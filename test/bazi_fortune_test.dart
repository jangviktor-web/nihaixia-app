// 批次 A-②：computeBaZiFortune 编排层测试（映射正确性，不重复引擎断言）。
// 引擎本身的行为（四柱一致/顺逆方向）由 bazi_core_crosscheck_test 覆盖。
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/services/bazi_service.dart';

void main() {
  final r = computeBaZiFortune(
    DateTime(1995, 8, 16, 12, 0),
    isMale: true, // 乙亥阴年男 → 逆排
  );

  test('8 步大运，每步含 10 流年', () {
    expect(r.decades.length, 8);
    for (final d in r.decades) {
      expect(d.years.length, 10, reason: '第${d.index}步大运应辖 10 流年');
      expect(d.endAge - d.startAge, 9, reason: '每步大运跨 10 虚岁');
    }
  });

  test('乙亥阴年男首运 = 癸未（逆排），流年从 1998 戊寅起', () {
    final d1 = r.decades.first;
    expect(d1.ganZhi, '癸未');
    expect(d1.years.first.year, 1998);
    expect(d1.years.first.ganZhi, '戊寅');
    // 逆排第二步：癸未 - 1 → 壬午
    expect(r.decades[1].ganZhi, '壬午');
  });

  test('起运虚岁与交运时间合理（2~3 岁起运、1998 年前后交运）', () {
    expect(r.startAge, greaterThan(1));
    expect(r.startAge, lessThan(10));
    expect(r.qiYunTime.year, inInclusiveRange(1997, 1999));
  });

  test('性别翻转 → 顺排（乙亥女首运 = 乙酉）', () {
    final f = computeBaZiFortune(
      DateTime(1995, 8, 16, 12, 0),
      isMale: false,
    );
    expect(f.decades.first.ganZhi, '乙酉');
    // 顺排第二步：乙酉 + 1 → 丙戌
    expect(f.decades[1].ganZhi, '丙戌');
  });
}
