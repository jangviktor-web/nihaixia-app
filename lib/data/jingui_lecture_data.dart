/// 《人纪·金匮要略》书面整理版讲稿索引（由 tool/import_renji_jingui.py 生成，勿手改）。
/// 篇文件 assets/jingui_lecture/NNN_篇名.md。与 assets/jingui/ 条文卡并列：
/// 条文卡=逐条速查（「见于经典」依赖），本库=书面版系统通读。
library;

import 'classic_lecture_data.dart';

class JinGuiBookLecture implements LectureIndex {
  @override
  final int seq;
  @override
  final String name;
  @override
  final String asset;

  const JinGuiBookLecture({
    required this.seq,
    required this.name,
    required this.asset,
  });
}

const List<JinGuiBookLecture>kJinGuiBookLectures = [
  JinGuiBookLecture(seq: 0, name: '总论·倪海厦传记', asset: 'assets/jingui_lecture/000_总论·倪海厦传记.md'),
  JinGuiBookLecture(seq: 1, name: '脏腑经络先后病脉证第一', asset: 'assets/jingui_lecture/001_脏腑经络先后病脉证第一.md'),
  JinGuiBookLecture(seq: 2, name: '痉湿暍病脉证治法第二·上', asset: 'assets/jingui_lecture/002_痉湿暍病脉证治法第二·上.md'),
  JinGuiBookLecture(seq: 3, name: '痉湿暍病脉证治法第二·下', asset: 'assets/jingui_lecture/003_痉湿暍病脉证治法第二·下.md'),
  JinGuiBookLecture(seq: 4, name: '百合狐惑阴阳毒病脉证治第三', asset: 'assets/jingui_lecture/004_百合狐惑阴阳毒病脉证治第三.md'),
  JinGuiBookLecture(seq: 5, name: '疟病脉证并治第四', asset: 'assets/jingui_lecture/005_疟病脉证并治第四.md'),
  JinGuiBookLecture(seq: 6, name: '中风历节病脉证并治第五', asset: 'assets/jingui_lecture/006_中风历节病脉证并治第五.md'),
  JinGuiBookLecture(seq: 7, name: '血痹虚劳病脉证并治第六', asset: 'assets/jingui_lecture/007_血痹虚劳病脉证并治第六.md'),
  JinGuiBookLecture(seq: 8, name: '肺痿肺痈咳嗽上气病脉证治第七', asset: 'assets/jingui_lecture/008_肺痿肺痈咳嗽上气病脉证治第七.md'),
  JinGuiBookLecture(seq: 9, name: '奔豚气病脉证并治第八', asset: 'assets/jingui_lecture/009_奔豚气病脉证并治第八.md'),
  JinGuiBookLecture(seq: 10, name: '胸痹心痛短气病脉证并治第九', asset: 'assets/jingui_lecture/010_胸痹心痛短气病脉证并治第九.md'),
  JinGuiBookLecture(seq: 11, name: '腹满寒疝宿食病脉证并治第十', asset: 'assets/jingui_lecture/011_腹满寒疝宿食病脉证并治第十.md'),
  JinGuiBookLecture(seq: 12, name: '五藏风寒积聚病脉证并治第十一', asset: 'assets/jingui_lecture/012_五藏风寒积聚病脉证并治第十一.md'),
  JinGuiBookLecture(seq: 13, name: '痰饮咳嗽病脉证并治第十二·上', asset: 'assets/jingui_lecture/013_痰饮咳嗽病脉证并治第十二·上.md'),
  JinGuiBookLecture(seq: 14, name: '痰饮咳嗽病脉证并治第十二·下', asset: 'assets/jingui_lecture/014_痰饮咳嗽病脉证并治第十二·下.md'),
  JinGuiBookLecture(seq: 15, name: '消渴小便不利淋病脉证并治第十三', asset: 'assets/jingui_lecture/015_消渴小便不利淋病脉证并治第十三.md'),
  JinGuiBookLecture(seq: 16, name: '水气病脉证并治第十四·上', asset: 'assets/jingui_lecture/016_水气病脉证并治第十四·上.md'),
  JinGuiBookLecture(seq: 17, name: '水气病脉证并治第十四·下', asset: 'assets/jingui_lecture/017_水气病脉证并治第十四·下.md'),
  JinGuiBookLecture(seq: 18, name: '黄疸病脉证并治第十五', asset: 'assets/jingui_lecture/018_黄疸病脉证并治第十五.md'),
  JinGuiBookLecture(seq: 19, name: '惊悸吐衄下血胸满瘀血病脉证治第十六', asset: 'assets/jingui_lecture/019_惊悸吐衄下血胸满瘀血病脉证治第十六.md'),
  JinGuiBookLecture(seq: 20, name: '呕吐哕下利病脉证治第十七·上', asset: 'assets/jingui_lecture/020_呕吐哕下利病脉证治第十七·上.md'),
  JinGuiBookLecture(seq: 21, name: '呕吐哕下利病脉证治第十七·下', asset: 'assets/jingui_lecture/021_呕吐哕下利病脉证治第十七·下.md'),
  JinGuiBookLecture(seq: 22, name: '疮痈肠痈浸淫病脉证并治第十八', asset: 'assets/jingui_lecture/022_疮痈肠痈浸淫病脉证并治第十八.md'),
  JinGuiBookLecture(seq: 23, name: '趺蹶手指臂肿转筋阴狐疝蚘虫病脉证治第十九', asset: 'assets/jingui_lecture/023_趺蹶手指臂肿转筋阴狐疝蚘虫病脉证治第十九.md'),
  JinGuiBookLecture(seq: 24, name: '妇人妊娠病脉证并治第二十', asset: 'assets/jingui_lecture/024_妇人妊娠病脉证并治第二十.md'),
  JinGuiBookLecture(seq: 25, name: '妇人产后病脉证治第二十一', asset: 'assets/jingui_lecture/025_妇人产后病脉证治第二十一.md'),
  JinGuiBookLecture(seq: 26, name: '妇人杂病脉证治第二十二（一）', asset: 'assets/jingui_lecture/026_妇人杂病脉证治第二十二（一）.md'),
  JinGuiBookLecture(seq: 27, name: '妇人杂病脉证治第二十二（二）', asset: 'assets/jingui_lecture/027_妇人杂病脉证治第二十二（二）.md'),
  JinGuiBookLecture(seq: 28, name: '妇人杂病脉证治第二十二（三）', asset: 'assets/jingui_lecture/028_妇人杂病脉证治第二十二（三）.md'),
  JinGuiBookLecture(seq: 29, name: '妇人杂病脉证治第二十二（四）', asset: 'assets/jingui_lecture/029_妇人杂病脉证治第二十二（四）.md'),
];
