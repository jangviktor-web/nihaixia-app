// 最小 golden 测试：四柱必须来自 bazi_core 官方算法。
//
// 用例：2026-02-18 12:00。
// 注：bazi_core 实际输出为「丙午 庚寅 癸亥 戊午」（日柱为癸亥）。
// 其 README 示例写的「癸酉」是 README 自身的笔误；按甲子基准日(2000-01-01=戊午)
// 用 JDN 推算 2026-02-18 距 2000-01-01 共 9545 天 → 日柱 (54+5)%60 = 59 = 癸亥，
// 与 bazi_core 运行结果一致、且独立于本库，可作为权威交叉验证。
// 该用例固定八字排盘模块的四柱口径（年柱按立春、日柱用权威基准日、
// 子时归属按 ratHourMode noSplit），防止回归到旧 ZiweiDate.bazi 路径。
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/services/bazi_service.dart';

void main() {
  test('2026-02-18 12:00 四柱应为 丙午 庚寅 癸亥 戊午（bazi_core 口径）', () {
    final r = computeBaZiPaipan(
      DateTime(2026, 2, 18, 12, 0),
      isMale: true,
      useTrueSolarTime: true,
      earlyZiShi: false,
      location: null,
    );

    // 天干 / 地支逐位
    expect(r.gans, equals(['丙', '庚', '癸', '戊']));
    expect(r.zhis, equals(['午', '寅', '亥', '午']));

    // 四柱拼接（bazi_core 运行结果）
    expect(
      '${r.bazi.year} ${r.bazi.month} ${r.bazi.day} ${r.bazi.time}',
      equals('丙午 庚寅 癸亥 戊午'),
    );

    // 胎元 / 胎息按 bazi_core 同源四柱派生（月柱庚寅→辛巳；日柱癸亥→戊寅）
    expect(r.taiYuan, equals('辛巳'));
    expect(r.taiXi, equals('戊寅'));
  });

  test('晚子时(noSplit)：2000-01-01 23:30 → 日柱己未 时柱甲子', () {
    final r = computeBaZiPaipan(
      DateTime(2000, 1, 1, 23, 30),
      isMale: true,
      useTrueSolarTime: true,
      earlyZiShi: false,
      location: null,
    );
    expect(r.bazi.day, '己未');
    expect(r.bazi.time, '甲子');
  });

  test('早子时(todayGan)：2000-01-01 23:30 → 日柱戊午 时柱壬子', () {
    final r = computeBaZiPaipan(
      DateTime(2000, 1, 1, 23, 30),
      isMale: true,
      useTrueSolarTime: true,
      earlyZiShi: true,
      location: null,
    );
    expect(r.bazi.day, '戊午');
    expect(r.bazi.time, '壬子');
  });
}
