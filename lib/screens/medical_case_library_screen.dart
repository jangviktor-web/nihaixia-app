import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/medical_case_data.dart';

/// 倪师医案库（1257 例）可搜索浏览。
/// 运行时解析 assets/medical_cases/cases_table.md，按诊断/方剂/结果/观点全文检索。
class MedicalCaseLibraryScreen extends StatefulWidget {
  const MedicalCaseLibraryScreen({super.key});

  @override
  State<MedicalCaseLibraryScreen> createState() =>
      _MedicalCaseLibraryScreenState();
}

class _MedicalCaseLibraryScreenState extends State<MedicalCaseLibraryScreen> {
  late Future<List<MedicalCase>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<MedicalCase> _all = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MedicalCase>> _load() async {
    final md = await rootBundle
        .loadString('assets/medical_cases/cases_table.md');
    _all = parseMedicalCaseTable(md);
    return _all;
  }

  List<MedicalCase> get _filtered => _all.where((c) => c.matches(_query)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('倪师医案库')),
      body: FutureBuilder<List<MedicalCase>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '搜索诊断 / 方剂 / 结果 / 倪师观点…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '共 ${_filtered.length} / ${_all.length} 例',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = _filtered[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(
                          '#${c.seq}  ${c.diagnosis.isEmpty ? '（未命名）' : c.diagnosis}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.patient.isNotEmpty)
                              Text(c.patient,
                                  style: const TextStyle(fontSize: 12)),
                            if (c.formula.isNotEmpty)
                              Text('方：${_clip(c.formula, 36)}',
                                  style: const TextStyle(fontSize: 12)),
                            if (c.result.isNotEmpty)
                              Text('效：${_clip(c.result, 36)}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalCaseDetailScreen(c: c),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _clip(String s, int n) => s.length > n ? '${s.substring(0, n)}…' : s;
}

/// 单例医案详情：12 字段逐条展示。
class MedicalCaseDetailScreen extends StatelessWidget {
  final MedicalCase c;
  const MedicalCaseDetailScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = <(String, String)>[
      ('日期', c.date),
      ('患者', c.patient),
      ('主要诊断', c.diagnosis),
      ('中医病机', c.mechanism),
      ('西医背景', c.western),
      ('方剂组成', c.formula),
      ('针灸方案', c.acupuncture),
      ('治法原则', c.method),
      ('疗程结果', c.result),
      ('生活医嘱', c.advice),
      ('倪师观点', c.view),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('#${c.seq} 医案')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (label, value) = rows[index];
          if (value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
