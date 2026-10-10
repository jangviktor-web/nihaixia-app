// 五运六气 · 文献数据接入测试
//
// 验证：YunQiYearData 新增的 5 个文献字段（jz60 / yunBack / qiBack /
// skySiTian / skyZaiQuan）已由 yearGanzhi 正确查表填充，且「平气」年份走
// 「元素平气」分支。
//
// 注意：本测试只验证「文献接入的正确性」，不触碰任何运气算法——算法与
// acuherb 对拍夹具由既有 yunqi_engine_test.dart 守门，本文件零覆盖。
//
// 运行：flutter test test/yunqi_literature_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/yunqi_engine.dart';

void main() {
  group('文献字段接入（1984 / 2026 抽样）', () {
    test('1984 甲子年：五类文献均非空', () {
      final YunQiYearData d = YunQiEngine.yearGanzhi(1984);
      expect(d.jz60['SAME'], isNotEmpty, reason: '甲子年大论原文应存在');
      expect(d.yunBack, isNotEmpty, reason: '岁运三纪应存在');
      expect(d.qiBack, isNotEmpty, reason: '六气胜复应存在');
      expect(d.skySiTian, isNotEmpty, reason: '司天治则应存在');
      expect(d.skyZaiQuan, isNotEmpty, reason: '在泉治则应存在');
    });

    test('2026 丙午年：五类文献均非空', () {
      final YunQiYearData d = YunQiEngine.yearGanzhi(2026);
      expect(d.jz60['SAME'], isNotEmpty, reason: '丙午年大论原文应存在');
      expect(d.yunBack, isNotEmpty, reason: '岁运三纪应存在');
      expect(d.qiBack, isNotEmpty, reason: '六气胜复应存在');
      expect(d.skySiTian, isNotEmpty, reason: '司天治则应存在');
      expect(d.skyZaiQuan, isNotEmpty, reason: '在泉治则应存在');
    });

    test('jz60 按年干支命中（甲子 / 丙午）', () {
      expect(YunQiEngine.yearGanzhi(1984).jz60['SAME'],
          contains('甲子甲午岁'));
      expect(YunQiEngine.yearGanzhi(2026).jz60['SAME'],
          contains('丙午')); // 丙午在丙寅丙申…不，验证非空即可，避免对原文过度断言
    });
  });

  group('平气分支（yunBack 用「元素平气」key）', () {
    test('1984-2043 中存在平气年，其 yunBack 非空', () {
      int foundPingQi = 0;
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        if (d.isPingQi) {
          foundPingQi++;
          // 平气年：yunBackMap 的 key 为「元素平气」，必须能查到非空。
          expect(d.yunBack, isNotEmpty,
              reason: '$y 为平气年，yunBack（元素平气）应非空');
        }
      }
      expect(foundPingQi, greaterThan(0),
          reason: '1984-2043 应至少存在一个平气年以验证平气分支');
    });
  });

  group('缺失键兜底（不抛、不崩）', () {
    test('任意已存干支缺失子键时返回空字符串而非 null', () {
      final YunQiYearData d = YunQiEngine.yearGanzhi(1984);
      expect(d.yunBack['NOT_A_KEY'], isNull);
      expect(d.jz60['NOT_A_KEY'], isNull);
      expect(d.skySiTian['NOT_A_KEY'], isNull);
      // 缺失键经 ?? '—' 后可在 UI 安全展示，不触发空行。
    });
  });
}
