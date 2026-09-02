import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import '../data/database_helper.dart';
import '../widgets/meridian_icons.dart';
import '../theme/app_colors.dart';

class DiagnosisHistoryScreen extends StatefulWidget {
  const DiagnosisHistoryScreen({super.key});

  @override
  State<DiagnosisHistoryScreen> createState() => _DiagnosisHistoryScreenState();
}

class _DiagnosisHistoryScreenState extends State<DiagnosisHistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await DatabaseHelper.instance.getDiagnosisHistory(limit: 100);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('诊断历史'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清空历史',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: StateView.loading())
          : _records.isEmpty
              ? const Center(child: Text('暂无诊断记录', style: TextStyle(fontSize: 16)))
              : ListView(
                  children: [
                    _buildTrendSection(),
                    const Divider(height: 1),
                    _buildHistoryList(),
                  ],
                ),
    );
  }

  // ==================== 传变趋势图 ====================

  Widget _buildTrendSection() {
    if (_records.length < 2) return const SizedBox.shrink();

    // 按时间正序（旧→新）
    final sorted = _records.reversed.toList();
    final meridians = sorted.map((r) => r['meridian'] as String? ?? '').toList();

    // 检测传变方向
    final trend = _detectTrend(meridians);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 20),
              const SizedBox(width: 8),
              Text('六经传变趋势',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendChart(sorted),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_trendIcon(trend), size: 18, color: _trendColor(trend)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(trend,
                        style: TextStyle(
                            color: _trendColor(trend),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> sorted) {
    // 取最近12条记录做趋势图
    final display = sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;
    final meridianOrder = ['太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'];

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y轴标签
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: meridianOrder.reversed.map((m) {
              return SizedBox(
                height: 25,
                child: Text(m,
                    style: TextStyle(
                        fontSize: 10,
                        color: _meridianColor(m),
                        fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          // 柱状图
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: display.map((r) {
                final meridian = r['meridian'] as String? ?? '';
                final idx = meridianOrder.indexOf(meridian);
                final height = idx >= 0 ? (idx + 1) * 25.0 : 25.0;
                final date = DateTime.tryParse(r['created_at'] as String? ?? '');
                final dayStr = date != null ? '${date.month}/${date.day}' : '';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: height,
                      decoration: BoxDecoration(
                        color: _meridianColor(meridian),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dayStr, style: const TextStyle(fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _detectTrend(List<String> meridians) {
    if (meridians.length < 2) return '';

    final order = {'太阳': 0, '阳明': 1, '少阳': 2, '太阴': 3, '少阴': 4, '厥阴': 5};
    final recent = meridians.length > 5
        ? meridians.sublist(meridians.length - 5)
        : meridians;

    int sum = 0;
    int count = 0;
    for (int i = 1; i < recent.length; i++) {
      final prev = order[recent[i - 1]];
      final curr = order[recent[i]];
      if (prev != null && curr != null) {
        sum += curr - prev;
        count++;
      }
    }
    if (count == 0) return '';

    final avg = sum / count;
    if (avg > 0.8) return '趋势：由表入里，病情加深，需注意';
    if (avg > 0.3) return '趋势：有入里倾向，建议及时调治';
    if (avg < -0.8) return '趋势：由里出表，病情好转';
    if (avg < -0.3) return '趋势：有向好倾向，继续调治';
    return '趋势：病情相对稳定';
  }

  Color _trendColor(String trend) {
    if (trend.contains('好转') || trend.contains('向好')) return context.colors.success;
    if (trend.contains('加深') || trend.contains('入里')) return context.colors.danger;
    if (trend.contains('入里倾向')) return context.colors.warning;
    return context.colors.info;
  }

  IconData _trendIcon(String trend) {
    if (trend.contains('好转') || trend.contains('向好')) return Icons.arrow_downward;
    if (trend.contains('加深') || trend.contains('入里')) return Icons.arrow_upward;
    return Icons.remove;
  }

  // ==================== 历史记录列表 ====================

  Widget _buildHistoryList() {
    return Column(
      children: _records.map((r) {
        final meridian = r['meridian'] as String? ?? '';
        final pattern = r['pattern'] as String? ?? '';
        final formula = r['formula'] as String? ?? '';
        final confidence = (r['confidence'] as num?)?.toDouble() ?? 0;
        final date = DateTime.tryParse(r['created_at'] as String? ?? '');
        final dateStr = date != null
            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
            : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.meridianContainer(meridian),
            child: Icon(meridianIcon(meridian),
                size: 16, color: context.colors.meridianColor(meridian)),
          ),
          title: Text('$meridian · $pattern',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('$formula  置信度${(confidence * 100).round()}%'),
          trailing: Text(dateStr,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        );
      }).toList(),
    );
  }

  // ==================== 工具方法 ====================

  Color _meridianColor(String meridian) {
    return context.colors.meridianColor(meridian);
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空诊断历史'),
        content: const Text('确定要清空所有诊断记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearDiagnosisHistory();
              Navigator.pop(ctx);
              _loadHistory();
            },
            child: Text('清空', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
  }
}
