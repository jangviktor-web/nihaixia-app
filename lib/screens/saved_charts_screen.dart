import 'package:flutter/material.dart';
import 'package:nihaisha_app/data/saved_chart_repository.dart';
import 'package:nihaisha_app/screens/ziwei_chart_screen.dart';

/// 我的命盘库。
///
/// 列出已保存的命盘（名称、出生时间、城市），支持左滑删除；点击某条进入
/// 排盘页并回填生辰与地点，重新排盘查看。
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的命盘库')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _charts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_outline,
                            size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          '还没有保存的命盘',
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '在紫微排盘页排盘后，点「添加到命盘库」即可收藏',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                          onTap: () => Navigator.push(
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
