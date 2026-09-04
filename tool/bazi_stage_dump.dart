// case A 十二神两口径 + 大运详情。
import 'package:bazi_core/bazi_core.dart';
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart';
import 'package:nihaisha_app/services/bazi_service.dart';

void main() {
  const gans = ['乙', '甲', '己', '庚'];
  const zhis = ['亥', '申', '卯', '午'];
  final fire = twelveStagesForPillars(gans[2], zhis, mode: TwelveStageMode.fireEarthSame);
  final water = twelveStagesForPillars(gans[2], zhis, mode: TwelveStageMode.waterEarthSame);
  print('火土同宫：' + [for (var i = 0; i < 4; i++) '${zhis[i]}=${fire[i]}'].join(' '));
  print('水土同宫：' + [for (var i = 0; i < 4; i++) '${zhis[i]}=${water[i]}'].join(' '));
  final f = computeBaZiFortune(DateTime(1995, 8, 16, 12, 0), isMale: true);
  print('起运 ${f.startAge} 岁，交运 ${f.qiYunTime}');
  for (final d in f.decades) {
    print('  第${d.index}运 ${d.ganZhi} ${d.startAge}-${d.endAge}岁');
  }
}
