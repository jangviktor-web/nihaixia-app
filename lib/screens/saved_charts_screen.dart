import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:nihaisha_app/data/saved_chart_repository.dart';
import 'package:nihaisha_app/screens/ziwei_chart_screen.dart';
import 'package:nihaisha_app/screens/bazi_paipan_screen.dart';

/// 我的命盘库。
///
/// 列出已保存的命盘（名称、出生时间、城市），支持左滑删除；点击某条
/// 弹出「紫微 / 八字」排盘方式选择，生辰数据自动带入所选排盘页并排盘。
class SavedChartsScreen extends StatefulWidget {
  const SavedChartsScreen({super.key});

  @override
  State<SavedChartsScreen> createState() => _SavedChartsScreenState();
}

class _SavedChartsScreenState extends State<SavedChartsScreen> {
  List<SavedChart> _charts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SavedChartRepository.getAll();
    if (mounted) {
      setState(() {
        _charts = list;
        _loading = false;
      });
    }
  }

  Future<void> _delete(SavedChart c) async {
    if (c.id == null) return;
    await SavedChartRepository.delete(c.id!);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「${c.name}」')),
      );
    }
  }

  /// 点击命盘条目：弹出「紫微 / 八字」排盘方式选择。
  /// 两种排盘共用同一份生辰数据（solarIso + 性别 + 地点），
  /// 选择后直接带入对应排盘页并自动排盘，无需重新录入。
  Future<void> _openChart(SavedChart c, DateTime? solar) async {
    if (solar == null) {
      // 数据异常（solarIso 解析失败）：退回紫微页由用户手动处理
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ZiweiChartScreen(
            initialSolar: null,
            initialGender: c.isMale,
            initialCityName: c.cityName,
            initialLng: c.lng,
            initialLat: c.lat,
          ),
        ),
      );
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '「${c.name}」用哪种方式排盘？',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              child: Text(
                '两种排盘共用同一生辰数据，选择后自动带入',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('紫微斗数排盘'),
              subtitle: const Text('十二宫位 · 四化 · 大限流年'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, 'ziwei'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('八字排盘'),
              subtitle: const Text('四柱 · 十神 · 大运 · 刑冲合害'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, 'bazi'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'bazi') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BaZiPaipanScreen(
            initialSolar: solar,
            initialIsMale: c.isMale,
            initialCityName: c.cityName,
            initialLng: c.lng,
            initialLat: c.lat,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ZiweiChartScreen(
            initialSolar: solar,
            initialGender: c.isMale,
            initialCityName: c.cityName,
            initialLng: c.lng,
            initialLat: c.lat,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的命盘库')),
      body: _loading
          ? const Center(child: StateView.loading())
          : _charts.isEmpty
              ? Center(
                  child: StateView.empty(
                    title: '还没有保存的命盘',
                    hint: '在紫微 / 八字排盘页排盘后，点「添加到命盘库」即可收藏',
                    icon: Icons.bookmark_outline,
                    fullScreen: false,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _charts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = _charts[i];
                    final solar = DateTime.tryParse(c.solarIso);
                    final birth = solar != null
                        ? '${solar.year}-${solar.month.toString().padLeft(2, '0')}-${solar.day.toString().padLeft(2, '0')}'
                        : c.solarIso;
                    return Dismissible(
                      key: ValueKey(c.id ?? c.solarIso),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                      ),
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (_) => _delete(c),
                      child: Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            c.isMale ? Icons.male_outlined : Icons.female_outlined,
                            color: cs.primary,
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            '$birth · ${c.cityName ?? "未记城市"}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openChart(c, solar),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
