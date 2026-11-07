import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../data/disease_alias_index.dart';
import '../data/llm_chat_repository.dart';
import '../data/medical_case_data.dart';
import '../data/settings_repository.dart';
import '../services/classic_search_service.dart';
import '../services/llm_service.dart';
import '../widgets/state_view.dart';
import 'markdown_doc_screen.dart';
import 'medical_case_detail_screen.dart';
import 'settings_screen.dart';

const List<String> _sampleQuestions = [
  '桂枝汤证的辨证要点是什么？',
  '小柴胡汤什么时候用？',
  '失眠可能对应哪些证候？',
];

/// 一轮问答。历史只存在页面内存里，退出页面即消失，不落库。
class _Turn {
  final String question;
  String? answer;
  String? error;
  List<ClassicHit> sources = [];

  /// 本轮命中的本地医案（可点进详情，避免「说到病例却没有医案」）。
  List<MedicalCase> cases = [];

  /// 本轮命中的古今 / 中西医病名对照（让用户看得见「消渴 = 糖尿病」的依据）。
  List<DiseaseAlias> diseases = [];

  /// 回答里提到、但讲义片段与医案里都没有的方名（超出讲义范围的引用）。
  /// 不持久化：重进页面时上下文已丢弃，重算会把全部方名误判为「无据」。
  List<String> unverified = [];

  _Turn(this.question);

  bool get busy => answer == null && error == null;

  /// 从持久化记录恢复（医案按 seq 反查，查不到的静默跳过）。
  factory _Turn.fromDb(LlmChatTurn t, Map<int, MedicalCase> bySeq) {
    final turn = _Turn(t.question)..answer = t.answer;
    turn.cases = [
      for (final seq in t.caseSeqs) if (bySeq[seq] != null) bySeq[seq]!,
    ];
    return turn;
  }
}

/// 「问倪师AI」：本地讲义检索片段 + 用户自配的 OpenAI 兼容端点。
///
/// 长对话模式（最近 3 轮历史），但不加模式开关：点「新对话」清空即等同于一问一答。
/// 默认关闭，未配置时本页只给出前往设置的入口，不发起任何网络请求。
class LlmAskScreen extends StatefulWidget {
  const LlmAskScreen({super.key});

  @override
  State<LlmAskScreen> createState() => _LlmAskScreenState();
}

