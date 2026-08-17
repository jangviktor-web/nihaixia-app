import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/neijing_lecture_data.dart';
import 'package:nihaisha_app/screens/neijing_library_screen.dart';
import 'package:nihaisha_app/screens/neijing_search_screen.dart';

/// 内经阅读库 + 全文搜索：数据完整性 + 页面冒烟。
void main() {
  group('阅读库索引数据', () {
    test('73 条（前言 + 72 篇），asset 文件全部存在', () {
      expect(kNeiJingLectures.length, 73);
      expect(kNeiJingLectures.first.seq, 0);
      expect(kNeiJingLectures.first.name, '前言');
      for (final l in kNeiJingLectures) {
        expect(l.asset, startsWith('assets/neijing/'));
        expect(File(l.asset).existsSync(), isTrue,
            reason: '缺少资源 ${l.asset}');
      }
      // 首篇与末篇
      expect(kNeiJingLectures[1].seq, 1);
      expect(kNeiJingLectures[1].name, '上古天真论');
      expect(kNeiJingLectures.last.seq, 81);
      // asset 查询
      expect(neijingAsset(1), kNeiJingLectures[1].asset);
      expect(neijingAsset(25), isNull); // 原稿未收录
    });
  });

  group('阅读库页冒烟', () {
    testWidgets('渲染篇目列表并进入首篇', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NeijingLibraryScreen()),
      );
      await tester.pump();
      expect(find.text('黄帝内经 · 阅读库'), findsOneWidget);
      expect(find.text('上古天真论'), findsOneWidget);

      // 时序关键：tap 触发导航后【立即 pump】，让新路由的 initState
      // 在 runAsync 的真实 zone 中执行（rootBundle.loadString 才走真实 IO，
      // 否则回 fake zone 后被 mock messenger 拦截永不完成）；
      // 再等真实 IO 完成，pump 渲染 FutureBuilder 完成态。
      await tester.runAsync(() async {
        await tester.tap(find.text('上古天真论'));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 1200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // 进入 MarkdownDocScreen：正文渲染 markdown 一级标题（中文序数）
      expect(find.text('第一篇 上古天真论'), findsOneWidget);
    });
  });

  group('全文搜索页冒烟', () {
    testWidgets('输入关键词命中篇目', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NeijingSearchScreen()),
      );
      await tester.pump();

      // onTap 触发 _ensureLoaded：与阅读库一致，tap 后【立即 pump】，
      // 让 onTap 回调在 runAsync 真实 zone 中执行（否则 loadString 挂起）。
      await tester.runAsync(() async {
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await Future.delayed(const Duration(seconds: 3));
      });
      await tester.pump();

      await tester.enterText(find.byType(TextField), '阴阳');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 命中排序（按次数降序）：着至教论(136) > 阴阳应象大论(84) >
      // 脉要精微论(53) > 阴阳别论(42)。前两项在视口内必可见；
      // 阴阳离合论(25) 排第 9 位左右，在 lazy ListView 视口外，不断言。
      expect(find.text('阴阳应象大论'), findsOneWidget);
      expect(find.text('阴阳别论'), findsOneWidget);
      // 命中计数徽标存在（视口内每项都有「N 处」）
      expect(find.textContaining('处'), findsWidgets);
    });
  });
}
