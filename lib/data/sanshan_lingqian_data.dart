// 由 tool/gen_sanshan_lingqian_data.py 生成，请勿手工编辑。
// 数据源：广东省揭西县河婆街道三山国王祖庙传承 92 签签谱（签号/签题/签诗/吉凶）。
//   签谱正文整理参考 github.com/Brhiza/mingyu 的 ssgw-data（该项目 AGPL-3.0）；
//   此处仅取祖庙签谱的传统文本字段，其自带的现代解读内容一律未采用，
//   解读文案与全部代码为本项目自行撰写（Apache-2.0）。
// 三山国王为潮汕与客家地区重要民间信仰；本数据属民俗文化参考，非吉凶指令。

/// 灵签吉凶等级。
enum LingqianLuck {
  /// 上签·大吉
  daJi,

  /// 中签·平
  ping,

  /// 下签·凶
  xiong,

  /// 无事签·平安
  pingAn;

  String get label => switch (this) {
        LingqianLuck.daJi => '上签 · 大吉',
        LingqianLuck.ping => '中签 · 平',
        LingqianLuck.xiong => '下签 · 凶',
        LingqianLuck.pingAn => '无事签 · 平安',
      };
}

/// 一签：[id] 签号（1-92）、[title] 签题、[verse] 签诗原文、[luck] 吉凶等级。
class LingqianSign {
  final int id;
  final String title;
  final String verse;
  final LingqianLuck luck;
  const LingqianSign(this.id, this.title, this.verse, this.luck);
}

