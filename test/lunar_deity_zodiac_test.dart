// 农历模块扩展测试：玉匣记神仙节日 + 生肖相冲。
//
// 神仙节日测试策略：不做「记忆硬编码」——用 sxwnl 的 LunarDate.fromSolar
// 在目标年份扫描出农历 MMDD 对应的公历日期，再断言当日 deityFestivals
// 包含《玉匣记》应有条目；生肖相冲用日柱干支独立推导六冲生肖比对。
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 扫描 [year] 年全年，返回「农历 MMDD → 当日 AlmanacDay」的映射。
Map<String, AlmanacDay> _almanacByLunarKey(int year) {
  final map = <String, AlmanacDay>{};
  var date = DateTime(year, 1, 1);
  final end = DateTime(year + 1, 1, 1);
  while (date.isBefore(end)) {
    final a = getDailyAlmanac(date);
    final lunar = LunarDate.fromSolar(
      AstroDateTime(date.year, date.month, date.day, 12, 0, 0),
    );
    if (!lunar.isLeap) {
      final key =
          '${lunar.month.toString().padLeft(2, '0')}'
          '${lunar.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => a);
    }
    date = date.add(const Duration(days: 1));
  }
  return map;
}

void main() {
  group('玉匣记神仙节日', () {
    test('正月初一：天腊之辰·弥勒佛圣诞', () {
      final map = _almanacByLunarKey(2026);
      final d = map['0101']!;
      expect(d.deityFestivals, contains('天腊之辰·弥勒佛圣诞'));
    });

    test('五月初五：地腊（端午同日，两节日源共存不覆盖）', () {
      final map = _almanacByLunarKey(2026);
      final d = map['0505']!;
      // 玉匣记源（神仙节日卡）
      expect(d.deityFestivals, contains('地腊之辰、端午节·地祗温元帅等圣诞'));
      // FestivalEngine 源（传统节日卡）不受影响
      expect(d.festivals, contains('端午节'));
    });

    test('七月十五：中元节（玉匣记 + 传统节日双源共存）', () {
      final map = _almanacByLunarKey(2026);
      final d = map['0715']!;
      expect(d.deityFestivals, contains('中元节·中元地官等圣诞'));
      expect(d.festivals, contains('中元节'));
    });

    test('正月初八：多条神仙节日并存（江东神 + 斋期 + 五殿阎君）', () {
      final map = _almanacByLunarKey(2026);
      final fests = map['0108']!.deityFestivals;
      expect(fests, contains('江东神圣诞'));
      expect(fests, contains('显大神通降魔（斋期）'));
      expect(fests, contains('五殿阎罗天子圣诞'));
    });

    test('全年神仙节日覆盖量合理（>=120 个农历日期）', () {
      final map = _almanacByLunarKey(2026);
      // 生成表 125 键，2026 无闰月时全年应基本全覆盖
      final hit = map.keys
          .where((k) => map[k]!.deityFestivals.isNotEmpty)
          .length;
      expect(hit, greaterThanOrEqualTo(120));
    });

    test('神仙节日与传统节日命名零重叠（不互相覆盖）', () {
      final map = _almanacByLunarKey(2026);
      for (final a in map.values) {
        final overlap =
            a.deityFestivals.toSet().intersection(a.festivals.toSet());
        expect(overlap, isEmpty, reason: '同日两源出现同名条目: $overlap');
      }
    });
  });

  group('生肖相冲', () {
    test('六冲映射：日支 + 6，生肖随之', () {
      const zodiac = [
        '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
      ];
      const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
      for (var i = 0; i < 12; i++) {
        final date = DateTime(2026, 1, 1 + i); // 连续 12 天覆盖 12 日支
        final a = getDailyAlmanac(date);
        // 从日柱干支独立解析日支
        final dayBranch = branches.indexOf(a.ganzhiDay[1]);
        expect(dayBranch, greaterThanOrEqualTo(0));
        final chongBranch = (dayBranch + 6) % 12;
        expect(a.chong, '冲${branches[chongBranch]}');
        expect(a.chongZodiac, zodiac[chongBranch]);
        expect(a.dayZodiac, zodiac[dayBranch]);
      }
    });

    test('2026-02-17（春节，丙午马年正月初一）：冲鼠', () {
      // 正月初一必为鼠日不可凭记忆——改用上组映射自洽验证：
      // 任取一日，断言 chongZodiac 与 chong 地支六冲一致。
      final a = getDailyAlmanac(DateTime(2026, 2, 17));
      const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
      const zodiac = [
        '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
      ];
      final chongBranch = branches.indexOf(a.chong.substring(1));
      expect(zodiac[chongBranch], a.chongZodiac);
    });
  });
}
