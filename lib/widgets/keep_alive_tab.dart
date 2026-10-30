import 'package:flutter/material.dart';

/// 让 [TabBarView] 的子页在切走后保持存活。
///
/// 默认 TabBarView 走 PageView：切走的页面会被卸载，再切回来要**整页重建**
/// （知识库的方剂/本草/针灸都是几百上千条的长列表，重建时第一帧要同步构建
/// 首屏所有 item，直观感受就是「切 tab 卡一下」），筛选条件与滚动位置也会丢。
/// 套一层 [KeepAliveTab] 后页面只构建一次。
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求
    return widget.child;
  }
}
