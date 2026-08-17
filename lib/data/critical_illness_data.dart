/// 倪师人纪班闭门课·七大重症临床索引。
///
/// 内容来源：人纪-6-人纪班闭门课（血癌/红斑性狼疮/脑瘤/肾衰竭尿毒症/乳癌/肝癌）
/// + 扶阳论坛重症讲义。原文为倪师口述，属传统文化参考，非医疗建议。
/// 正文见 assets/critical_illness/*.md，经 MarkdownDocScreen 渲染。
class CriticalIllness {
  final String title; // 病名
  final String subtitle; // 病机/辨证要点摘要
  final String asset; // assets/critical_illness/ 下文件名
  final List<String> tags; // 文中重点方剂（可点跳转 FormulaDetailScreen）
  final bool isOverview; // 是否为总览/前言

  const CriticalIllness({
    required this.title,
    required this.subtitle,
    required this.asset,
    this.tags = const [],
    this.isOverview = false,
  });
}

const List<CriticalIllness> kCriticalIllnesses = [
  CriticalIllness(
    title: '闭门课总览',
    subtitle: '生附子/生硫磺/粉剂体系 · 十大重症案例背景',
    asset: 'assets/critical_illness/0.前言.md',
    tags: const ['生附子', '生硫磺'],
    isOverview: true,
  ),
  CriticalIllness(
    title: '血癌',
    subtitle: '精子残渣逆流 · 奶水逆流 · 第六椎（灵台）压痛',
    asset: 'assets/critical_illness/1.血癌.md',
    tags: const ['炙甘草汤', '四逆汤', '生附子', '防己', '黄连阿胶汤'],
  ),
  CriticalIllness(
    title: '红斑性狼疮',
    subtitle: '奶水逆流入心 · 第五椎压痛 · 寒热并结',
    asset: 'assets/critical_illness/2.红斑性狼疮.md',
    tags: const ['生附子', '生硫磺', '四逆汤', '柴胡'],
  ),
  CriticalIllness(
    title: '脑瘤',
    subtitle: '痰迷心窍 · 疫苗后遗症 · 厥阴',
    asset: 'assets/critical_illness/3.脑瘤.md',
    tags: const ['生附子', '熟地', '生硫磺', '十枣汤', '小建中汤'],
  ),
  CriticalIllness(
    title: '肾衰竭尿毒症',
    subtitle: '里寒湿盛 · 心阳不足 · 肾阳回头则尿毒自解',
    asset: 'assets/critical_illness/4.肾衰竭尿毒症.md',
    tags: const ['生附子', '真武汤', '当归四逆汤', '四逆汤'],
  ),
  CriticalIllness(
    title: '乳癌',
    subtitle: '牛奶荷尔蒙 · 开刀化疗移转 · 术附汤排脓收敛',
    asset: 'assets/critical_illness/5.乳癌.md',
    tags: const ['防己', '瓦楞子', '牡蛎', '生附子', '黄连阿胶汤'],
  ),
  CriticalIllness(
    title: '肝癌',
    subtitle: '肝家阴实 · 阴阳决离 · 强心生阳破阴实',
    asset: 'assets/critical_illness/6.肝癌.md',
    tags: const ['生硫磺', '柴胡', '四逆汤', '小建中汤', '大柴胡汤'],
  ),
];
