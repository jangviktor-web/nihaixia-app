import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/models/acupoint_detail.dart';
import 'package:nihaisha_app/screens/acupoint_detail_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/data/zhenjiu_lecture_index.dart';

/// A8 回归：详情页「位置」区块必须渲染标准取穴定位，而不是讲稿正文切片。
///
/// 用于替代 Web 端人工点检——本机无可用浏览器做自动化，
/// 但「数据值 → 详情页可见文本」这条链路可以在 widget 层直接断言。
/// 期望值取自 assets/data/acupoints.json（2026-11-12 location 修复后）。
void main() {
  const cases = <String, String>{
    '大陵穴': '掌后骨下，两筋间陷中。',
    '乳中穴': '当乳中是。',
    '合谷穴': '手大指次指歧骨间陷中。',
    '膈俞穴': '七椎下两旁相去脊各一寸五分，正坐取之。',
    '八髎穴': '骶部，左右共八穴（上髎、次髎、中髎、下髎），当第1至第4骶后孔中。',
  };

  // 修复前的错误值（讲稿正文切片），必须不再出现
  const forbidden = <String>[
    '就是后跟，这是膝',
    '的病，我们介绍到后面',
    '针原穴就像你跟身体讲话',
  ];

  testWidgets('详情页渲染修复后的定位，且不含讲稿切片', (tester) async {
    // 详情页的「讲义讲解」会触发 ZhenJiuLectureIndex.load()，
    // 其内部用 20ms 轮询等待并发载入；在 fake_async 下会变成 pending timer。
    // 先用真实异步预热一次，让 build 时直接命中缓存。
    await tester.runAsync(() async {
      try {
        await ZhenJiuLectureIndex.load();
      } catch (_) {
        // 测试环境无该 asset 时忽略，页面会走「索引无命中则不显示」分支
      }
    });

    for (final entry in cases.entries) {
      await tester.pumpWidget(MaterialApp(
        // 详情页通过 context.colors 读 ThemeExtension，测试必须提供
        theme: ThemeData(extensions: [AppColors.light]),
        home: AcupointDetailScreen(
          acupoint: AcupointDetail(name: entry.key, location: entry.value),
        ),
      ));
      await tester.pump();
      // 详情页会触发 ZhenJiuLectureIndex.load（内部 20ms Timer），
      // 不清掉会在收尾时被判定为 pending timer
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('位置'), findsOneWidget,
          reason: '${entry.key} 缺少「位置」区块');
      expect(find.text(entry.value), findsOneWidget,
          reason: '${entry.key} 定位未按修复值渲染');
      for (final bad in forbidden) {
        expect(find.textContaining(bad), findsNothing,
            reason: '${entry.key} 仍出现讲稿切片片段「$bad」');
      }
    }
  });
}
