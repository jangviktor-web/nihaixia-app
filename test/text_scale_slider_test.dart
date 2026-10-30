// 字号档位回归：上限必须能到 200%（issue #4 用户需求），且两处入口共用同一口径。
// 运行：flutter test test/text_scale_slider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/theme/app_tokens.dart';
import 'package:nihaisha_app/widgets/text_scale_slider.dart';

void main() {
  test('档位口径：0.8 ~ 2.0，每档 5%，共 24 档', () {
    expect(AppTextScale.min, 0.8);
    expect(AppTextScale.max, 2.0, reason: 'issue #4：字号需可调到 200%');
    expect(AppTextScale.step, 0.05);
    expect(AppTextScale.divisions, 24);
    expect(
      (AppTextScale.max - AppTextScale.min) / AppTextScale.step,
      closeTo(AppTextScale.divisions.toDouble(), 1e-9),
      reason: 'divisions 必须与区间/步长自洽，否则滑块会出现非整档位',
    );
  });

  test('normalize：越界值收敛，区间内原样返回', () {
    expect(AppTextScale.normalize(3.0), AppTextScale.max);
    expect(AppTextScale.normalize(0.5), AppTextScale.min);
    expect(AppTextScale.normalize(1.25), 1.25);
  });

  testWidgets('滑块上限 200%，拖到最右端回传 2.0', (tester) async {
    double value = 1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TextScaleSlider(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, AppTextScale.min);
    expect(slider.max, 2.0);
    expect(slider.divisions, AppTextScale.divisions);

    // 拖动滑块到轨道最右端：值应被推到上限，且不会越界。
    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await tester.pump();

    expect(value, AppTextScale.max, reason: '拖到最右端应可拿到 200%');
    expect(tester.widget<Slider>(find.byType(Slider)).value, AppTextScale.max);
  });

  testWidgets('外部传入越界值时按上限渲染，不触发 Slider 断言', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextScaleSlider(value: 2.6, onChanged: (_) {}),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, AppTextScale.max);
  });

  testWidgets('200% 下控件自身布局不溢出', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextScaleSlider(value: 2.0, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull, reason: '字号拉满时滑块行不应溢出');
  });
}