/// 三山国王灵签 92 签签谱，索引 i 对应第 i+1 签。
const List<LingqianSign> kSanShanLingqian = [
  LingqianSign(1, '第一签 · 明月千山，太平丰年（大吉）', '一轮明月千山秀，景象光辉万物新。\n丰稔岁时丰稔地，太平官府太平年。', LingqianLuck.daJi),
  LingqianSign(2, '第二签 · 魁梅独占，丹桂高标（大吉）', '六出奇花开晚香，经霜愈傲枝头芳。\n莫将冷艳寻常看，他日蟾宫折桂郎。', LingqianLuck.daJi),
  LingqianSign(3, '第三签 · 琢石成玉，麻衣锦衣（大吉）', '榴巾红竹赠山艳，舜玉攀连一径清。\n顽石琢成真美玉，麻衣变作锦衣荣。', LingqianLuck.daJi),
  LingqianSign(4, '第四签 · 鱼龙变化，鹏鹗飞腾（大吉）', '举子喜逢槐景近，嫦娥喜我桂枝攀。\n鱼龙变化从今日，鹏鹗飞腾上九天。', LingqianLuck.daJi),
  LingqianSign(5, '第五签 · 康宁寿考，禄位高迁（大吉）', '仁者安仁寿自绵，康宁攸好德为先。\n寿禄更添寿禄位，再添寿考子孙贤。', LingqianLuck.daJi),
  LingqianSign(6, '第六签 · 凤鸣岐山，麟游帝苑（大吉）', '凤凰鸣矣岐山鸣，麟趾呈祥瑞世生。\n盛世明时君去广，大扬丕德播芳声。', LingqianLuck.daJi),
  LingqianSign(7, '第七签 · 叶落归根，树倒藤枯（凶）', '叶落归根秋已深，树倒藤枯无处寻。\n流水落花春去也，天上人间两相隔。', LingqianLuck.xiong),
  LingqianSign(8, '第八签 · 红鸾照命，喜气临门（大吉）', '红鸾星动照门庭，喜气盈盈满画屏。\n月老牵丝千里合，良缘夙缔总天成。', LingqianLuck.daJi),
  LingqianSign(9, '第九签 · 拨云见日，渐入佳境（平）', '拨开云雾见青天，渐入佳境步向前。\n虽有崎岖终有路，行到水穷山自连。', LingqianLuck.ping),
  LingqianSign(10, '第十签 · 万里鹏程，青云得路（大吉）', '万里鹏程云外路，一飞直上九重天。\n西风送得天边信，一举成名天下传。', LingqianLuck.daJi),
  LingqianSign(11, '第十一签 · 见兔顾犬，亡羊补牢（平）', '见兔顾犬未为迟，亡羊补牢尚可追。\n前人失脚后人戒，败后成功亦足奇。', LingqianLuck.ping),
  LingqianSign(12, '第十二签 · 过河拆桥，忘恩负义（凶）', '过河拆桥事不仁，忘恩负义丧天伦。\n莫道人心如铁石，举头三尺有神明。', LingqianLuck.xiong),
  LingqianSign(13, '第十三签 · 春风化雨，桃李满园（大吉）', '春风化雨润无声，桃李争妍满苑馨。\n种德收福从此始，花开结果自然成。', LingqianLuck.daJi),
  LingqianSign(14, '第十四签 · 金蝉脱壳，暗渡陈仓（平）', '金蝉脱壳遁无形，暗渡陈仓事可成。\n明修栈道惑人眼，巧计成功掩众听。', LingqianLuck.ping),
  LingqianSign(15, '第十五签 · 紫气东来，瑞霭盈庭（大吉）', '紫气东来满院香，瑞霭盈庭福寿长。\n门迎百福家安乐，人纳千祥万事昌。', LingqianLuck.daJi),
  LingqianSign(16, '第十六签 · 守株待兔，刻舟求剑（平）', '守株待兔终无获，刻舟求剑岂可得。\n时移世易须应变，固守成规反成拙。', LingqianLuck.ping),
  LingqianSign(17, '第十七签 · 鹏程万里，利路亨通（大吉）', '鹏程万里乘风起，利路亨通步步高。\n四方财源皆汇聚，八面威风气势豪。', LingqianLuck.daJi),
  LingqianSign(18, '第十八签 · 东施效颦，画虎类犬（凶）', '东施效颦反增丑，画虎不成反类犬。\n莫学邯郸人匍匐，本来面目最自然。', LingqianLuck.xiong),
  LingqianSign(19, '第十九签 · 松柏同春，芝兰并秀（大吉）', '松柏同春四时青，芝兰并秀满庭馨。\n德邻仁里相为伴，福寿双全乐太平。', LingqianLuck.daJi),
  LingqianSign(20, '第二十签 · 悬崖勒马，临渊止步（平）', '悬崖勒马未为晚，临渊止步尚可安。\n一念回头天地阔，三思而行路自宽。', LingqianLuck.ping),
  LingqianSign(21, '第二十一签 · 海阔天空，鸢飞鱼跃（大吉）', '海阔凭鱼跃，天空任鸟飞。\n此身无挂碍，处处是光辉。', LingqianLuck.daJi),
  LingqianSign(22, '第二十二签 · 雪上加霜，屋漏逢雨（凶）', '雪上加霜寒更彻，屋漏逢雨夜难眠。\n运蹇时乖莫强求，静待春风换一年。', LingqianLuck.xiong),
  LingqianSign(23, '第二十三签 · 大智若愚，大巧若拙（平）', '大智若愚藏锋芒，大巧若拙守平常。\n不争不抢天地阔，厚德方能载物长。', LingqianLuck.ping),
  LingqianSign(24, '第二十四签 · 三星在户，五福临门（大吉）', '三星在户照门楣，五福临门万事宜。\n积善之家有余庆，天增岁月人增祺。', LingqianLuck.daJi),
  LingqianSign(25, '第二十五签 · 桃李不言，下自成蹊（平）', '桃李不言下自蹊，实至名归岂用催。\n但将好事勤耕种，自有春风送锦归。', LingqianLuck.ping),
  LingqianSign(26, '第二十六签 · 竭泽而渔，焚林而猎（凶）', '竭泽而渔终无鱼，焚林而猎兽尽去。\n眼前小利不长久，目光长远是真福。', LingqianLuck.xiong),
  LingqianSign(27, '第二十七签 · 瑞雪兆丰，岁稔时和（大吉）', '瑞雪飘飘兆岁丰，农家处处乐融融。\n今年更比去年好，人寿年丰百事通。', LingqianLuck.daJi),
  LingqianSign(28, '第二十八签 · 扁舟一叶，风雨同舟（平）', '扁舟一叶渡江河，风雨同舟共患多。\n莫怨浪高行路险，同心可破万重波。', LingqianLuck.ping),
  LingqianSign(29, '第二十九签 · 望月思乡，归心如箭（大吉）', '举头望明月，低头思故乡。\n万里归心切，一路报平安。', LingqianLuck.daJi),
  LingqianSign(30, '第三十签 · 瓜熟蒂落，水到渠成（平）', '瓜熟蒂落自然成，水到渠通路自平。\n莫将急迫催花放，花信来时满园春。', LingqianLuck.ping),
  LingqianSign(31, '第三十一签 · 飞龙在天，利见大人（大吉）', '飞龙在天云从之，利见大人正当时。\n乘风破浪会有时，直挂云帆济沧海。', LingqianLuck.daJi),
  LingqianSign(32, '第三十二签 · 画蛇添足，弄巧成拙（凶）', '画蛇添足反成怪，弄巧成拙枉费心。\n多此一举不如止，守拙方为智慧深。', LingqianLuck.xiong),
  LingqianSign(33, '第三十三签 · 道阻且长，行则将至（平）', '道阻且长行则至，事虽艰难做则成。\n莫畏前程多坎坷，功夫深处自然明。', LingqianLuck.ping),
  LingqianSign(34, '第三十四签 · 珠联璧合，鸾凤和鸣（大吉）', '珠联璧合两相欢，鸾凤和鸣比翼安。\n天作之合人共羡，白头偕老永团圆。', LingqianLuck.daJi),
  LingqianSign(35, '第三十五签 · 塞翁失马，焉知非福（平）', '塞翁失马难言祸，得马焉知不是灾。\n祸福相倚无定数，平常心是福门开。', LingqianLuck.ping),
  LingqianSign(36, '第三十六签 · 宝镜重明，玉环再合（大吉）', '宝镜重明照古今，玉环再合更精神。\n周而复始循环理，否极泰来自有真。', LingqianLuck.daJi),
  LingqianSign(37, '第三十七签 · 井中观天，所见者小（凶）', '井中观天所见小，不识沧海与蓬岛。\n劝君跳出狭小圈，方知天地无限好。', LingqianLuck.xiong),
  LingqianSign(38, '第三十八签 · 雾里看花，水中望月（平）', '雾里看花花不明，水中望月月无影。\n待得云开见日出，方知万事自分明。', LingqianLuck.ping),
  LingqianSign(39, '第三十九签 · 天从人愿，地发其祥（大吉）', '天从人愿喜相逢，地发其祥万事通。\n时来风送滕王阁，运到雷轰荐福碑。', LingqianLuck.daJi),
  LingqianSign(40, '第四十签 · 失之东隅，收之桑榆（平）', '失之东隅未为失，收之桑榆岂是迟。\n塞翁失马焉非福，得失常在一念之。', LingqianLuck.ping),
  LingqianSign(41, '第四十一签 · 春风得意，马蹄轻疾（大吉）', '春风得意马蹄疾，一日看尽长安花。\n锦绣前程如画展，鹏程万里趁年华。', LingqianLuck.daJi),
  LingqianSign(42, '第四十二签 · 此地无银，隔壁有耳（凶）', '此地无银三百两，隔壁阿二未曾偷。\n欲盖弥彰招人笑，坦坦荡荡自无愁。', LingqianLuck.xiong),
  LingqianSign(43, '第四十三签 · 风调雨顺，国泰民安（大吉）', '风调雨顺禾稻香，国泰民安万事昌。\n五谷丰登仓廪实，安居乐业喜洋洋。', LingqianLuck.daJi),
  LingqianSign(44, '第四十四签 · 磨杵成针，水滴石穿（平）', '磨杵成针须毅力，水滴石穿非等闲。\n功夫不负有心人，铁杵磨成绣花针。', LingqianLuck.ping),
  LingqianSign(45, '第四十五签 · 他山之石，可以攻玉（平）', '他山之石可攻玉，借人之长补己短。\n虚心纳谏胸襟广，日有所增路自宽。', LingqianLuck.ping),
  LingqianSign(46, '第四十六签 · 蟾宫折桂，金榜题名（大吉）', '蟾宫折桂步青云，金榜题名天下闻。\n一举成名从此始，前程万里尽光辉。', LingqianLuck.daJi),
  LingqianSign(47, '第四十七签 · 对牛弹琴，白费心机（凶）', '对牛弹琴空费力，明珠暗投无人识。\n莫向愚人说道理，话不投机半句多。', LingqianLuck.xiong),
  LingqianSign(48, '第四十八签 · 金玉满堂，福寿双全（大吉）', '金玉满堂家业兴，福寿双全乐太平。\n子孝孙贤承祖德，年年岁岁有余庆。', LingqianLuck.daJi),
  LingqianSign(49, '第四十九签 · 借花献佛，顺水推舟（平）', '借花献佛意殷殷，顺水推舟不费心。\n成人之美积善德，他日自得福满林。', LingqianLuck.ping),
  LingqianSign(50, '第五十签 · 学海无涯，勤舟可渡（平）', '学海无涯勤是岸，书山有路志为梯。\n莫道此身已倦怠，一篙松劲退千寻。', LingqianLuck.ping),
  LingqianSign(51, '第五十一签 · 月老牵丝，良缘天定（大吉）', '月老牵丝千里合，赤绳系足两心连。\n姻缘本是前生定，莫向东风枉自怜。', LingqianLuck.daJi),
  LingqianSign(52, '第五十二签 · 叶公好龙，表里不一（凶）', '叶公好龙名声在，真龙来时魂飞天。\n口是心非终露馅，表里如一才是贤。', LingqianLuck.xiong),
  LingqianSign(53, '第五十三签 · 五谷丰登，仓廪充实（大吉）', '五谷丰登仓廪足，六畜兴旺满庭院。\n农家勤耕天不负，一年更比一年甜。', LingqianLuck.daJi),
  LingqianSign(54, '第五十四签 · 三人成虎，众口铄金（平）', '三人成虎谎成真，众口铄金骨化尘。\n谣言止于智者耳，清者自清莫沉沦。', LingqianLuck.ping),
  LingqianSign(55, '第五十五签 · 龙凤呈祥，喜气洋洋（大吉）', '龙凤呈祥瑞气生，喜气洋洋满门庭。\n双喜临门人共庆，家和万事自然兴。', LingqianLuck.daJi),
  LingqianSign(56, '第五十六签 · 隔墙有耳，暗室亏心（平）', '隔墙有耳须谨言，暗室亏心天已知。\n杨震四知传千古，慎独自律是真师。', LingqianLuck.ping),
  LingqianSign(57, '第五十七签 · 锦心绣口，金玉满堂（大吉）', '锦心绣口吐珠玑，金玉满堂映日辉。\n一朝得遇君王顾，万丈文光射斗牛。', LingqianLuck.daJi),
  LingqianSign(58, '第五十八签 · 南辕北辙，背道而驰（凶）', '南辕北辙事难成，背道而驰空费心。\n方向一错千里谬，回头是岸早调正。', LingqianLuck.xiong),
  LingqianSign(59, '第五十九签 · 黄金铸像，白玉为堂（大吉）', '黄金铸像耀门庭，白玉为堂气象新。\n财源广进通四海，富甲一方惠乡邻。', LingqianLuck.daJi),
  LingqianSign(60, '第六十签 · 乘风破浪，披荆斩棘（平）', '乘风破浪会有时，披荆斩棘莫辞劳。\n少年当有凌云志，万里江山任尔翱。', LingqianLuck.ping),
  LingqianSign(61, '第六十一签 · 八仙过海，各显神通（大吉）', '八仙过海各神通，各展所长志趣同。\n天下英才皆我用，四海之内任西东。', LingqianLuck.daJi),
  LingqianSign(62, '第六十二签 · 掩耳盗铃，自欺欺人（凶）', '掩耳盗铃自欺人，掩鼻偷香枉费心。\n自欺欺人终害己，光明磊落才是真。', LingqianLuck.xiong),
  LingqianSign(63, '第六十三签 · 返璞归真，抱朴守拙（平）', '返璞归真见本心，抱朴守拙智慧深。\n繁华落尽真味现，平淡之中见真金。', LingqianLuck.ping),
  LingqianSign(64, '第六十四签 · 瑞气盈门，百福骈臻（大吉）', '瑞气盈门百福临，骈臻吉祥满庭金。\n天增岁月人增寿，春满乾坤福满心。', LingqianLuck.daJi),
  LingqianSign(65, '第六十五签 · 投桃报李，礼尚往来（平）', '投桃报李礼为尚，往而不来非礼方。\n人情世故通明处，路路畅通福自长。', LingqianLuck.ping),
  LingqianSign(66, '第六十六签 · 鹬蚌相争，渔翁得利（平）', '鹬蚌相争两俱伤，渔翁得利笑一场。\n劝君莫作无谓斗，退一步海阔天广。', LingqianLuck.ping),
  LingqianSign(67, '第六十七签 · 龙吟虎啸，风云际会（大吉）', '龙吟虎啸风云会，际会相逢正及时。\n三顾茅庐诚所至，卧龙一出定乾坤。', LingqianLuck.daJi),
  LingqianSign(68, '第六十八签 · 缘木求鱼，刻舟寻剑（凶）', '缘木求鱼终不得，刻舟求剑岂能逢。\n方向一错空费力，回心转意路自通。', LingqianLuck.xiong),
  LingqianSign(69, '第六十九签 · 洞房花烛，金榜题名（大吉）', '洞房花烛喜气盈，金榜题名天下惊。\n人生得意须尽欢，莫使韶光负此生。', LingqianLuck.daJi),
  LingqianSign(70, '第七十签 · 盲人摸象，管中窥豹（平）', '盲人摸象各说异，管中窥豹只见斑。\n若欲洞明全局事，须从高处放眼观。', LingqianLuck.ping),
  LingqianSign(71, '第七十一签 · 长乐未央，永受嘉福（大吉）', '长乐未央福绵绵，永受嘉福寿延延。\n岁岁年年花似锦，朝朝暮暮乐无边。', LingqianLuck.daJi),
  LingqianSign(72, '第七十二签 · 熟能生巧，巧能生精（平）', '熟能生巧日日新，巧能生精妙入神。\n百炼成钢非一日，功夫深处自通神。', LingqianLuck.ping),
  LingqianSign(73, '第七十三签 · 自相矛盾，言行不一（凶）', '自相矛盾两难全，言行不一事难圆。\n说矛道盾皆自陷，表里如一始安然。', LingqianLuck.xiong),
  LingqianSign(74, '第七十四签 · 蟠桃献寿，福海寿山（大吉）', '蟠桃献寿福如海，寿比南山松柏青。\n福如东海长流水，寿比南山不老松。', LingqianLuck.daJi),
  LingqianSign(75, '第七十五签 · 囫囵吞枣，食而不化（平）', '囫囵吞枣味不知，食而不化反伤脾。\n细嚼慢咽方入味，步步踏实是真知。', LingqianLuck.ping),
  LingqianSign(76, '第七十六签 · 紫微高照，吉星拱照（大吉）', '紫微高照运亨通，吉星拱照万事隆。\n贵人指引青云路，前程似锦乐无穷。', LingqianLuck.daJi),
  LingqianSign(77, '第七十七签 · 鲤鱼跃门，登龙有路（平）', '鲤鱼跃门逆水流，一跃成龙上九重。\n青云有路终须到，金榜无名誓不休。', LingqianLuck.ping),
  LingqianSign(78, '第七十八签 · 朝三暮四，心猿意马（凶）', '朝三暮四意不定，心猿意马事难成。\n东奔西走无结果，守一而终始有功。', LingqianLuck.xiong),
  LingqianSign(79, '第七十九签 · 千祥云集，百福并臻（大吉）', '千祥云集照门庭，百福并臻满院馨。\n吉庆有余年年好，万事亨通日日兴。', LingqianLuck.daJi),
  LingqianSign(80, '第八十签 · 雪中送炭，济困扶危（平）', '雪中送炭情义深，济困扶危见真心。\n但行好事莫问果，积善之人天自荫。', LingqianLuck.ping),
  LingqianSign(81, '第八十一签 · 鸿运当头，福星高照（大吉）', '鸿运当头万事兴，福星高照百业隆。\n时来天地皆同力，运去英雄不自由。', LingqianLuck.daJi),
  LingqianSign(82, '第八十二签 · 坐井观天，夜郎自大（凶）', '坐井观天眼界隘，夜郎自大更可哀。\n不知天外还有天，强中自有强中手来。', LingqianLuck.xiong),
  LingqianSign(83, '第八十三签 · 退避三舍，忍辱负重（平）', '退避三舍非怯懦，忍辱负重是真谋。\n大丈夫能屈能伸，来日方长终出头。', LingqianLuck.ping),
  LingqianSign(84, '第八十四签 · 春风满堂，和气致祥（大吉）', '春风满堂和气生，一家安乐万事兴。\n和气致祥千古训，福寿康宁乐太平。', LingqianLuck.daJi),
  LingqianSign(85, '第八十五签 · 黄粱一梦，南柯一枕（平）', '黄粱一梦终须醒，南柯一枕本是空。\n荣华富贵如云散，不如安贫乐道中。', LingqianLuck.ping),
  LingqianSign(86, '第八十六签 · 买椟还珠，舍本逐末（平）', '买椟还珠失本真，舍本逐末枉劳神。\n浮华外表终成幻，内在精华才是珍。', LingqianLuck.ping),
  LingqianSign(87, '第八十七签 · 梅开二度，喜上加喜（大吉）', '梅开二度又逢春，喜上加喜气象新。\n好事何妨再三至，福泽绵绵惠此身。', LingqianLuck.daJi),
  LingqianSign(88, '第八十八签 · 邯郸学步，失其本步（凶）', '邯郸学步终失步，东施效颦更丑露。\n天生我材必有用，何必羡人失本路。', LingqianLuck.xiong),
  LingqianSign(89, '第八十九签 · 福星高照，禄马交驰（大吉）', '福星高照运亨通，禄马交驰事业隆。\n吉人自有天来助，德配天地福无穷。', LingqianLuck.daJi),
  LingqianSign(90, '第九十签 · 功德圆满，万法归宗（大吉）', '功德圆满归真道，万法归宗理自通。\n九九归原终有数，一片丹心照碧空。', LingqianLuck.daJi),
  LingqianSign(91, '第九十一签 · 无事平安，心宽福至（平安）', '云淡风轻近午天，傍花随柳过前川。\n时人不识余心乐，将谓偷闲学少年。', LingqianLuck.pingAn),
  LingqianSign(92, '第九十二签 · 一本万殊，万殊一本（平安）', '万紫千红总是春，千山万水归一尘。\n本来无事常清净，何须向外觅通津。', LingqianLuck.pingAn),
];
