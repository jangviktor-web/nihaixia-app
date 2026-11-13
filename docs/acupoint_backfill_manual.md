# 穴位临床要点补全操作手册（17 个截断穴位）

> 交接对象：任意本地 AI agent / 开发者，无需历史上下文，按本文档可直接执行。
> 任务：`assets/data/acupoints.json` 中 17 个穴位的 `clinicalNotes` 字段在数据生成期被截断到 2000 字（全部截在句子中途）。需对照讲稿原文补全，并剔除混入的下穴/章头内容。
> 规范依据：`docs/acupoint_style_guide.md`（先读第 1、2 节）。
> 配套审计：`python tool/audit_acupoints.py`（本文验收命令都在其中）。

---

## 0. 任务一句话

对下列 17 个穴位，从讲稿原文中找到**本穴临床讲解段落的完整范围**，将 `clinicalNotes` 整值替换为**补全后的完整文本**（原截断值只是它的前 2000 字）。补完跑审计与测试，零 error 后提交双推。

## 1. 路径与环境

| 项 | 路径/值 |
|---|---|
| 数据文件 | `D:\AndroidProjects\nihaisha_app\assets\data\acupoints.json` |
| 讲稿目录 | `D:\AndroidProjects\nihaisha_app\assets\zhenjiu_lecture\` |
| 审计脚本 | `D:\AndroidProjects\nihaisha_app\tool\audit_acupoints.py` |
| 规范文档 | `D:\AndroidProjects\nihaisha_app\docs\acupoint_style_guide.md` |
| Flutter | `/d/flutter/bin/flutter`（bash）或 `D:\flutter\bin\flutter.bat` |
| 环境前缀（必设） | `TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="$TEMP"` |
| 远程 | `origin` = GitHub（push 走代理 `http://127.0.0.1:7890`）；`cnb` = https://cnb.cool/Jangviktor/nihaixia-app（push 加 `-c http.proxy=` 直连） |

## 2. 数据格式硬规则（违反 = 白干）

1. **⛔ 禁止 `json.dump` 全量重写**——会展开 compact 数组（`"meridians": ["冲脉"]` 变多行），污染 diff 约 +180 行假变更。只能**文本级行替换**（见 §3 模板）。
2. 文件格式：2 空格缩进；穴位对象字段一行一个；**短数组保持单行**；文件以 `\n` 结尾；LF 存储（git autocrlf=true 会把工作区显示为 CRLF，属正常，`git status` 认为无差异不代表内容没变——比较内容必须按 LF 规范化后比）。
3. `clinicalNotes` **无长度上限**——补全后 3000–4000 字是正常的，原 2000 是生成期 bug。
4. 值内换行写作 `\n`（JSON 转义），引号 `\"`。
5. 🔴 **修改前必须备份原文件**（本会话真实发生过改坏 JSON 的事故）。备份文件**绝不 git add**；本批验收全绿后才可删除。

## 3. 通用修复函数（直接复制使用）

```python
import json, re

PATH = 'D:/AndroidProjects/nihaisha_app/assets/data/acupoints.json'

def set_field(name: str, field: str, value: str):
    """文本级替换某穴位某字段的整行值。保留缩进与尾逗号。"""
    lines = open(PATH, encoding='utf-8').read().split('\n')
    for i, ln in enumerate(lines):
        if f'"name": "{name}"' in ln:
            for j in range(i + 1, min(i + 40, len(lines))):
                if '"name":' in lines[j]:
                    raise ValueError(f'{name}: 未在 40 行内找到 {field}，人工检查')
                if f'"{field}":' in lines[j]:
                    indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())]
                    trail = ',' if lines[j].rstrip().endswith(',') else ''
                    # 值内 JSON 转义：反斜杠与引号
                    val = value.replace('\\', '\\\\').replace('"', '\\"')
                    lines[j] = f'{indent}"{field}": "{val}"{trail}'
                    open(PATH, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
                    return
            raise ValueError(f'{name}: 未找到 {field}')
    raise ValueError(f'未找到穴位 {name}')

def validate():
    d = json.load(open(PATH, encoding='utf-8'))
    assert d['total'] == 402 and len(d['acupoints']) == 402, '结构破坏'
    return d
```

操作模型：**整值替换**。步骤 = ⓪ **备份**（见下）→ ① 从讲稿提取本穴完整段落原文 → ② 清洗（见 §4）→ ③ `set_field(穴名, 'clinicalNotes', 新文本)` → ④ `validate()`。