class _LlmAskScreenState extends State<LlmAskScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _busy = false;
  final List<_Turn> _turns = [];

  /// 当前会话。null 表示「尚未落库的新会话」——首条回答写入时才建。
  int? _sessionId;

  /// 历史是否加载完成：加载完成前禁用发送，避免加载与提问竞态。
  bool _historyReady = false;

  @override
  void initState() {
    super.initState();
    _restoreHistory();
  }

  Future<void> _restoreHistory() async {
    try {
      final session = await LlmChatRepository.latestSession();
      if (session == null) {
        if (mounted) setState(() => _historyReady = true);
        return;
      }
      _sessionId = session.id;
      final turns = await LlmChatRepository.loadTurns(session.id);
      final all = await getAllMedicalCases();
      final bySeq = {for (final c in all) c.seq: c};
      if (!mounted) return;
      setState(() {
        _turns
          ..clear()
          ..addAll([for (final t in turns) _Turn.fromDb(t, bySeq)]);
        _historyReady = true;
      });
      if (turns.isNotEmpty) _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _historyReady = true);
    }
  }

  /// 回答落库。失败静默：记录是附属功能，不能因为它打断回答展示。
  Future<void> _persistTurn(_Turn turn) async {
    final answer = turn.answer;
    if (answer == null) return; // 失败轮不落库
    try {
      _sessionId ??= await LlmChatRepository.createSession(
        turn.question.length > 20
            ? turn.question.substring(0, 20)
            : turn.question,
      );
      await LlmChatRepository.appendTurn(
        _sessionId!,
        question: turn.question,
        answer: answer,
        caseSeqs: [for (final c in turn.cases) c.seq],
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _ask() async {
    if (_busy || !_historyReady) return;
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    _controller.clear();

    // 历史只取已完成的轮次，且不含本轮；讲义片段只给当前轮。
    final prior = _turns.where((t) => t.answer != null).toList();
    final recent = prior.length > LlmService.maxHistoryTurns
        ? prior.sublist(prior.length - LlmService.maxHistoryTurns)
        : prior;
    final history = recent
        .map((t) => (question: t.question, answer: t.answer!))
        .toList();

    final turn = _Turn(q);
    setState(() {
      _turns.add(turn);
      _busy = true;
    });
    _scrollToBottom();

    try {
      // 必须走 prepare：整句提问在整串匹配下 0 命中，需关键词回退；
      // 且要一并拿方剂清单 / 医案 / 统计，否则模型只答第一个方剂、不会数、不回链医案。
      final r = await LlmService.prepare(q);
      final text = await LlmService.ask(
        q,
        LlmConfig.fromSettings(),
        retrieval: r,
        history: history,
      );
      if (!mounted) return;
      setState(() {
        turn.answer = text;
        turn.sources = r.classics;
        turn.cases = r.cases;
        turn.diseases = r.diseases;
        turn.unverified = LlmService.unverifiedFormulas(text, r);
      });
      await _persistTurn(turn);
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => turn.error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => turn.error = '请求失败，请稍后重试或检查设置');
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  void _askSample(String q) {
    _controller.text = q;
    _ask();
  }

  /// 重试：移除失败轮再重发，避免把失败轮算进历史。
  void _retry() {
    if (_busy || _turns.isEmpty) return;
    final q = _turns.removeLast().question;
    _controller.text = q;
    _ask();
  }

  /// 新对话：清空当前视图，旧会话保留在历史里（下次可从列表切回）。
  void _newChat() {
    if (_busy) return;
    setState(() {
      _sessionId = null;
      _turns.clear();
    });
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  /// 切换到指定会话。
  Future<void> _switchTo(LlmChatSession session) async {
    if (_busy || _sessionId == session.id) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final turns = await LlmChatRepository.loadTurns(session.id);
      final all = await getAllMedicalCases();
      final bySeq = {for (final c in all) c.seq: c};
      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _turns
          ..clear()
          ..addAll([for (final t in turns) _Turn.fromDb(t, bySeq)]);
      });
      if (turns.isNotEmpty) _scrollToBottom();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSessionList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SessionsSheet(
        currentId: _sessionId,
        onPick: _switchTo,
        onDeleted: (deletedId) {
          if (deletedId == _sessionId) {
            setState(() {
              _sessionId = null;
              _turns.clear();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = SettingsRepository.instance.llmReady;

    return Scaffold(
      appBar: AppBar(
        title: const Text('问倪师AI'),
        actions: [
          IconButton(
            tooltip: '历史会话',
            icon: const Icon(Icons.history),
            onPressed: _historyReady ? _openSessionList : null,
          ),
          if (_turns.isNotEmpty)
            TextButton(
              onPressed: _busy ? null : _newChat,
              child: const Text('新对话'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!ready) _notConfigured(cs),
          Expanded(child: _body(cs)),
          _disclaimer(cs),
          const Divider(height: 1),
          _composer,
        ],
      ),
    );
  }

  /// 免责框由 App 固定渲染，绝不交给模型生成。
  /// 急症提问另出加强版：persona 禁止模型在正文写安全话术，缺口在这里补。
  Widget _disclaimer(ColorScheme cs) {
    final last = _turns.isEmpty ? '' : _turns.last.question;
    final emergency = LlmService.isEmergencyQuery(last);
    // 针灸提问另加一句：取穴与手法是可照着做的操作，风险比开方更直接。
    final acupuncture =
        !emergency && last.isNotEmpty && LlmService.isAcupunctureQuery(last);
    final base = emergency
        ? '【急症提示】你描述的情况可能是急症：请立即拨打 120 或就近急诊，'
            '不要自行抓药、不要等待 AI 回答。\n'
            'AI 生成内容，非倪海厦本人原话，仅供学习参考，不构成诊疗建议。'
        : 'AI 生成内容，非倪海厦本人原话，仅供学习参考，不构成诊疗建议。'
            '请遵医嘱用药；急症、重症请立即就医。';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: emergency ? cs.errorContainer : cs.surfaceContainerHighest,
      child: Text(
        acupuncture
            ? '$base\n穴位定位与针刺手法须由执业医师操作，请勿自行下针。'
            : base,
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: emergency ? cs.onErrorContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _notConfigured(ColorScheme cs) => Material(
        color: cs.errorContainer,
        child: ListTile(
          leading: Icon(Icons.settings_outlined, color: cs.onErrorContainer),
          title: Text('尚未配置 AI 接口',
              style: TextStyle(color: cs.onErrorContainer)),
          subtitle: Text('请在设置中填写接口地址、API Key 与模型',
              style: TextStyle(color: cs.onErrorContainer)),
          trailing: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: const Text('去设置'),
          ),
        ),
      );

  Widget _body(ColorScheme cs) {
    if (_turns.isEmpty) return _emptyView(cs);
    // 窗口固定 3 轮，用 Column 即可，无需 ListView.builder 的滚动/高度管理。
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in _turns) _turnView(cs, t),
        ],
      ),
    );
  }

  Widget _turnView(ColorScheme cs, _Turn t) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _questionBar(cs, t.question),
            const SizedBox(height: 8),
            if (t.busy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    StateView.loading(fullScreen: false),
                    const SizedBox(height: 12),
                    Text(
                      '正在检索讲义并生成回答…',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else if (t.error != null)
              StateView.error(
                fullScreen: false,
                message: t.error,
                onRetry: _retry,
              )
            else ...[
              _auditTile(t.unverified),
              _diseaseTile(t.diseases),
              _casesTile(t.cases),
              _sourcesTile(t.sources),
              const SizedBox(height: 8),
              MarkdownBody(
                data: t.answer!,
                selectable: true,
                styleSheet: MarkdownDocScreen.styleSheetFor(Theme.of(context)),
              ),
            ],
          ],
        ),
      );

  Widget _questionBar(ColorScheme cs, String q) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你问的是',
                style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
            const SizedBox(height: 3),
            Text(q, style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer)),
          ],
        ),
      );

  /// 出处审计：把「回答里有、讲义片段里没有」的方名挑出来标注。
  /// 不改写回答，只交底 —— 用户自己判断这条是讲义原话还是模型自带知识。
  Widget _auditTile(List<String> unverified) {
    if (unverified.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: Icon(Icons.fact_check_outlined, size: 18, color: cs.tertiary),
      title: Text(
        '${unverified.length} 处方名未在讲义片段中出现',
        style: TextStyle(fontSize: 13, color: cs.tertiary),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${unverified.join('、')}\n\n'
              '本次检索的讲义片段与倪师医案里都没有提到这些方名，可能是模型的'
              '自身知识补充。涉及用药时请以讲义原文为准，不要当作倪师原话。',
              style: TextStyle(fontSize: 12, height: 1.5, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  /// 病名对照：可展开看到「古名 ⇒ 今名」及倪师讲稿原话，答案对名有据可查。
  Widget _diseaseTile(List<DiseaseAlias> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: const Icon(Icons.translate, size: 18),
      title: Text('病名对照 ${list.length} 条', style: const TextStyle(fontSize: 13)),
      children: [
        for (final e in list)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${e.ancient} ⇒ ${e.moderns.join('、')}',
              style: const TextStyle(fontSize: 12),
            ),
            subtitle: Text(
              '${e.kindLabel} · 倪师原话：${e.note}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// 相关医案：点进去看完整 12 字段医案。
  /// 「AI 说到某个病例不回链医案」的解法——检索时就带上医案，回答下方给出入口。
  Widget _casesTile(List<MedicalCase> cases) {
    if (cases.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: const Icon(Icons.folder_shared_outlined, size: 18),
      title: Text('相关倪师医案 ${cases.length} 例',
          style: const TextStyle(fontSize: 13)),
      children: [
        for (final c in cases)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('#${c.seq} ${c.displayName}',
                style: const TextStyle(fontSize: 12)),
            subtitle: Text(
              [c.formula, c.result]
                  .where((e) => e.trim().isNotEmpty)
                  .join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final all = await getAllMedicalCases();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalCaseDetailScreen(c: c, allCases: all),
                ),
              );
            },
          ),
      ],
    );
  }

  /// 来源可展开：点开直接看命中片段，答案可溯源（不是只给一个数字）。
  Widget _sourcesTile(List<ClassicHit> sources) {
    if (sources.isEmpty) {
      return const ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline, size: 18),
        title: Text('本次检索没有命中讲义内容', style: TextStyle(fontSize: 12)),
      );
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text('参考 ${sources.length} 条本地讲义片段',
          style: const TextStyle(fontSize: 13)),
      children: [
        for (final h in sources)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${h.sourceLabel}·${h.title}',
                style: const TextStyle(fontSize: 12)),
            subtitle: Text(
              h.snippet,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _emptyView(ColorScheme cs) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StateView.empty(
                fullScreen: false,
                icon: Icons.chat_bubble_outline,
                title: '问一个中医问题',
                hint: 'App 先在本地讲义检索，再把片段交给模型作答。\n'
                    '对话只保存在本机，可连续追问、跨页面续接；\n'
                    '右上角时钟图标可切换历史会话。未配置或关闭时不联网。',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final q in _sampleQuestions)
                    ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _askSample(q),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget get _composer => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '例如：那如果换成麻黄汤呢？',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _busy || !SettingsRepository.instance.llmReady
                  ? null
                  : _ask,
              icon: const Icon(Icons.send, size: 18),
              label: const Text('提问'),
            ),
          ],
        ),
      );
}


