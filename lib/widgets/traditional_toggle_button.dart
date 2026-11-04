import 'package:flutter/material.dart';

import '../data/settings_repository.dart';

/// 繁简显示切换按钮（阅读页 / 药材详情 / 方剂详情共用）。
///
/// 点击翻转全局开关 `traditionalDisplayEnabled`，然后回调 [onChanged]，
/// 由各页面自行重载内容（阅读页重取正文，详情页重跑批量转换）。
/// 图标状态在页面 setState 后随之刷新。
class TraditionalToggleButton extends StatelessWidget {
  const TraditionalToggleButton({super.key, this.onChanged});

  /// 开关翻转后触发（页面在此重载内容 + setState）。
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final on = SettingsRepository.instance.traditionalDisplayEnabled;
    return IconButton(
      icon: Icon(
        Icons.translate,
        color: on ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: on ? '关闭繁体显示' : '繁体显示',
      onPressed: () async {
        await SettingsRepository.instance.setTraditionalDisplayEnabled(!on);
        onChanged?.call();
      },
    );
  }
}
