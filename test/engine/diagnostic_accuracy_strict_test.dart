import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

/// 规则引擎 top() 精确命中测试。
/// 用例与 engine_test.py（Python 端口，解析同一份 formula_rules.dart）逐一对应，
/// 已对照真实规则数据验证通过。
void main() {
  group('RuleEngine.top 精确命中', () {
    // (q, ext, 期望 top 方名；null 表示期望无候选)
    final cases = <(String, Map<String, int>, Set<String>, String?)>[
      ('桂枝汤(太阳中风有汗脉缓)', {kQ1: 1, kQ4: 2, kQ2: 12, kQ3: 1, kQ5: 1, kQ10: 2}, {}, '桂枝汤'),
      ('麻黄汤(无汗恶寒脉浮紧)', {kQ1: 7, kQ4: 1, kQ2: 1, kQ3: 1, kQ5: 2, kQ10: 2}, {}, '麻黄汤'),
      ('炙甘草汤(脉结代心动悸)', {kQ2: 14, kQ5: 18, kQ10: 2, kQ1: 1, kQ3: 2, kQ9: 4}, {}, '炙甘草汤'),
      ('五苓散(渴+小便不利)', {kQ3: 2, kQ7: 5, kQ2: 1, kQ1: 1, kQ6: 3}, {}, '五苓散'),
      ('小柴胡汤(往来寒热胸胁苦满口苦)', {kQ1: 3, kQ5: 5, kQ3: 5, kQ9: 2, kQ8: 2, kQ10: 4, kQ7: 2, kQ12: 3}, {}, '小柴胡汤'),
      ('白虎汤(大热大渴大汗)', {kQ1: 1, kQ3: 7, kQ4: 7, kQ2: 4, kQ10: 4, kQ5: 1}, {}, '白虎汤'),
      ('蜜煎导猪胆汁导(汗出+便秘,津液内竭)', {kQ6: 2, kQ4: 2}, {}, '蜜煎导猪胆汁导'),
      ('蜜煎导(纯便秘无汗,应无候选)', {kQ6: 2}, {}, null),
      ('四逆汤(厥逆脉微但欲寐)', {kQ1: 6, kQ2: 10, kQ10: 3, kQ3: 1, kQ6: 7, kQ7: 7, kQ5: 9, kQ8: 7}, {}, '四逆汤'),
      ('白头翁加甘草阿胶汤(便脓血+腹痛拒按)', {kQ6: 6, kQ5: 7, kQ2: 9, kQ10: 2}, {}, '白头翁加甘草阿胶汤'),
      ('防己黄芪汤(汗出+身重浮肿)', {kQ4: 2, kQ1: 7, kQ7: 5, kQ2: 11, kQ5: 8}, {'edema'}, '防己黄芪汤'),
      ('桂枝附子汤(仅风寒痛,无汗)', {kQ1: 7, kQ5: 8}, {}, '桂枝附子汤'),
      ('甘草附子汤(风寒痛+汗出短气+小便不利)', {kQ1: 7, kQ5: 8, kQ4: 2, kQ7: 5}, {}, '甘草附子汤'),
      ('甘草附子汤(风寒痛+汗出,无小便不利)', {kQ1: 7, kQ5: 8, kQ4: 2}, {}, '甘草附子汤'),
      ('桂枝芍药知母汤(风寒痛+汗出+短气+诸肢节痛+尫羸)', {kQ1: 7, kQ5: 8, kQ4: 2, kQ10: 2}, {'all_joints_pain', 'body_emaciated'}, '桂枝芍药知母汤'),
      ('空输入(应无候选)', {}, {}, null),
      // ---- 11 首 v3.2 终审方剂 ----
      ('大陷胸丸(★胸膈心下硬满+项背强)', {}, {'chest_diaphragm_hard', 'nape_stiff'}, '大陷胸丸'),
      ('大陷胸丸(缺项背强,★缺失不应出)', {}, {'chest_diaphragm_hard'}, null),
      ('瓜蒂散(★胸中痞硬)', {}, {'chest_hard_full'}, '瓜蒂散'),
      ('葶苈大枣泻肺汤(★胸满不能卧)', {}, {'chest_full_no_lie'}, '葶苈大枣泻肺汤'),
      ('猪膏发煎(身黄肌肤枯燥)', {}, {'jaundice_dry_skin'}, '猪膏发煎'),
      ('猪膏发煎(plain黄疸,非专属应不出)', {}, {'jaundice'}, null),
      ('皂荚丸(咳喘不得卧)', {}, {'wheeze_no_lie'}, '皂荚丸'),
      ('橘枳姜汤(胸中气塞)', {}, {'chest_qi_block'}, '橘枳姜汤'),
      ('旋覆花汤(肝着常欲蹈胸)', {}, {'liver_attachment'}, '旋覆花汤'),
      ('柏叶汤(吐血不止)', {}, {'hematemesis'}, '柏叶汤'),
      ('矾石散(带下异常)', {}, {'leukorrhea'}, '矾石散'),
      ('蛇床子散(阴中寒)', {}, {'vulva_cold'}, '蛇床子散'),
      ('狼牙汤(阴中蚀疮)', {}, {'vulva_ulcer'}, '狼牙汤'),
      ('真武汤(★手足温冷异常+小便不利+头眩,去重只1条)', {kQ1: 6, kQ7: 5, kQ5: 19}, {}, '真武汤'),
    ];

    for (final (label, q, ext, expected) in cases) {
      test(label, () {
        final top = RuleEngine.top(q, ext);
        if (expected == null) {
          expect(top, isNull, reason: '期望无候选');
        } else {
          expect(top, isNotNull, reason: '期望命中 $expected');
          expect(top!.rule.name, expected);
        }
      });
    }
  });
}
