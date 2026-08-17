import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/minggua_engine.dart';

void main() {
  group('先天/后天卦计算（经原文示例校准）', () {
    test('原文示例：甲子 丁卯 庚申 庚辰 阳男 → 先天 天风姤', () {
      final r = MingGuaEngine.compute(
        yearGan: '甲', yearZhi: '子',
        monthGan: '丁', monthZhi: '卯',
        dayGan: '庚', dayZhi: '申',
        timeGan: '庚', timeZhi: '辰',
        male: true,
      );
      expect(r, isNotNull);
      expect(r!.yangNumber, 31);
      expect(r.yinNumber, 34);
      expect(r.upperNumber, 6); // 31−25
      expect(r.lowerNumber, 4); // 34−30
      expect(r.xianTian.name, '天风姤'); // 上乾下巽
      expect(r.xianTian.seq, 44);
      expect(r.houTian.name, '风天小畜'); // 天旋地转 → 上下互换
      expect(r.houTian.seq, 9);
      expect(r.baziFull, '甲子 丁卯 庚申 庚辰');
    });

    test('同八字 阳女 → 先天 风天小畜（地数在上）', () {
      final r = MingGuaEngine.compute(
        yearGan: '甲', yearZhi: '子',
        monthGan: '丁', monthZhi: '卯',
        dayGan: '庚', dayZhi: '申',
        timeGan: '庚', timeZhi: '辰',
        male: false,
      );
      expect(r, isNotNull);
      expect(r!.xianTian.name, '风天小畜');
      expect(r.houTian.name, '天风姤');
    });

    test('乙年 阴男：乙丑 戊寅 庚申 庚辰 → 巽为风', () {
      final r = MingGuaEngine.compute(
        yearGan: '乙', yearZhi: '丑',
        monthGan: '戊', monthZhi: '寅',
        dayGan: '庚', dayZhi: '申',
        timeGan: '庚', timeZhi: '辰',
        male: true,
      );
      expect(r, isNotNull);
      expect(r!.yangNumber, 29);
      expect(r.yinNumber, 34);
      expect(r.xianTian.name, '巽为风');
      expect(r.houTian.name, '巽为风');
    });

    test('非法干支 → null', () {
      final r = MingGuaEngine.compute(
        yearGan: 'X', yearZhi: '子',
        monthGan: '丁', monthZhi: '卯',
        dayGan: '庚', dayZhi: '申',
        timeGan: '庚', timeZhi: '辰',
        male: true,
      );
      expect(r, isNull);
    });

    test('「遇10不用」折叠：阳数11→1坎、阴数44→14→4巽 → 风水涣', () {
      final r = MingGuaEngine.compute(
        yearGan: '乙', yearZhi: '丑',
        monthGan: '戊', monthZhi: '寅',
        dayGan: '甲', dayZhi: '子',
        timeGan: '甲', timeZhi: '子',
        male: true,
      );
      expect(r, isNotNull);
      expect(r!.yangNumber, 11);
      expect(r.yinNumber, 44);
      expect(r.upperNumber, 1); // collapse(11)=1 坎
      expect(r.lowerNumber, 4); // 44−30=14 → collapse=4 巽
      // 乙年阴干男 → 地数在上 → 上巽下坎 = 风水涣
      expect(r.xianTian.name, '风水涣');
      expect(r.houTian.name, '水风井'); // 上下互换
    });

    test('阳数恰为 25 → 卦数 0 无效 → null（fail-safe 不臆造）', () {
      // 庚辰 甲申 丙午 癸巳：阳数=25 → 25−25=0 → 无法成卦
      final r = MingGuaEngine.compute(
        yearGan: '庚', yearZhi: '辰',
        monthGan: '甲', monthZhi: '申',
        dayGan: '丙', dayZhi: '午',
        timeGan: '癸', timeZhi: '巳',
        male: true,
      );
      expect(r, isNull);
    });
  });
}