### ⓪ 备份（每个批次开始前必做，一次即可）

```bash
cd /d/AndroidProjects/nihaisha_app
cp assets/data/acupoints.json assets/data/acupoints.json.bak-$(date +%Y%m%d)-batchN
```

- 备份文件命名 `.bak-<日期>-batch<N>`，**不进 git**（验收后删除，绝不 `git add *.bak*`）。
- 恢复：`cp assets/data/acupoints.json.bak-<...> assets/data/acupoints.json`（优先）或 `git checkout -- assets/data/acupoints.json`（兜底，恢复到 HEAD 版本）。
- 批次结束验收全绿后：`rm assets/data/acupoints.json.bak-*`。

## 4. 取材与边界判定（决定补什么、剔什么）

1. **定位讲稿**：`grep -rn "<穴名>" assets/zhenjiu_lecture/` 找到本穴讲解所在文件与行号。讲稿章节标题格式 `#### 8.胃之募穴一中脘`。
2. **本穴段落范围**：从本穴小节标题（或穴名首次出现）起，到**下一个 `####` 小节标题**（或下一个穴位名）止。这段内的讲稿正文 + 书证引文 + 《单穴治病选萃》条目，全部属于本穴。
3. **清洗规则**：
   - 剔除混入的**其他穴/章开头**（如陷谷尾部「现在要介绍脾脏…六、足阳明胃经」、头维尾部的颊车/地仓段）；
   - 讲稿小节标题行（`乳癌之针灸治疗（ 3-01:00:53 ）` 式）**保留**——是内容结构；
   - 讲稿 OCR 空格/换行保留原样，不做美化。
4. **补全后的值** = 原截断文本（去掉尾部混入）+ 讲稿中缺失的后续内容。**逐句核对来源，禁止臆写任何讲稿没有的句子。**
5. 判断「截断混入」：当前尾部（见 §5 任务卡）之后的讲稿内容若属于**下一个穴位/下一章**，从该处截断；若属于**本穴讲解的延续**，续接。

## 5. 任务清单（17 穴，每穴一张卡）

> 尾部 = 当前 `clinicalNotes` 的最后 ~20 字，用于核对是否同一版本；**任务批次顺序即执行顺序**。

### 第一批（常用大穴，7 个）

| 穴位 | 经脉 | 讲稿文件 | 当前尾部 | 备注 |
|---|---|---|---|---|
| 关元穴 | 任脉 | `21_第四章任脉经穴.md`（约 171 行起） | 「男人除非阴部被」 | 脐下血水段被截 |
| 委中穴 | 足太阳膀胱经 | `29_第四章足太阳膀胱经.md` | 「有一种带状疱」 | 委中放血/疱疹段 |
| 外关穴 | 手少阳三焦经 | `32_第四章手少阳三焦经.md` | 「就是」 | 眼珠斜视揉耳段之后 |
| 大陵穴 | 手厥阴心包经 | `31_第四章手厥阴心包经.md` | 「在行房的时」 | 三焦气/命门段之后 |
| 风门穴 | 足太阳膀胱经 | `29_第四章足太阳膀胱经.md` | 「相生的现象出现了」 | 肺病正治段之后 |
| 听宫穴 | 手太阳小肠经 | `28_第四章手太阳小肠经.md` | 「因为往上」 | 膀胱气化段之后 |
| 少府穴 | 手少阴心经 | `27_第四章手少阴心经.md` | 「让它木」 | 木火土金水段之后 |

### 第二批（6 个）

| 穴位 | 经脉 | 讲稿文件 | 当前尾部 | 备注 |
|---|---|---|---|---|
| 乳中穴 | 足阳明胃经 | `25_第四章足阳明胃经.md` | 「第一种吸出来，小孩子吸出来，但有」 | 母乳排出方式列举 |
| 厥阴俞穴 | 足太阳膀胱经 | `29_第四章足太阳膀胱经.md` | 「反而逆流出」 | 红斑狼疮段之后 |
| 大杼穴 | 足太阳膀胱经 | `29_第四章足太阳膀胱经.md` | 「五点到七点，」 | 流注歌诀段之后 |
| 通谷穴 | 足太阳膀胱经 | `29_第四章足太阳膀胱经.md` | 「当然就不知道该如何诊断。而」 | 生理学段之后 |
| 素髎穴 | 督脉 | `24_第四章督脉经穴.md` | 「那你这样子时，要有」 | 六字诀呬字段之后 |
| 陷谷穴 | 足阳明胃经 | `25_第四章足阳明胃经.md` | ❌ 尾部混入「现在要介绍脾脏…六、足阳明胃经」 | **先剔除章头，再从陷谷段续接** |

