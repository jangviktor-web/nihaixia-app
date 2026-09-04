import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database_helper.dart';
import '../data/medical_case_data.dart';
import '../widgets/formula_rich_text.dart';
import '../widgets/acupoint_rich_text.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'acupoint_detail_screen.dart';

/// 医案详情：12 字段逐条展示 + 收藏/复制/分享 + 相关医案。
/// [allCases] 由列表页传入，供底部「相关医案」计算（避免详情页重复解析全量）。
class MedicalCaseDetailScreen extends StatefulWidget {
  final MedicalCase c;
  final List<MedicalCase>? allCases;
  const MedicalCaseDetailScreen({super.key, required this.c, this.allCases});

  @override
  State<MedicalCaseDetailScreen> createState() =>
      _MedicalCaseDetailScreenState();
}

class _MedicalCaseDetailScreenState extends State<MedicalCaseDetailScreen> {
  bool _isBookmarked = false;

  /// 相关医案：首帧后异步计算，避免详情首屏因全量扫描方剂索引而卡顿；
  /// 列表页已后台预热缓存，此处通常在微任务内即完成，无可见延迟。
  List<MedicalCase> _related = const [];
  bool _relatedReady = false;

  MedicalCase get c => widget.c;

  @override
  void initState() {
    super.initState();
    _recordRecent();
    _checkBookmark();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final list = findRelatedCases(c, widget.allCases ?? const [], max: 6);
    if (!mounted) return;
    setState(() {
      _related = list;
      _relatedReady = true;
    });
  }

  Future<void> _recordRecent() async {
    try {
      await DatabaseHelper.instance.upsertMedicalCaseRecent(c.seq);
    } catch (_) {
      // 记录失败不阻断阅读
    }
  }

  Future<void> _checkBookmark() async {
    final ok = await DatabaseHelper.instance.isMedicalCaseBookmarked(c.seq);
    if (mounted) setState(() => _isBookmarked = ok);
  }

  Future<void> _toggleBookmark() async {
    final next = !_isBookmarked;
    await DatabaseHelper.instance.setMedicalCaseBookmarked(c.seq, next);
    if (!mounted) return;
    setState(() => _isBookmarked = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? '已收藏医案 #${c.seq}' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: c.toShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('医案文本已复制'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _shareText() async {
    await Share.share(c.toShareText());
  }

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

    final children = <Widget>[];
    for (final (label, value) in rows) {
      if (value.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              label == '方剂组成'
                  ? FormulaRichText(
                      formula: value,
                      onFormulaTap: (f) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormulaDetailScreen(formula: f),
                            ),
                          );
                        }
                      },
                      onHerbTap: (h) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HerbDetailScreen(herb: h),
                            ),
                          );
                        }
                      },
                    )
                  : label == '针灸方案'
                      ? AcupointRichText(
                          text: value,
                          onAcupointTap: (a) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AcupointDetailScreen(acupoint: a),
                                ),
                              );
                            }
                          },
                        )
                      : FormulaRichText(
                          formula: value,
                          onFormulaTap: (f) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FormulaDetailScreen(formula: f),
                                ),
                              );
                            }
                          },
                          onHerbTap: (h) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HerbDetailScreen(herb: h),
                                ),
                              );
                            }
                          },
                        ),
            ],
          ),
        ),
      );
    }

    final related = _relatedReady ? _related : const <MedicalCase>[];
    if (related.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '相关医案',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) =>
                      _relatedCard(context, related[index]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('#${c.seq}  ${c.displayName}'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _isBookmarked ? '取消收藏' : '收藏医案',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制医案文本',
            onPressed: _copyText,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享医案',
            onPressed: _shareText,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: children.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }

  Widget _relatedCard(BuildContext context, MedicalCase other) {
    final cs = Theme.of(context).colorScheme;
    final shared =
        c.formulaNames.where((n) => other.formulaNames.contains(n)).toList();
    return SizedBox(
      width: 210,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalCaseDetailScreen(
                  c: other,
                  allCases: widget.allCases,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${other.seq}  ${other.displayName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (shared.isNotEmpty)
                  Text(
                    '共方：${shared.join('、')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.primary),
                  )
                else
                  Text(
                    '同诊断',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
