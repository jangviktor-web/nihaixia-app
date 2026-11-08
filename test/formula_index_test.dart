// 方剂提及预索引（formula_index.json）：数据一致性最小验证。
// 判定逻辑本体（clauseIntroducesFormula 移植版）由
// `python tool/build_formula_index.py --selfcheck` 重放旧 Dart 测试断言验证，
// 此处只验索引资产与抽样命中。
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/classic_lecture_data.dart';
import 'package:nihaisha_app/data/formula_mention_index.dart';
import 'package:nihaisha_app/data/formula_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('方剂提及预索引', () {
    test('回归：方名 → seq → 卡片正文确实含该方名（shanghan_unified 切换）', () async {
      // 2026-11-06：旧 formula_index 的 s 是旧资产排序序，切换后全体静默错位，
      // 而范围检查全绿。这条检查的是「内容对不对」，不是「下标越不越界」。
      final idx = await FormulaMentionIndex.load();
      for (final name in const ['白虎汤', '桂枝汤', '小青龙汤']) {
        final m = idx.hitsFor(name);
        expect(m, isNotNull, reason: '$name 应有伤寒出处');
        for (final s in m!.shanghan) {
          final lecture = kShangHanLectures[s];
          final body = await rootBundle.loadString(lecture.asset);
          expect(body.contains(name), isTrue,
              reason: '$name seq=$s 指向 ${lecture.asset}，但该卡正文不含此方名');
        }
      }
    });

    test('可加载且命中方剂数合理', () async {
      final idx = await FormulaMentionIndex.load();
      final hitCount = [for (final f in const ['四逆汤', '桂枝汤', '小柴胡汤'])
        if (idx.hitsFor(f) != null) f].length;
      expect(hitCount, 3, reason: '核心三方必须命中');
    });

    test('四逆汤：伤寒条文命中且 seq 在范围内', () async {
      final idx = await FormulaMentionIndex.load();
      final m = idx.hitsFor('四逆汤')!;
      expect(m.shanghan, isNotEmpty);
      for (final s in m.shanghan) {
        expect(s, inInclusiveRange(0, kShangHanLectures.length - 1),
            reason: '伤寒 seq 越界');
      }
      for (final s in m.jingui) {
        expect(s, inInclusiveRange(0, 452), reason: '金匮 seq 越界');
      }
    });

    test('最长优先：四逆汤 的命中不含「茯苓四逆汤」专属条文（抽 74 条场景验证）', () async {
      final idx = await FormulaMentionIndex.load();
      final m = idx.hitsFor('四逆汤')!;
      final m2 = idx.hitsFor('茯苓四逆汤');
      // 若两者命中条文完全相同则必是归属错误（茯苓四逆汤条文不应归给四逆汤）
      if (m2 != null && m2.shanghan.isNotEmpty) {
        expect(
          m.shanghan.toSet().containsAll(m2.shanghan.toSet()),
          isFalse,
          reason: '四逆汤命中集不应完全覆盖茯苓四逆汤命中集',
        );
      }
    });

    test('讲稿提及 seq 均在讲稿范围内', () async {
      final idx = await FormulaMentionIndex.load();
      for (final name in const ['小柴胡汤', '桂枝汤']) {
        final m = idx.hitsFor(name);
        if (m == null) continue;
        for (final h in m.zhenjiu) {
          expect(h.seq, inInclusiveRange(0, 71), reason: '针灸 seq 越界');
          expect(h.count, greaterThan(0));
        }
        for (final h in m.bencao) {
          expect(h.seq, inInclusiveRange(0, 334), reason: '本草 seq 越界');
          expect(h.count, greaterThan(0));
        }
      }
    });

    test('回归：原文引文被空行截断的方仍能挂上（柴胡桂枝干姜汤）', () async {
      // 2026-11-03 修复前：引文块遇空行即中断 → 该方「见于经典」整条缺失。
      final idx = await FormulaMentionIndex.load();
      final m = idx.hitsFor('柴胡桂枝干姜汤');
      expect(m, isNotNull, reason: '柴胡桂枝干姜汤应有伤寒出处');
      expect(m!.shanghan, isNotEmpty, reason: '应命中伤寒条文');
    });

    test('回归：2026-11-03 合并的同方重复条目——旧名仍可检索到正名', () async {
      await FormulaRepository.load();
      // 三组合并：猪膏髪煎→猪膏发煎、乌头煎→大乌头煎、肾著汤→甘草干姜茯苓白术汤
      expect(FormulaRepository.search('猪膏髪煎').map((f) => f.name),
          contains('猪膏发煎'));
      expect(FormulaRepository.search('乌头煎').map((f) => f.name),
          contains('大乌头煎'));
      expect(FormulaRepository.search('肾著汤').map((f) => f.name),
          contains('甘草干姜茯苓白术汤'));
      expect(FormulaRepository.search('肾着汤').map((f) => f.name),
          contains('甘草干姜茯苓白术汤'));
      // 本轮再并：橘枳生姜汤→橘枳姜汤、厚朴人参汤→厚朴生姜半夏甘草人参汤、
      // 麻黄连翘赤小豆汤→麻黄连轺赤小豆汤（轺=连翘根），旧名均须可搜
      expect(FormulaRepository.search('橘枳生姜汤').map((f) => f.name),
          contains('橘枳姜汤'));
      expect(FormulaRepository.search('厚朴人参汤').map((f) => f.name),
          contains('厚朴生姜半夏甘草人参汤'));
      expect(FormulaRepository.search('连翘赤小豆汤').map((f) => f.name),
          contains('麻黄连轺赤小豆汤'));
      // 栀子枳实汤原条目漏「香豉」，已并入枳实栀子豉汤（宋本393 劳复方）
      expect(FormulaRepository.search('栀子枳实汤').map((f) => f.name),
          contains('枳实栀子豉汤'));
      expect(FormulaRepository.search('枳实栀子汤').map((f) => f.name),
          contains('枳实栀子豉汤'));
      expect(FormulaRepository.search('甘姜苓术汤').map((f) => f.name),
          contains('甘草干姜茯苓白术汤'));
      // 合并后条目总数 327 → 314（含新增桂苓甘草龙骨牡蛎汤、再并橘枳生姜汤/厚朴人参汤）；且不再有重名
      expect(FormulaRepository.getAll().length, 314);
      final names = FormulaRepository.getAll().map((f) => f.name).toList();
      expect(names.toSet().length, names.length, reason: '不应有重名方剂');
    });

    test('回归：大黄蟅虫丸异写可搜到正名（蛰/蟅/䗪 是异体字，不是繁简）', () async {
      await FormulaRepository.load();
      const canon = '大黄蟅虫丸';
      // 蟅 = 金匮讲稿正名；蛰 = 伤寒讲义写法；䗪 = 诊断引擎 formula_rules 正名；
      // 大黄虫丸 = 金匮讲稿掉字写法。四者同指金匮「内有干血…大黄蟅虫丸主之」。
      // 异体字不走 toSimplified（繁简表只处理 蟄→蛰），故由 alias 显式登记。
      for (final q in const [
        '大黄蛰虫丸',
        '大黄䗪虫丸',
        '大黄虫丸',
        '大黃蟄蟲丸',
        '蟅虫丸'
      ]) {
        expect(FormulaRepository.search(q).map((f) => f.name), contains(canon),
            reason: '$q 应命中正名 $canon');
      }
      // 诊断引擎产出的「大黄䗪虫丸」经 alias 兜底可跳方剂详情
      expect(FormulaRepository.resolveFormula('大黄䗪虫丸')?.name, canon);
      // getByName 的 12 个调用方（chat / 书签 / 讲义 / LLM 服务…）也要认别名
      for (final q in const ['大黄蛰虫丸', '大黄䗪虫丸', '大黄虫丸']) {
        expect(FormulaRepository.getByName(q)?.name, canon,
            reason: '$q 应能按 alias 打开方剂详情');
      }
    });

    test('回归：抵当汤 / 抵挡汤 是方言异写，四路索引归到正名', () async {
      await FormulaRepository.load();
      // 倪师原话：伤寒 237「抵当就是抵挡」；本草冬葵子「山东话抵挡…把它写成抵挡汤」。
      // 讲稿有意保留方言写法，故只在索引层归并，不改文本。
      expect(FormulaRepository.search('抵挡汤').map((f) => f.name),
          contains('抵当汤'));
      expect(FormulaRepository.getByName('抵挡汤')?.name, '抵当汤');
      expect(FormulaRepository.resolveFormula('抵挡汤')?.name, '抵当汤');

      final idx = await FormulaMentionIndex.load();
      final m = idx.hitsFor('抵当汤');
      expect(m, isNotNull, reason: '抵当汤应有提及索引');
      // 伤寒（宋本条号-1）、金匮 seq
      expect(m!.shanghan, containsAll(<int>[123, 124, 236, 256]));
      expect(m.jingui, contains(414));
      // 本草讲稿：29 牛膝 / 92 淮木 / 126 冬葵子 / 210 石龙子 均由「抵挡汤」写法新增
      expect(m.bencao.map((e) => e.seq), containsAll(<int>[29, 92, 126, 210]));
    });
  });
}
