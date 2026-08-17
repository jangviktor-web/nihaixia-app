/// 倪师医案合并蒸馏表格（1257 例）数据模型与解析。
///
/// 原始表格为 markdown（assets/medical_cases/cases_table.md，12 列）。
/// 不在编译期展开为常量（避免 685KB 膨胀），改为运行时按行解析。
/// 内容属传统文化参考，非医疗建议。

class MedicalCase {
  final int seq;
  final String date;
  final String patient;
  final String diagnosis; // 主要诊断（中医）
  final String mechanism; // 中医病因分析（关键病机）
  final String western; // 西医背景与观点
  final String formula; // 具体方剂剂量/治疗组成
  final String acupuncture; // 针灸方案
  final String method; // 中医治疗方法（原则）
  final String result; // 疗程/结果
  final String advice; // 生活医嘱
  final String view; // 倪海厦核心观点/评论

  const MedicalCase({
    required this.seq,
    this.date = '',
    this.patient = '',
    this.diagnosis = '',
    this.mechanism = '',
    this.western = '',
    this.formula = '',
    this.acupuncture = '',
    this.method = '',
    this.result = '',
    this.advice = '',
    this.view = '',
  });

  /// 全文检索命中（诊断/方剂/结果/观点/病机）。
  bool matches(String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return diagnosis.toLowerCase().contains(lower) ||
        formula.toLowerCase().contains(lower) ||
        result.toLowerCase().contains(lower) ||
        view.toLowerCase().contains(lower) ||
        mechanism.toLowerCase().contains(lower) ||
        patient.toLowerCase().contains(lower);
  }

  /// 医案展示名：优先「主要诊断」，缺失时回退「中医病机」，再缺失显「（未命名）」。
  String get displayName {
    if (diagnosis.isNotEmpty) return diagnosis;
    if (mechanism.isNotEmpty) return mechanism;
    return '（未命名）';
  }
}

/// 解析 markdown 表格文本为病例列表。
/// 跳过表头（首格「序号」）与分隔行（含 `---`），仅收录首格为数字的行。
/// 质量门禁：方剂为空 / 含「未公开」/ 占位「未提及」的医案直接剔除（无可用方剂）。
List<MedicalCase> parseMedicalCaseTable(String md) {
  final lines = md.split('\n');
  final cases = <MedicalCase>[];

  for (final raw in lines) {
    final line = raw.trim();
    if (!line.startsWith('|')) continue;

    // 按 | 切分后，仅去除首尾由外框竖线产生的空串；
    // 【保留内部空单元格】以维持 12 列对齐（中间列为空不应导致后续列左移）。
    final rawCells = line.split('|').map((c) => c.trim()).toList();
    if (rawCells.isNotEmpty && rawCells.first.isEmpty) rawCells.removeAt(0);
    if (rawCells.isNotEmpty && rawCells.last.isEmpty) rawCells.removeLast();
    final cells = rawCells;
    if (cells.isEmpty) continue;

    // 表头 / 分隔行
    if (cells[0] == '序号' ||
        cells[0].contains('---') ||
        RegExp(r'^-+$').hasMatch(cells[0])) {
      continue;
    }

    final seq = int.tryParse(cells[0]);
    if (seq == null) continue;

    // 补齐至 12 列，防止短行越界
    final padded = List<String>.from(cells);
    while (padded.length < 12) padded.add('');
    // 源表以「---」作为空值占位，归一为空串以便详情页隐藏
    for (var i = 0; i < padded.length; i++) {
      if (padded[i] == '---') padded[i] = '';
    }

    // 质量门禁：无可用方剂的医案剔除（空 / 未公开 / 未提及）
    final formula = padded[6];
    if (formula.trim().isEmpty) continue;
    if (formula.contains('未公开')) continue;
    if (formula.trim() == '未提及') continue;

    cases.add(MedicalCase(
      seq: seq,
      date: padded[1],
      patient: padded[2],
      diagnosis: padded[3],
      mechanism: padded[4],
      western: padded[5],
      formula: padded[6],
      acupuncture: padded[7],
      method: padded[8],
      result: padded[9],
      advice: padded[10],
      view: padded[11],
    ));
  }

  return cases;
}