/// 历史会话列表（底部抽屉）：切换 / 重命名 / 删除。
class _SessionsSheet extends StatefulWidget {
  final int? currentId;
  final Future<void> Function(LlmChatSession) onPick;
  final void Function(int) onDeleted;

  const _SessionsSheet({
    required this.currentId,
    required this.onPick,
    required this.onDeleted,
  });

  @override
  State<_SessionsSheet> createState() => _SessionsSheetState();
}

class _SessionsSheetState extends State<_SessionsSheet> {
  List<LlmChatSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await LlmChatRepository.listSessions();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _loading = false;
    });
  }

  /// 按 updated_at 分组：今天 / 昨天 / 7 天内 / 更早。
  Map<String, List<LlmChatSession>> get _grouped {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <String, List<LlmChatSession>>{};
    for (final s in _sessions) {
      final d = DateTime.tryParse(s.updatedAt);
      final day = d == null ? null : DateTime(d.year, d.month, d.day);
      final label = day == null
          ? '更早'
          : day == today
              ? '今天'
              : day == today.subtract(const Duration(days: 1))
                  ? '昨天'
                  : today.difference(day).inDays <= 7
                      ? '7 天内'
                      : '更早';
      (out[label] ??= []).add(s);
    }
    return out;
  }

  static const _groupOrder = ['今天', '昨天', '7 天内', '更早'];

  Future<void> _rename(LlmChatSession s) async {
    final controller = TextEditingController(text: s.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;
    await LlmChatRepository.renameSession(s.id, title);
    await _reload();
  }

  Future<void> _delete(LlmChatSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('删除「${s.title}」及其全部对话记录？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LlmChatRepository.deleteSession(s.id);
    widget.onDeleted(s.id);
    await _reload();
  }

  String _fmtTime(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return sameDay ? '$hh:$mm' : '${d.month}/${d.day} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('历史会话',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? const Center(
                          child: Text('还没有历史会话',
                              style: TextStyle(color: Colors.grey)))
                      : ListView(
                          children: [
                            for (final g in _groupOrder)
                              if (_grouped[g] != null) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                  child: Text(g,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary)),
                                ),
                                for (final s in _grouped[g]!)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(
                                      s.id == widget.currentId
                                          ? Icons.chat_bubble
                                          : Icons.chat_bubble_outline,
                                      size: 20,
                                      color: s.id == widget.currentId
                                          ? cs.primary
                                          : null,
                                    ),
                                    title: Text(s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(_fmtTime(s.updatedAt),
                                        style: const TextStyle(fontSize: 11)),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'rename') _rename(s);
                                        if (v == 'delete') _delete(s);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'rename',
                                            child: Text('重命名')),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('删除')),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onPick(s);
                                    },
                                  ),
                              ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
