import 'package:flutter/material.dart';
import '../data/yijing_data.dart';
import '../engine/yijing_engine.dart';
import 'yijing_detail_screen.dart';
import 'yijing_result_screen.dart';
import 'minggua_calculator_screen.dart';
import 'minggua_library_screen.dart';

/// 易经六十四卦工具主页（起卦 / 六十四卦总览）
class YiJingScreen extends StatefulWidget {
  const YiJingScreen({super.key});

  @override
  State<YiJingScreen> createState() => _YiJingScreenState();
}

class _YiJingScreenState extends State<YiJingScreen> {
  final _numAController = TextEditingController();
  final _numBController = TextEditingController();
  int _manualUpper = 1;
  int _manualLower = 1;
  int _manualMoving = 0;

  @override
  void dispose() {
    _numAController.dispose();
    _numBController.dispose();
    super.dispose();
  }

  void _openResult(CastResult cast) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => YiJingResultScreen(cast: cast)),
    );
  }

  void _castNumbers() {
    final a = int.tryParse(_numAController.text.trim());
    final b = int.tryParse(_numBController.text.trim());
    if (a == null || b == null || a < 0 || b < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入两个非负整数')));
      return;
    }
    _openResult(YiJingEngine.castByNumbers(a, b));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('易经六十四卦'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.casino_outlined), text: '起卦'),
              Tab(icon: Icon(Icons.grid_view_outlined), text: '六十四卦'),
              Tab(icon: Icon(Icons.calculate_outlined), text: '四柱命卦'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCastTab(context),
            _buildBrowseTab(context),
            _buildMingGuaTab(context),
          ],
        ),
      ),
    );
  }

  // ---------- Tab 1：起卦 ----------
  Widget _buildCastTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 时间起卦
        _MethodCard(
          icon: Icons.schedule,
          title: '时间起卦（梅花易数）',
          subtitle: '以当前年月日时推演上下卦与动爻',
          color: colorScheme.primary,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '现在：${DateTime.now().year}年${DateTime.now().month}月'
                  '${DateTime.now().day}日 ${DateTime.now().hour}时',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    _openResult(YiJingEngine.castByTime(DateTime.now())),
                icon: const Icon(Icons.casino_outlined),
                label: const Text('起卦'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 数字起卦
        _MethodCard(
          icon: Icons.numbers,
          title: '数字起卦',
          subtitle: '任意两数，余数定上下卦，和数定动爻',
          color: colorScheme.secondary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numAController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '第一个数',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _numBController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '第二个数',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _castNumbers,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('起卦'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 手动选卦
        _MethodCard(
          icon: Icons.tune,
          title: '手动选卦',
          subtitle: '直接选择上下卦与动爻（0 为静卦）',
          color: colorScheme.tertiary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _manualUpper,
                      decoration: const InputDecoration(
                        labelText: '上卦',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final t in kTrigrams)
                          DropdownMenuItem(
                            value: t.xiantian,
                            child: Text('${t.name}${t.symbol}${t.nature}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _manualUpper = v ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _manualLower,
                      decoration: const InputDecoration(
                        labelText: '下卦',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final t in kTrigrams)
                          DropdownMenuItem(
                            value: t.xiantian,
                            child: Text('${t.name}${t.symbol}${t.nature}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _manualLower = v ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _manualMoving,
                      decoration: const InputDecoration(
                        labelText: '动爻',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var i = 0; i <= 6; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(i == 0 ? '静卦' : '$i爻动'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _manualMoving = v ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openResult(
                    YiJingEngine.castManual(
                      _manualUpper,
                      _manualLower,
                      _manualMoving,
                    ),
                  ),
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('起卦'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '倪海厦《天纪·人间道》：「易经不是用来算命的，是用来教人如何做君子、避小人的。」',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.outline,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ---------- Tab 2：六十四卦总览 ----------
  Widget _buildBrowseTab(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemCount: kHexagrams.length,
      itemBuilder: (context, i) {
        final h = kHexagrams[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YiJingHexagramDetailScreen(hex: h),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  YiJingEngine.symbol(h.seq),
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(height: 4),
                Text(
                  h.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '第${h.seq}卦',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Tab 3：四柱命卦 ----------
Widget _buildMingGuaTab(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _MethodCard(
        icon: Icons.calculate_outlined,
        title: '四柱命卦计算器',
        subtitle: '生辰 → 八字 → 先天卦（前半生）/ 后天卦（后半生）',
        color: colorScheme.primary,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MingGuaCalculatorScreen(),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('排四柱命卦'),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _MethodCard(
        icon: Icons.library_books_outlined,
        title: '四柱命卦讲义库',
        subtitle: '八字排法 + 64 卦先天/后天/值年卦批解 + 批卦补充',
        color: colorScheme.tertiary,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MingGuaLibraryScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('浏览讲义'),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '倪师《天纪·四柱命卦》：用生辰八字推先天卦主前半生、后天卦主后半生；'
        '值年卦需皇极经世查条表暂不自动算。算法已按原文示例校准（甲子·丁卯·庚申·庚辰 阳男 → 天风姤）。'
        '属传统文化参考，非医疗建议。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: colorScheme.outline, height: 1.6),
      ),
    ],
  );
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
