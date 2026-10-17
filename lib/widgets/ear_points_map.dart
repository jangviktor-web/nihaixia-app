import 'package:flutter/material.dart';

/// 标准耳穴定位图：正面（图 A.15，84 穴）/ 背面（图 A.16，9 穴）。
///
/// 图片取自 GB/T 13734-2008 附录 A，经用户 2026-10-14 拍板直接嵌包
/// （详见对话记录），仅作学习参考用途，底部保留出处标注。
/// 按用户 2026-10-14 反馈：去掉水平镜像，按原始朝向展示（真机上镜像会导致图内穴名文字反读）。
/// `_flipX=false` 即原始朝向；置 true 才是水平镜像。
class EarPointsMap extends StatelessWidget {
  const EarPointsMap({super.key});

  /// 图片按原始朝向展示（不做水平镜像）。
  static const _flipX = false;

  Widget _sheet(String asset) {
    final image = Image.asset(asset);
    return InteractiveViewer(
      maxScale: 6,
      child: Center(
        child: _flipX
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1, 1, 1),
                child: image,
              )
            : image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TabBar(
            tabs: [Tab(text: '正面 84 穴'), Tab(text: '背面 9 穴')],
          ),
          SizedBox(
            height: 430,
            child: TabBarView(
              children: [
                _sheet('assets/images/ear_ref/ear_front.webp'),
                _sheet('assets/images/ear_ref/ear_back.webp'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '定位依据 GB/T 13734-2008《耳穴名称与定位》，图示取自附录 A，仅供学习参考',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
