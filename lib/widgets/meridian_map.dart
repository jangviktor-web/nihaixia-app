import 'package:flutter/material.dart';

/// 十四经循行穴位图（十二正经 + 任脉 + 督脉）。
///
/// 图片为 683×1024 的标准经络循行图，一图一档，文件名与经穴库
/// （`assets/data/acupoints.json`）的 `meridian` 字段**字面一致**，
/// 因此「选中哪条经就开哪张图」不需要额外的名称映射表。
/// 奇经八脉里的维脉/跷脉/冲脉/带脉，以及经外奇穴，目前没有对应图。
class MeridianMap {
  const MeridianMap._();

  /// 十四经，按十二经循行顺序排列（肺→大肠→胃→脾→心→小肠→膀胱→肾→
  /// 心包→三焦→胆→肝），任督二脉收尾。
  static const List<String> meridians = <String>[
    '手太阴肺经',
    '手阳明大肠经',
    '足阳明胃经',
    '足太阴脾经',
    '手少阴心经',
    '手太阳小肠经',
    '足太阳膀胱经',
    '足少阴肾经',
    '手厥阴心包经',
    '手少阳三焦经',
    '足少阳胆经',
    '足厥阴肝经',
    '任脉',
    '督脉',
  ];

  /// 该经络是否配有循行图。
  static bool has(String meridian) => meridians.contains(meridian);

  /// 图片资产路径。
  static String assetOf(String meridian) =>
      'assets/images/meridians/$meridian.webp';
}

/// 单条经络的循行穴位图（双指可放大到 6 倍，看清细小的穴名标注）。
class MeridianMapView extends StatelessWidget {
  /// 经络名，必须是 [MeridianMap.meridians] 之一。
  final String meridian;

  const MeridianMapView({super.key, required this.meridian});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 6,
      child: Center(child: Image.asset(MeridianMap.assetOf(meridian))),
    );
  }
}

/// 弹出经络图对话框。[initial] 为初始经络，缺省从手太阴肺经开起。
Future<void> showMeridianMapDialog(
  BuildContext context, {
  String? initial,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MeridianMapDialog(initial: initial),
  );
}

class _MeridianMapDialog extends StatefulWidget {
  final String? initial;

  const _MeridianMapDialog({this.initial});

  @override
  State<_MeridianMapDialog> createState() => _MeridianMapDialogState();
}

class _MeridianMapDialogState extends State<_MeridianMapDialog> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = (widget.initial != null && MeridianMap.has(widget.initial!))
        ? widget.initial!
        : MeridianMap.meridians.first;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: <Widget>[
                  Icon(Icons.account_tree_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '十四经循行穴位图',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: MeridianMap.meridians.length,
                itemBuilder: (BuildContext context, int index) {
                  final String m = MeridianMap.meridians[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(m, style: const TextStyle(fontSize: 11)),
                      selected: m == _current,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _current = m),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: MeridianMapView(meridian: _current)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Text(
                '图示为十四经循行穴位图，仅供学习参考',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