### 第三批（4 个）

| 穴位 | 经脉 | 讲稿文件 | 当前尾部 | 备注 |
|---|---|---|---|---|
| 和髎穴 | 手少阳三焦经 | `32_第四章手少阳三焦经.md` | 「肝木生」 | 胆木生火段之后 |
| 头维穴 | 足阳明胃经 | `25_第四章足阳明胃经.md` | 「这两边突起一块的就是地仓。地仓⏎」 | 尾部是颊车/地仓内容，判断归属后剔除或续接 |
| 定喘穴 | 经外奇穴 | 多章节拼合（grep 定位） | 「现在有一种」 | 来源跨章节，谨慎核对边界 |
| 阑尾穴 | 经外奇穴 | 多章节拼合（grep 定位） | 「对西医来说可能是子」 | 尾部讲下巨虚（胃经），阑尾段与胃经段边界需判 |

## 6. 验收流程（每批完成后执行，逐条过）

```bash
cd /d/AndroidProjects/nihaisha_app

# 1. JSON 合法 + 结构
python -c "import json; d=json.load(open('assets/data/acupoints.json',encoding='utf-8')); assert d['total']==402 and len(d['acupoints'])==402; print('ok')"

# 2. 审计：error 必须为 0；本批穴位不得再出现 A4 warning
python tool/audit_acupoints.py

# 3. diff 检查：每穴只应变化 1 行（clinicalNotes），总变更行数 = 穴数
git diff --stat assets/data/acupoints.json

# 4. 穴位测试（10 个文件 47 用例，必须全过）
for f in test/acupoint_canon_order_test.dart test/acupoint_link_eligibility_test.dart \
         test/acupoint_meridian_order_test.dart test/acupoint_name_tiebreak_test.dart \
         test/acupoint_rich_text_test.dart test/acupuncture_erxue_test.dart \
         test/llm_acu_accuracy_test.dart test/llm_symptom_accuracy_test.dart \
         test/markdown_link_href_test.dart test/meridian_map_test.dart; do
  r=$(TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="$TEMP" /d/flutter/bin/flutter test $f 2>&1 | tail -1)
  echo "[$(basename $f)] $r"
done
```

验收硬标准：审计 0 error；本批穴位 A4 warning 全部消失；测试全绿；diff 行数 = 本批穴数。

**验收全绿后的收尾**：删除备份文件 `rm assets/data/acupoints.json.bak-*`（若验收未过需要重做，备份保留到下一轮成功为止）。

## 7. 提交与双推

```bash
# 每批一个 commit
git add assets/data/acupoints.json
git commit -m "fix(acupoints): 补全第N批N穴截断的临床要点（关元/委中/外关/大陵/风门/听宫/少府）"

# 双推（顺序固定：GitHub 成功后才推 CNB）
git -c http.postBuffer=52428800 -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 push origin main
git -c http.postBuffer=52428800 -c http.proxy= push cnb main
```

推完核对三端一致：`git rev-parse HEAD` 与两个 `ls-remote` 相同。

## 8. 部署（补全全部完成后，可选）

网页版：重建带 base-href 的产物并覆盖 `docs/web/`（参照仓库内 `docs/web-adaptation.md`），base href 必须 `/nihaixia-app/web/`，bash 传参要加 `MSYS_NO_PATHCONV=1`。APK：走正常发版流程（`+N` 递增，勿用本地同号包覆盖线上）。

## 9. 历史参照案例（照着做）

| 案例 | 错误 | 修法 |
|---|---|---|
| 巨阙穴 | `location`/`clinicalNotes` 填了目录页码行；`moxibustion`/`contraindication` 错填上脘段内容 | 四字段按讲稿 609/615-649 行重写 |
| 上脘穴 | `needling` 误填巨阙书证「针六分留七呼」 | 换回上脘自己书证「针八分，灸二七壮」 |
| 禾髎穴 | `clinicalNotes` 末尾混入「（3-00:20:35 ）」+ 下一章章头 | 行内截断到「大肠经的经穴终了。」 |

判例规则：**字段内容中心穴位 ≠ 本穴名 → 错位，须重写**；讲稿小节标题行 → 保留。
