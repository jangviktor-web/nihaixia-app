/// 《人纪·针灸》阅读库索引（由 tool/import_renji_zhenjiu.py 生成，勿手改）。
/// 篇文件 assets/zhenjiu_lecture/NN_标题.md。
library;

import 'classic_lecture_data.dart';

class ZhenJiuLecture implements LectureIndex {
  @override
  final int seq;
  @override
  final String name;
  @override
  final String asset;

  const ZhenJiuLecture({
    required this.seq,
    required this.name,
    required this.asset,
  });
}

const List<ZhenJiuLecture> kZhenJiuLectures = [
  ZhenJiuLecture(seq: 0, name: '第一章·针灸的使用时机', asset: 'assets/zhenjiu_lecture/00_第一章针灸的使用时机.md'),
  ZhenJiuLecture(seq: 1, name: '第一章·针灸的急救法', asset: 'assets/zhenjiu_lecture/01_第一章针灸的急救法.md'),
  ZhenJiuLecture(seq: 2, name: '第一章·火罐的使用时机', asset: 'assets/zhenjiu_lecture/02_第一章火罐的使用时机.md'),
  ZhenJiuLecture(seq: 3, name: '第一章·火罐的使用', asset: 'assets/zhenjiu_lecture/03_第一章火罐的使用.md'),
  ZhenJiuLecture(seq: 4, name: '第二章·针刺的深浅讨论', asset: 'assets/zhenjiu_lecture/04_第二章针刺的深浅讨论.md'),
  ZhenJiuLecture(seq: 5, name: '第二章·一般针刺入穴方法', asset: 'assets/zhenjiu_lecture/05_第二章一般针刺入穴方法.md'),
  ZhenJiuLecture(seq: 6, name: '第二章·成人与幼儿的不同入穴方式', asset: 'assets/zhenjiu_lecture/06_第二章成人与幼儿的不同入穴方式.md'),
  ZhenJiuLecture(seq: 7, name: '第二章·现代常用的针号概念', asset: 'assets/zhenjiu_lecture/07_第二章现代常用的针号概念.md'),
  ZhenJiuLecture(seq: 8, name: '第二章·黄帝时代九针①型式', asset: 'assets/zhenjiu_lecture/08_第二章黄帝时代九针①型式.md'),
  ZhenJiuLecture(seq: 9, name: '第三章·十二经纳天干歌', asset: 'assets/zhenjiu_lecture/09_第三章十二经纳天干歌.md'),
  ZhenJiuLecture(seq: 10, name: '第三章·十二经纳地支歌', asset: 'assets/zhenjiu_lecture/10_第三章十二经纳地支歌.md'),
  ZhenJiuLecture(seq: 11, name: '第三章·十二正经之井荣俞原经合穴', asset: 'assets/zhenjiu_lecture/11_第三章十二正经之井荣俞原经合穴.md'),
  ZhenJiuLecture(seq: 12, name: '第三章·病在脏取井穴①', asset: 'assets/zhenjiu_lecture/12_第三章病在脏取井穴①.md'),
  ZhenJiuLecture(seq: 13, name: '第三章·病变于色取荣穴①', asset: 'assets/zhenjiu_lecture/13_第三章病变于色取荣穴①.md'),
  ZhenJiuLecture(seq: 14, name: '第三章·病在时间者取俞穴②', asset: 'assets/zhenjiu_lecture/14_第三章病在时间者取俞穴②.md'),
  ZhenJiuLecture(seq: 15, name: '第三章·病变于音者取经穴④', asset: 'assets/zhenjiu_lecture/15_第三章病变于音者取经穴④.md'),
  ZhenJiuLecture(seq: 16, name: '第三章·病起于饮食取合穴⑤', asset: 'assets/zhenjiu_lecture/16_第三章病起于饮食取合穴⑤.md'),
  ZhenJiuLecture(seq: 17, name: '第三章·五脏不平衡时用原穴①', asset: 'assets/zhenjiu_lecture/17_第三章五脏不平衡时用原穴①.md'),
  ZhenJiuLecture(seq: 18, name: '第三章·与四季的关系', asset: 'assets/zhenjiu_lecture/18_第三章与四季的关系.md'),
  ZhenJiuLecture(seq: 19, name: '第三章·五行', asset: 'assets/zhenjiu_lecture/19_第三章五行.md'),
  ZhenJiuLecture(seq: 20, name: '第四章·任脉与督脉', asset: 'assets/zhenjiu_lecture/20_第四章任脉与督脉.md'),
  ZhenJiuLecture(seq: 21, name: '第四章·任脉经穴', asset: 'assets/zhenjiu_lecture/21_第四章任脉经穴.md'),
  ZhenJiuLecture(seq: 22, name: '第四章·督脉经穴篇', asset: 'assets/zhenjiu_lecture/22_第四章督脉经穴篇.md'),
  ZhenJiuLecture(seq: 23, name: '第四章·手太阴肺经', asset: 'assets/zhenjiu_lecture/23_第四章手太阴肺经.md'),
  ZhenJiuLecture(seq: 24, name: '第四章·手阳明大肠经', asset: 'assets/zhenjiu_lecture/24_第四章手阳明大肠经.md'),
  ZhenJiuLecture(seq: 25, name: '第四章·足阳明胃经', asset: 'assets/zhenjiu_lecture/25_第四章足阳明胃经.md'),
  ZhenJiuLecture(seq: 26, name: '第四章·足太阴脾经', asset: 'assets/zhenjiu_lecture/26_第四章足太阴脾经.md'),
  ZhenJiuLecture(seq: 27, name: '第四章·手少阴心经', asset: 'assets/zhenjiu_lecture/27_第四章手少阴心经.md'),
  ZhenJiuLecture(seq: 28, name: '第四章·手太阳小肠经', asset: 'assets/zhenjiu_lecture/28_第四章手太阳小肠经.md'),
  ZhenJiuLecture(seq: 29, name: '第四章·足太阳膀胱经', asset: 'assets/zhenjiu_lecture/29_第四章足太阳膀胱经.md'),
  ZhenJiuLecture(seq: 30, name: '第四章·足少阴肾经', asset: 'assets/zhenjiu_lecture/30_第四章足少阴肾经.md'),
  ZhenJiuLecture(seq: 31, name: '第四章·手厥阴心包经', asset: 'assets/zhenjiu_lecture/31_第四章手厥阴心包经.md'),
  ZhenJiuLecture(seq: 32, name: '第四章·手少阳三焦经', asset: 'assets/zhenjiu_lecture/32_第四章手少阳三焦经.md'),
  ZhenJiuLecture(seq: 33, name: '第四章·足少阳胆经', asset: 'assets/zhenjiu_lecture/33_第四章足少阳胆经.md'),
  ZhenJiuLecture(seq: 34, name: '第四章·足厥阴肝经', asset: 'assets/zhenjiu_lecture/34_第四章足厥阴肝经.md'),
  ZhenJiuLecture(seq: 35, name: '第六章·梅花针（治皮肤病麻痹症）', asset: 'assets/zhenjiu_lecture/35_第六章梅花针治皮肤病麻痹症.md'),
  ZhenJiuLecture(seq: 36, name: '第六章·头部与脑瘤治症', asset: 'assets/zhenjiu_lecture/36_第六章头部与脑瘤治症.md'),
  ZhenJiuLecture(seq: 37, name: '第六章·治眼证及睛中法', asset: 'assets/zhenjiu_lecture/37_第六章治眼证及睛中法.md'),
  ZhenJiuLecture(seq: 38, name: '第六章·治鼻病： 鼻息肉鼻炎', asset: 'assets/zhenjiu_lecture/38_第六章治鼻病：鼻息肉鼻炎.md'),
  ZhenJiuLecture(seq: 39, name: '第六章·治耳症： 耳鸣化脓', asset: 'assets/zhenjiu_lecture/39_第六章治耳症：耳鸣化脓.md'),
  ZhenJiuLecture(seq: 40, name: '第六章·面部中风与起因', asset: 'assets/zhenjiu_lecture/40_第六章面部中风与起因.md'),
  ZhenJiuLecture(seq: 41, name: '第六章·治舌症与扁桃腺炎', asset: 'assets/zhenjiu_lecture/41_第六章治舌症与扁桃腺炎.md'),
  ZhenJiuLecture(seq: 42, name: '第六章·瘿瘤（甲状腺治症）', asset: 'assets/zhenjiu_lecture/42_第六章瘿瘤甲状腺治症.md'),
  ZhenJiuLecture(seq: 43, name: '第六章·内伤。五脏气乱与癫痫', asset: 'assets/zhenjiu_lecture/43_第六章内伤五脏气乱与癫痫.md'),
  ZhenJiuLecture(seq: 44, name: '第六章·肺积水与胸肋积水', asset: 'assets/zhenjiu_lecture/44_第六章肺积水与胸肋积水.md'),
  ZhenJiuLecture(seq: 45, name: '第六章·心脏肥大。胸痛与心律不整', asset: 'assets/zhenjiu_lecture/45_第六章心脏肥大胸痛与心律不整.md'),
  ZhenJiuLecture(seq: 46, name: '第六章·乳癌初期与中期肿块治疗', asset: 'assets/zhenjiu_lecture/46_第六章乳癌初期与中期肿块治疗.md'),
  ZhenJiuLecture(seq: 47, name: '第六章·肺积水乳癌末期灸法治疗', asset: 'assets/zhenjiu_lecture/47_第六章肺积水乳癌末期灸法治疗.md'),
  ZhenJiuLecture(seq: 48, name: '第六章·胆结石与肝病治症', asset: 'assets/zhenjiu_lecture/48_第六章胆结石与肝病治症.md'),
  ZhenJiuLecture(seq: 49, name: '第六章·针灸疗程与针后禁忌', asset: 'assets/zhenjiu_lecture/49_第六章针灸疗程与针后禁忌.md'),
  ZhenJiuLecture(seq: 50, name: '第六章·脾肿大与胃病治疗', asset: 'assets/zhenjiu_lecture/50_第六章脾肿大与胃病治疗.md'),
  ZhenJiuLecture(seq: 51, name: '第六章·血症（内出血与外伤出血）', asset: 'assets/zhenjiu_lecture/51_第六章血症内出血与外伤出血.md'),
  ZhenJiuLecture(seq: 52, name: '第六章·朝食暮吐与腹膜炎', asset: 'assets/zhenjiu_lecture/52_第六章朝食暮吐与腹膜炎.md'),
  ZhenJiuLecture(seq: 53, name: '第六章·消渴。痞块与肝结石治症', asset: 'assets/zhenjiu_lecture/53_第六章消渴痞块与肝结石治症.md'),
  ZhenJiuLecture(seq: 54, name: '第六章·腹痛。瘀血与便秘', asset: 'assets/zhenjiu_lecture/54_第六章腹痛瘀血与便秘.md'),
  ZhenJiuLecture(seq: 55, name: '第六章·盲肠炎与奔豚症', asset: 'assets/zhenjiu_lecture/55_第六章盲肠炎与奔豚症.md'),
  ZhenJiuLecture(seq: 56, name: '第六章·血痢。痔疮。肠漏与大肠癌', asset: 'assets/zhenjiu_lecture/56_第六章血痢痔疮肠漏与大肠癌.md'),
  ZhenJiuLecture(seq: 57, name: '第六章·月经寒实症。助孕与绝孕', asset: 'assets/zhenjiu_lecture/57_第六章月经寒实症助孕与绝孕.md'),
  ZhenJiuLecture(seq: 58, name: '第六章·痛经。赤白带与子宫卵巢肿瘤', asset: 'assets/zhenjiu_lecture/58_第六章痛经赤白带与子宫卵巢肿瘤.md'),
  ZhenJiuLecture(seq: 59, name: '第六章·怀孕忌针。安胎堕胎与胎位不正', asset: 'assets/zhenjiu_lecture/59_第六章怀孕忌针安胎堕胎与胎位不正.md'),
  ZhenJiuLecture(seq: 60, name: '第六章·灵龟八法', asset: 'assets/zhenjiu_lecture/60_第六章灵龟八法.md'),
  ZhenJiuLecture(seq: 61, name: '第六章·灵龟八法与子午流注', asset: 'assets/zhenjiu_lecture/61_第六章灵龟八法与子午流注.md'),
  ZhenJiuLecture(seq: 62, name: '第六章·奇穴： 大椎外五分定喘穴', asset: 'assets/zhenjiu_lecture/62_第六章奇穴：大椎外五分定喘穴.md'),
  ZhenJiuLecture(seq: 63, name: '第六章·耳针治疗： 醒酒。肾结石。心脏。消炎', asset: 'assets/zhenjiu_lecture/63_第六章耳针治疗：醒酒肾结石心脏消炎.md'),
  ZhenJiuLecture(seq: 64, name: '第六章·回阳九针', asset: 'assets/zhenjiu_lecture/64_第六章回阳九针.md'),
  ZhenJiuLecture(seq: 65, name: '第六章·十三鬼穴： 癫痫发狂奔走中邪', asset: 'assets/zhenjiu_lecture/65_第六章十三鬼穴：癫痫发狂奔走中邪.md'),
  ZhenJiuLecture(seq: 66, name: '第六章·疾病疑问解答（略）', asset: 'assets/zhenjiu_lecture/66_第六章疾病疑问解答略.md'),
  ZhenJiuLecture(seq: 67, name: '第六章·骨质疏松症谈维他命日夜颠倒者与发秃', asset: 'assets/zhenjiu_lecture/67_第六章骨质疏松症谈维他命日夜颠倒者与发秃.md'),
  ZhenJiuLecture(seq: 68, name: '第六章·委中放血与关节脱臼', asset: 'assets/zhenjiu_lecture/69_第六章委中放血与关节脱臼.md'),
  ZhenJiuLecture(seq: 69, name: '第六章·脉气走向，痛点之对称治疗', asset: 'assets/zhenjiu_lecture/71_第六章脉气走向痛点之对称治疗.md'),
  ZhenJiuLecture(seq: 70, name: '第六章·飞针引气与针之深浅力道', asset: 'assets/zhenjiu_lecture/85_第六章飞针引气与针之深浅力道.md'),
  ZhenJiuLecture(seq: 71, name: '第六章·标本赋', asset: 'assets/zhenjiu_lecture/86_第六章标本赋.md'),
];
