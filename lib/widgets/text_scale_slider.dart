import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 「小 —— 滑块 —— 大」字号调节控件。
///
/// 设置页与快捷外观弹窗共用同一实现，档位口径见 [AppTextScale]
/// （0.8 ~ 2.0，每档 5%）。两处入口若各写一份 Slider，极易再次出现
/// 上限不一致的问题，故统一收敛到这里。
class TextScaleSlider extends StatelessWidget {
  const TextScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 当前缩放值（越界值会被 [AppTextScale.normalize] 收敛后展示）。
  final double value;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = AppTextScale.normalize(value);
    return Row(
      children: [
        const Text('小', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Slider(
            value: current,
            min: AppTextScale.min,
            max: AppTextScale.max,
            divisions: AppTextScale.divisions,
            label: '${(current * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        const Text('大', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
