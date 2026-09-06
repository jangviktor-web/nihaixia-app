// 输出项目引擎的排盘基准（用于与网络排盘网站对账）。
// 运行：/d/flutter/bin/dart run tool/bazi_dump.dart
import 'package:bazi_core/bazi_core.dart';

import 'package:nihaisha_app/services/bazi_service.dart';

final cases = [
  (DateTime(1995, 8, 16, 12, 0), true, '1995-08-16 12:00 男'),
  (DateTime(2000, 1, 1, 23, 30), true, '2000-01-01 23:30 男（晚子时边界）'),
  (DateTime(1984, 6, 15, 12, 0), true, '1984-06-15 12:00 男'),
];

void main() {
  for (final (t, isMale, label) in cases) {
    final noTst = computeBaZiPaipan(t, isMale: isMale, useTrueSolarTime: false);
    final withTst = computeBaZiPaipan(t, isMale: isMale, useTrueSolarTime: true);
    final f = computeBaZiFortune(t, isMale: isMale);
    print('== $label ==');
    print('  钟表排盘（无真太阳时）：${noTst.bazi.year} ${noTst.bazi.month} ${noTst.bazi.day} ${noTst.bazi.time}');
    print('  真太阳时(默认120E)　　：${withTst.bazi.year} ${withTst.bazi.month} ${withTst.bazi.day} ${withTst.bazi.time}');
    print('  十神：${noTst.tenGods.join(" ")}  旬空：${noTst.kongWang.join("、")}');
    print('  起运：${f.startAge.toStringAsFixed(1)}岁 @${f.qiYunTime.year}-${f.qiYunTime.month}-${f.qiYunTime.day}');
    print('  大运：${f.decades.map((d) => d.ganZhi).join(" ")}');
  }
}
