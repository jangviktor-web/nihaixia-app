import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/diagnostic_engine.dart';
import '../engine/diagnostic_rules.dart';
import '../data/formula_repository.dart';
import '../data/settings_repository.dart';
import '../models/diagnosis.dart';
import '../models/bookmark.dart';
import '../data/database_helper.dart';
import 'formula_detail_screen.dart';
import 'meridian_detail_screen.dart';

/// 对话步骤快照（用于返回上一步）
class _StepSnapshot {
  final List<_ChatBubble> messages;
  final EngineSnapshot engineSnapshot;

  _StepSnapshot({
    required this.messages,
    required this.engineSnapshot,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DiagnosticEngine _engine = DiagnosticEngine();
  final List<_ChatBubble> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showOptions = false;
  List<_ChatOption> _currentOptions = [];
  bool _canGoBack = false;

  // 诊断步骤历史栈（用于返回上一步）
  final List<_StepSnapshot> _stepHistory = [];

  // 舌诊脉诊选择状态
  String? _selectedTongueCoating;
  String? _selectedTongueShape;
  String? _selectedPulse;

  @override
  void initState() {
    super.initState();
    _startDiagnosis();
  }

  void _startDiagnosis() {
    _addBotMessage(_engine.getInitialGreeting());
    _showChiefComplaintOptions();
  }

  // ==================== 快照管理 ====================

  void _saveSnapshot() {
    _stepHistory.add(_StepSnapshot(
      messages: List.from(_messages),
      engineSnapshot: _engine.createSnapshot(),
    ));
    _canGoBack = true;
  }

  void _goBack() {
    if (_stepHistory.isEmpty) return;
    final snapshot = _stepHistory.removeLast();
    setState(() {
      _messages.clear();
      _messages.addAll(snapshot.messages);
      _engine.restoreSnapshot(snapshot.engineSnapshot);
      _showOptions = true;
      _canGoBack = _stepHistory.isNotEmpty;
    });
    _scrollToBottom();
  }

  // ==================== 主诉选择 ====================

  void _showChiefComplaintOptions() {
    final options = _engine.getChiefComplaintOptions();
    setState(() {
      _currentOptions = options
          .map((o) => _ChatOption(
                label: '${o.emoji} ${o.label}',
                description: o.description,
                onTap: () => _selectChiefComplaint(o.key, o.label),
              ))
          .toList();
      _showOptions = true;
    });
  }

  void _selectChiefComplaint(String key, String label) {
    _saveSnapshot();
    _addUserMessage(label);
    _engine.selectChiefComplaint(key);
    _showTemperatureOptions();
  }

  // ==================== 寒热辨经 ====================

  void _showTemperatureOptions() {
    _addBotMessage('发烧怕冷的情况是怎样的？');
    final options = _engine.getTemperatureQuestions();
    setState(() {
      _currentOptions = options
          .map((o) => _ChatOption(
                label: o.label,
                description: o.description,
                onTap: () => _selectTemperature(o.key, o.label),
              ))
          .toList();
      _showOptions = true;
    });
  }

  void _selectTemperature(String key, String label) {
    _saveSnapshot();
    _addUserMessage(label);
    _engine.answerTemperaturePattern(key);
    _showTonguePulseInput();
  }

  // ==================== 舌诊脉诊 ====================

  void _showTonguePulseInput() {
    _addBotMessage('接下来请告诉我你的舌象和脉象（可跳过）：');
    setState(() {
      _currentOptions = [
        _ChatOption(
          label: '📝 选择舌诊脉诊',
          onTap: _showTonguePulseDialog,
        ),
        _ChatOption(
          label: '⏭️ 跳过，直接问诊',
          onTap: () {
            _addUserMessage('跳过舌诊脉诊');
            _engine.answerTonguePulse();
            _showTenQuestion(0);
          },
        ),
      ];
      _showOptions = true;
    });
  }

  void _showTonguePulseDialog() {
    _selectedTongueCoating = null;
    _selectedTongueShape = null;
    _selectedPulse = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('舌诊脉诊'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('舌苔', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getTongueCoatingOptions().map((opt) {
                    final selected = _selectedTongueCoating == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedTongueCoating = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('舌形', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getTongueShapeOptions().map((opt) {
                    final selected = _selectedTongueShape == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedTongueShape = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('脉象', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _engine.getPulseOptions().map((opt) {
                    final selected = _selectedPulse == opt;
                    return FilterChip(
                      label: Text(opt),
                      selected: selected,
                      onSelected: (s) {
                        setDialogState(() {
                          _selectedPulse = s ? opt : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _saveSnapshot();
                String label = '舌诊脉诊：';
                if (_selectedTongueCoating != null) label += '苔${_selectedTongueCoating!} ';
                if (_selectedTongueShape != null) label += '形${_selectedTongueShape!} ';
                if (_selectedPulse != null) label += '脉${_selectedPulse!}';
                if (_selectedTongueCoating == null &&
                    _selectedTongueShape == null &&
                    _selectedPulse == null) {
                  label = '舌诊脉诊：未选择';
                }
                _addUserMessage(label);
                _engine.answerTonguePulse(
                  tongueCoating: _selectedTongueCoating,
                  tongueShape: _selectedTongueShape,
                  pulseType: _selectedPulse,
                );
                _showTenQuestion(0);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 倪海厦九问 ====================

  void _showTenQuestion(int index) {
    final questions = _engine.getTenQuestions();
    if (index >= questions.length) {
      _afterTenQuestions();
      return;
    }

    final q = questions[index];
    _addBotMessage(q.question);
    setState(() {
      _currentOptions = q.options
          .map((o) => _ChatOption(
                label: o,
                onTap: () {
                  _addUserMessage(o);
                  _engine.answerTenQuestion(q.key, o);
                  _showTenQuestion(index + 1);
                },
              ))
          .toList();
      _showOptions = true;
    });
  }

  // ==================== 九问后处理 ====================

  void _afterTenQuestions() {
    final result = _engine.diagnose();
    if (result != null) {
      _addBotMessage('好，九问已经完成了。让我根据你的情况来分析...\n\n'
          '📋 你的情况：${_engine.selectedSymptoms.join("、")}\n\n'
          '下面给出辨证结果：');
      _showResult();
    } else {
      _addBotMessage('好的，让我进一步确认一些症状...');
      final meridian = _engine.diagnose()?.meridian ?? '少阴';
      final questions = _engine.getFollowUpQuestions(meridian);
      if (questions.isNotEmpty) {
        _showFollowUpQuestion(questions, 0);
      } else {
        _showResult();
      }
    }
  }

  void _showFollowUpQuestion(List<FollowUpQuestion> questions, int index) {
    if (index >= questions.length) {
      _showResult();
      return;
    }

    final q = questions[index];
    _addBotMessage(q.question);
    setState(() {
      _currentOptions = q.options
          .map((o) => _ChatOption(
                label: o,
                onTap: () {
                  _addUserMessage(o);
                  _engine.answerFollowUp(q.key, o);
                  _showFollowUpQuestion(questions, index + 1);
                },
              ))
          .toList();
      _showOptions = true;
    });
  }

  // ==================== 诊断结果展示 ====================

  void _showResult() {
    final result = _engine.diagnose();
    if (result == null) return;

    setState(() => _showOptions = false);

    final formula = FormulaRepository.getByName(result.formula);
    final explanation = formula?.explanation ?? result.explanation;

    String resultText = '${result.meridianEmoji} 辨证结果\n\n'
        '【六经】${result.displayMeridian}病\n';

    if (result.isCombined) {
      resultText += '⚡ 合病：${result.meridian}与${result.combinedMeridian}同病\n';
    }

    resultText += '【证型】${result.pattern}\n'
        '【方剂】${result.formula}\n';

    if (formula != null && formula.components.isNotEmpty) {
      resultText += '【组成】${formula.componentsText}\n';
    }

    // 舌诊脉诊信息
    if (result.tongueCoating != null || result.tongueShape != null || result.pulseType != null) {
      resultText += '\n🔬 舌脉：';
      if (result.tongueCoating != null) resultText += '苔${result.tongueCoating} ';
      if (result.tongueShape != null) resultText += '形${result.tongueShape} ';
      if (result.pulseType != null) resultText += '脉${result.pulseType}';
      resultText += '\n';
    }

    resultText += '\n${result.patternDetail}\n\n💡 ${explanation}';

    _addBotMessage(resultText, isResult: true, diagnosisResult: result);

    // 保存诊断历史
    DatabaseHelper.instance.saveDiagnosisHistory(
      result.meridian,
      result.pattern,
      result.formula,
      result.confidence,
      jsonEncode(result.answers),
    );

    // 处方详情
    if (result.prescription != null) {
      final rx = result.prescription!;
      String rxText = '📋 完整处方\n'
          '─────────────────\n'
          '${rx.components.map((c) => '${c.name} ${c.dosage}').join('  ')}';

      if (rx.preparation.isNotEmpty) {
        rxText += '\n\n💊 煎服法:\n${rx.preparation}';
      }
      if (rx.contraindication.isNotEmpty) {
        rxText += '\n\n⚠️ 禁忌:\n${rx.contraindication}';
      }
      if (rx.modifications != null && rx.modifications!.isNotEmpty) {
        rxText += '\n\n🔄 加减建议:';
        for (final m in rx.modifications!) {
          rxText += '\n• ${m.condition} → ${m.description}';
          if (m.resultFormula.isNotEmpty) {
            rxText += '（${m.resultFormula}）';
          }
        }
      }
      _addBotMessage(rxText, isResult: false);
    }

    // 鉴别诊断
    if (result.differential != null) {
      final diff = result.differential!;
      String diffText = '🔍 鉴别诊断\n\n'
          '【关键区别】${diff.keyDifference}\n\n'
          '┌─ ${diff.name1}（${diff.formula1}）\n'
          '│  ${diff.details.entries.map((e) => '${e.key}：${e.value}').join('\n│  ')}\n'
          '│\n'
          '└─ ${diff.name2}（${diff.formula2}）\n'
          '   ${diff.details.entries.map((e) => '${e.key}：${e.value}').join('\n   ')}';
      _addBotMessage(diffText, isResult: false);
    }

    // 调护建议
    if (result.careAdvice != null) {
      String careText = '🛡️ 调护建议\n';
      for (final entry in result.careAdvice!.entries) {
        careText += '\n【${entry.key}】';
        for (final item in entry.value) {
          careText += '\n• $item';
        }
      }
      _addBotMessage(careText, isResult: false);
    }

    _addBotMessage('以上是辨证建议，仅供参考。如需详细查看方剂或药物信息，请点击下方按钮。\n\n'
        '🔄 想重新辨证吗？');
    setState(() {
      _currentOptions = [
        _ChatOption(
          label: '🔄 重新辨证',
          onTap: _resetDiagnosis,
        ),
        _ChatOption(
          label: '📖 查看${result.meridian}经详情',
          onTap: () => _openMeridianDetail(result.meridian),
        ),
        if (formula != null)
          _ChatOption(
            label: '💊 查看${formula.name}详情',
            onTap: () => _openFormulaDetail(formula),
          ),
        _ChatOption(
          label: '📤 分享辨证结果',
          onTap: () => _shareResult(result),
        ),
        if (result.prescription != null)
          _ChatOption(
            label: '📋 复制处方',
            onTap: () => _copyPrescription(result.prescription!),
          ),
      ];
      _showOptions = true;
    });
  }

  void _resetDiagnosis() {
    _engine.reset();
    _stepHistory.clear();
    _canGoBack = false;
    setState(() {
      _messages.clear();
    });
    _addBotMessage('好的，我们重新开始。');
    _showChiefComplaintOptions();
  }

  // ==================== 导航 ====================

  void _openFormulaDetail(formula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaDetailScreen(formula: formula),
      ),
    );
  }

  void _openMeridianDetail(String meridian) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeridianDetailScreen(meridian: meridian),
      ),
    );
  }

  // ==================== 消息管理 ====================

  void _addBotMessage(String text,
      {bool isResult = false, DiagnosisResult? diagnosisResult}) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: false,
        isResult: isResult,
        diagnosisResult: diagnosisResult,
        onBookmark: isResult && diagnosisResult != null
            ? () => _bookmarkResult(diagnosisResult)
            : null,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatBubble(text: text, isUser: true));
      _showOptions = false;
    });
    _scrollToBottom();
  }

  // ==================== 收藏 ====================

  void _bookmarkResult(DiagnosisResult result) async {
    final db = DatabaseHelper.instance;
    final bookmark = Bookmark(
      title: '${result.displayMeridian}病 - ${result.pattern}',
      content: '六经: ${result.displayMeridian}\n'
          '${result.isCombined ? "合病: ${result.meridian}与${result.combinedMeridian}\n" : ""}'
          '证型: ${result.pattern}\n方剂: ${result.formula}\n\n'
          '${result.patternDetail}\n\n${result.explanation}',
      category: '辨证结果',
      source: 'chat_diagnosis',
    );
    await db.insertBookmark(bookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到收藏')),
      );
    }
  }

  // ==================== 分享 ====================

  void _shareResult(DiagnosisResult result) {
    final formula = FormulaRepository.getByName(result.formula);
    String text = '【汉唐中医辨证结果】\n\n';
    text += '六经：${result.displayMeridian}病\n';
    if (result.isCombined) {
      text += '合病：${result.meridian}与${result.combinedMeridian}同病\n';
    }
    text += '证型：${result.pattern}\n';
    text += '方剂：${result.formula}\n';
    if (formula != null && formula.components.isNotEmpty) {
      text += '组成：${formula.componentsText}\n';
    }
    if (result.tongueCoating != null || result.tongueShape != null || result.pulseType != null) {
      text += '舌脉：';
      if (result.tongueCoating != null) text += '苔${result.tongueCoating} ';
      if (result.tongueShape != null) text += '形${result.tongueShape} ';
      if (result.pulseType != null) text += '脉${result.pulseType}';
      text += '\n';
    }
    text += '\n${result.patternDetail}\n\n';
    text += '💡 ${result.explanation}\n\n';
    if (result.careAdvice != null) {
      text += '🛡️ 调护建议：\n';
      for (final entry in result.careAdvice!.entries) {
        text += '【${entry.key}】${entry.value.join("、")}\n';
      }
      text += '\n';
    }
    text += '—— 来自「汉唐中医」App';
    Share.share(text);
  }

  void _copyPrescription(FormulaPrescription prescription) {
    final text = prescription.toCopyText();
    Clipboard.setData(ClipboardData(text: text));
    _addBotMessage('✅ 处方已复制到剪贴板，可粘贴发送给药房。');
  }

  // ==================== 设置对话框 ====================

  void _showSettingsDialog() {
    final settings = SettingsRepository.instance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('暗黑模式', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
            const SizedBox(height: 16),
            const Text('字体大小', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('小', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: settings.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 14,
                    label: '${(settings.textScaleFactor * 100).round()}%',
                    onChanged: (v) => settings.setTextScaleFactor(v),
                  ),
                ),
                const Text('大', style: TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ==================== 滚动 ====================

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== 构建UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('六经辨证'),
        actions: [
          if (_canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: '返回上一步',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDiagnosis,
            tooltip: '重新辨证',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_showOptions)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shrinkWrap: true,
                itemCount: _currentOptions.length,
                itemBuilder: (context, index) {
                  final option = _currentOptions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: option.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== 气泡组件 ====================

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isResult;
  final DiagnosisResult? diagnosisResult;
  final VoidCallback? onBookmark;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isResult = false,
    this.diagnosisResult,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '倪海厦',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isResult
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withOpacity(0.5)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isResult && onBookmark != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: TextButton.icon(
                  onPressed: onBookmark,
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('收藏'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== 选项模型 ====================

class _ChatOption {
  final String label;
  final String? description;
  final VoidCallback onTap;

  _ChatOption({
    required this.label,
    this.description,
    required this.onTap,
  });
}
