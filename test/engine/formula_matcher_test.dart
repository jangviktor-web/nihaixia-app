import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_oral_hint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/formula_matcher.dart';
import 'package:nihaisha_app/models/formula.dart';

/// 最小可用 Formula 构造器（仅填充匹配器需要的字段）。
Formula _mk(String id, {List<String> keywords = const []}) => Formula(
      id: id,
      name: id,
      meridian: '太阳',
      category: '解表',
      components: const [],
      indication: '',
      keywords: keywords,
    );

void main() {
  // ========== 验收标准 1：数据加载 ==========
  group('FormulaOralHintRepository 加载', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await FormulaOralHintRepository.load();
    });

    test('加载 170 条且关键字段完整', () {
      expect(FormulaOralHintRepository.count, 170);
      final h = FormulaOralHintRepository.getById('guizhi_tang');
      expect(h, isNotNull);
      expect(h!.oral, isNotEmpty);
      expect(h.indicators, isNotEmpty);
      expect(h.treatment, isNotEmpty);
      expect(h.sourceText, isNotEmpty);
    });

    test('未加载时为 null（向后兼容底线）', () {
      // 真实 id 存在，但仓库已加载；此处验证 getById 对不存在的 id 返回 null，
      // 保证资源缺失时匹配器退化为纯基线、辨证不崩溃。
      expect(FormulaOralHintRepository.getById('no_such_formula_xyz'), isNull);
    });
  });

  // ========== 验收标准 2：非劣化不变式 ==========
  group('FormulaMatcher 非劣化不变式', () {
    test('enhancementCap 严格小于 1（排序不变式前提）', () {
      // rank 证明：设基线分整数 b，增强分 e<1，则 b(X)>b(Y) 必然 score(X)>score(Y)。
      expect(FormulaMatcher.enhancementCap, lessThan(1.0));
    });

    test('基线分更高者 rank 中永远排在前面', () {
      final strong = _mk('strong', keywords: ['发热', '恶寒']);
      final weak = _mk('weak'); // 无 keywords，基线 0
      final ranked =
          FormulaMatcher.rank([strong, weak], ['发热', '恶寒'], topK: 5);
      expect(ranked, isNotEmpty);
      expect(ranked.first.$1, 'strong');
    });
  });

  // ========== 验收标准 3：口语语料召回增益（真实数据） ==========
  group('口语语料召回增益（真实数据）', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await FormulaRepository.load();
      await FormulaOralHintRepository.load();
    });

    test('桂枝汤：现代口语词 baseline=0 但 enhancement>0', () {
      final gz = FormulaRepository.getById('guizhi_tang');
      expect(gz, isNotNull);
      final base = FormulaMatcher.baselineScore(gz!, ['特别怕风']);
      final enh = FormulaMatcher.enhancementScore(gz, ['特别怕风']);
      // 改造前：古文体 keywords/indication/name/alias 不含"特别怕风" → 字面匹配 0 命中
      expect(base, 0);
      // 改造后：语料 indicators 含"特别怕风" → 加权命中捞回
      expect(enh, greaterThan(0));
    });

    test('rank 对真实查询返回非空且分数均>0', () {
      final all = FormulaRepository.getAll();
      final ranked =
          FormulaMatcher.rank(all, ['怕冷', '发热', '出汗'], topK: 5);
      expect(ranked, isNotEmpty);
      for (final r in ranked) {
        expect(r.$2, greaterThan(0));
      }
    });

    test('语料未加载时 enhancementScore 退化为 0（不崩溃、不影响基线）', () {
      // 构造一个完全不在语料中的 id，enhancement 必须为 0，rank 退化回纯基线。
      final orphan = _mk('orphan_no_hint', keywords: ['发热']);
      expect(FormulaMatcher.enhancementScore(orphan, ['发热']), 0.0);
      final ranked = FormulaMatcher.rank([orphan], ['发热'], topK: 5);
      expect(ranked.first.$2, FormulaMatcher.baselineScore(orphan, ['发热']));
    });
  });
}
