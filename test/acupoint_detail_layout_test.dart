import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/models/acupoint_detail.dart';
import 'package:nihaisha_app/screens/acupoint_detail_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

/// 「属性」块布局回归。
///
/// 曾经用 Chip 承载 attribute，Chip 内 Text 不换行，窄屏被裁掉大半
/// （实测 54 字需 761dp，320dp 屏只得 254dp）。这类裁剪**不抛异常**，
/// 只能靠几何断言守：换行后渲染高度必须高于单行。
const String _longAttr =
    '手厥阴心包经络穴，通阴维脉（八脉交会穴）；条文作「手心主之络，别走少阴」，'
    '络脉篇作「别走少阳」，两源并存待考';

const AcupointDetail _p = AcupointDetail(
  name: '内关穴',
  meridian: '手厥阴心包经',
  attribute: _longAttr,
  clinicalNotes: '【倪师主治思路】内关是心包经的络穴，通阴维脉，主心胸胃的病。',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('320dp + 字号 2.0：54 字属性换行显示、不被裁', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(2.0)),
        child: child!,
      ),
      home: const AcupointDetailScreen(acupoint: _p),
    ));
    await tester.pump();

    final para = tester.renderObject<RenderParagraph>(find.text(_longAttr));
    // 单行高度约 2 倍字高（约 40dp @2.0x）；换行后必然明显更高。
    expect(para.size.height, greaterThan(60),
        reason: '属性未换行——说明又被约束成单行裁掉了');
    expect(para.size.width, lessThanOrEqualTo(320 - 32 + 0.5),
        reason: '属性宽度超出内容区');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
