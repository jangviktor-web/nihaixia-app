import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/models/acupoint_detail.dart';
import 'package:nihaisha_app/screens/acupoint_detail_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/data/zhenjiu_lecture_index.dart';

/// 回归：description / location 同时为空的穴位，详情页必须仍能正常渲染。
///
/// 事故背景（2026-11-14）：穴位列表卡片曾用
/// `description.isNotEmpty || location.isNotEmpty` 作为「能否点开」的开关，
/// 导致印堂穴、中枢、急脉三条的 onTap 被置为 null，点击无反应，
/// 表现为「详情页无法打开」。列表侧已改为恒可点击，本测试守住详情页本身。
void main() {
  const sparse = <AcupointDetail>[
    AcupointDetail(
      name: '印堂穴',
      meridian: '督脉',
      attribute: '经外奇穴；不属于督脉二十八穴，也不列入督脉经穴歌。',
      clinicalNotes: '注：讲义未针对印堂作专门论述，取中脘治疗印堂痛。',
    ),
    AcupointDetail(
      name: '中枢',
      meridian: '督脉',
      attribute: '督脉穴（讲义未给本穴独立条文）。',
      clinicalNotes: '倪师讲义中未针对本穴作特别临床论述。',
    ),
    AcupointDetail(
      name: '急脉',
      meridian: '足厥阴肝经',
      clinicalNotes: '【书证】以上即讲义中与本穴相关的全部文字。',
    ),
  ];

  testWidgets('字段稀疏的穴位详情页可正常打开', (tester) async {
    await tester.runAsync(() async {
      try {
        await ZhenJiuLectureIndex.load();
      } catch (_) {}
    });

    for (final a in sparse) {
      expect(a.description.isEmpty && a.location.isEmpty, isTrue,
          reason: '${a.name} 应作为稀疏数据样本');

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [AppColors.light]),
        home: AcupointDetailScreen(acupoint: a),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(a.name), findsWidgets,
          reason: '${a.name} 详情页标题未渲染');
      expect(find.text('古籍原文'), findsOneWidget,
          reason: '${a.name} 缺少古籍原文入口');
      if (a.clinicalNotes.isNotEmpty) {
        expect(find.text('倪海厦临床心悟'), findsOneWidget,
            reason: '${a.name} 缺少临床心悟区块');
      }
      expect(tester.takeException(), isNull,
          reason: '${a.name} 详情页渲染抛异常');
    }
  });

  testWidgets('同一位置换 acupoint：标题与正文同步切换（滑动切换的基础）', (tester) async {
    await tester.runAsync(() async {
      try {
        await ZhenJiuLectureIndex.load();
      } catch (_) {}
    });

    const a = AcupointDetail(name: '印堂穴', meridian: '督脉', clinicalNotes: '甲内容。');
    const b = AcupointDetail(name: '中枢', meridian: '督脉', clinicalNotes: '乙内容。');

    Future<void> pumpOne(AcupointDetail x) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [AppColors.light]),
        home: AcupointDetailScreen(acupoint: x),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await pumpOne(a);
    expect(find.text('印堂穴'), findsWidgets);

    // 同位置替换会复用 State：若未在 didUpdateWidget 重算同经络列表，
    // 标题仍会停在「印堂穴」——这条断言就是它的回归检查。
    await pumpOne(b);
    expect(find.text('中枢'), findsWidgets, reason: '换穴后标题未更新');
    expect(find.text('印堂穴'), findsNothing, reason: '换穴后残留上一个穴的标题');
    expect(tester.takeException(), isNull);
  });
}
