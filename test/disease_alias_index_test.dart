// 古今病名 / 中西医病名对照索引：资产合规 + 检索扩展 + 上下文注入。
// 运行：flutter test test/disease_alias_index_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/disease_alias_index.dart';
import 'package:nihaisha_app/services/llm_service.dart';

String _norm(String s) =>
    s.replaceAll('…', '').replaceAll(RegExp(r'\s+'), '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiseaseAliasIndex index;

  setUpAll(() async {
    index = await DiseaseAliasIndex.load();
  });

  group('资产合规', () {
    test('索引非空且两类都在（古今差异 / 中西医叫法）', () {
      expect(index.entries.length, greaterThan(30));
      expect(index.entries.any((e) => e.kind == 'gujin'), isTrue);
      expect(index.entries.any((e) => e.kind == 'zhongxi'), isTrue);
      for (final e in index.entries) {
        expect(e.ancient, isNotEmpty);
        expect(e.moderns, isNotEmpty, reason: '${e.ancient} 缺少今名/西医名');
        expect(e.moderns, isNot(contains(e.ancient)),
            reason: '${e.ancient} 的现代名不能与古名相同');
      }
    });

    test('每条 note 都是倪师材料原文（逐字可回溯到 src 文件）', () {
      for (final e in index.entries) {
        expect(e.note, isNotEmpty, reason: '${e.ancient} 缺少原文依据');
        expect(e.sources, isNotEmpty, reason: '${e.ancient} 缺少出处');
        var found = false;
        for (final s in e.sources) {
          final f = File(s);
          if (!f.existsSync()) continue;
          if (_norm(f.readAsStringSync()).contains(_norm(e.note))) {
            found = true;
            break;
          }
        }
        expect(found, isTrue,
            reason: '${e.ancient} 的 note「${e.note}」在 ${e.sources} 中找不到原文，'
                '说明不是从材料整理出来的');
      }
    });
  });

  group('匹配与扩展', () {
    test('问今天的病名能命中古名对照', () {
      final hit = index.match('糖尿病怎么治？');
      expect(hit.map((e) => e.ancient), contains('消渴'));
      expect(hit.first.note, isNotEmpty);
    });

    test('问西医名能命中中医名（支饮 ↔ 胸水）', () {
      final hit = index.match('胸水是什么');
      expect(hit.map((e) => e.ancient), contains('支饮'));
    });

    test('检索扩展同时给出古名与今名', () {
      final hit = index.match('糖尿病');
      final terms = index.expandTerms(hit);
      expect(terms, contains('消渴'));
      expect(terms, contains('糖尿病'));
    });

    test('无关提问不误命中', () {
      expect(index.match('今天天气怎么样'), isEmpty);
    });

    test('同名异义会被标出来（寒疝 ≠ 西医疝气）', () {
      final hit = index.match('寒疝怎么办');
      expect(hit.map((e) => e.ancient), contains('寒疝'));
      expect(hit.first.note, contains('不太一样'),
          reason: '寒疝与西医疝气必须点明差异，不能当作同一病');
    });
  });

  group('注入上下文', () {
    test('brief 带上倪师原话与方向标签', () {
      final s = DiseaseAliasIndex.brief(index.match('消渴'));
      expect(s, contains('【古今·中西医病名对照'));
      expect(s, contains('消渴'));
      expect(s, contains('糖尿病'));
      expect(s, isNot(contains('（本次检索没有命中讲义内容）')));
    });

    test('buildContext 里病名对照排在讲义片段之后、提问之前', () {
      final c = LlmService.buildContext(
        const [],
        '消渴怎么辨',
        diseaseBrief: DiseaseAliasIndex.brief(index.match('消渴')),
      );
      expect(c.indexOf('【古今·中西医病名对照'), greaterThan(-1));
      expect(c.indexOf('【古今·中西医病名对照'),
          lessThan(c.indexOf('【提问】')));
    });

    test('prepare 会把古名补进检索（问糖尿病能拿到消渴条文）', () async {
      final r = await LlmService.prepare('糖尿病怎么辨治？');
      expect(r.diseaseBrief, contains('消渴'));
      final joined = r.classics.map((h) => '${h.title}${h.snippet}').join();
      expect(joined.contains('消渴') || joined.contains('糖尿病'), isTrue,
          reason: '病名扩展后必须真的把对应条文检索出来，否则只是显示了个标签');
    });
  });
}
