# 穴位空字段增补操作手册（needling / moxibustion / contraindication）

> 交接对象：任意本地 AI agent / 开发者，无需历史上下文。
> 任务：`assets/data/acupoints.json` 中 **159 个空 `needling`**、**170 个空 `moxibustion`** 的穴位，按讲稿原文增补内容；`contraindication` 顺带处理。
> 候选清单：`tool/enrich_candidates.json`（已按讲稿频次筛选排序，含误报排除）。
> 规范依据：`docs/acupoint_style_guide.md`（先读）+ `docs/acupoint_backfill_manual.md` §3（修复函数可直接复用）。

---

## 0. 任务一句话

对候选清单中的穴位（159 个空 `needling`、170 个空 `moxibustion`，两表高度重叠），从讲稿原文提取该穴的针法/灸法内容，按 `set_field()` 文本级替换写入空字段；每批次备份 → 补全 → 验收 → **本地 commit**（🔴 push 前必须经用户确认，见 §7）；**备份保留到全部完成后询问用户是否删除**。

## 1. 路径与环境

| 项 | 路径/值 |
|---|---|
| 数据文件 | `D:\AndroidProjects\nihaisha_app\assets\data\acupoints.json` |
| 候选清单 | `D:\AndroidProjects\nihaisha_app\tool\enrich_candidates.json` |
| 讲稿目录 | `assets\zhenjiu_lecture\`（按经脉编号文件） |
| 结构化讲稿 | `assets\data\acupuncture.json` |
| 古籍语料 | `assets\guji\zhenjiudacheng.txt` |
| 审计脚本 | `python tool/audit_acupoints.py` |
| 规范文档 | `docs\acupoint_style_guide.md` |
| 修复函数 | `docs\acupoint_backfill_manual.md` §3（`set_field()` / `validate()` 直接复制） |
| Flutter | `/d/flutter/bin/flutter`，命令前必设 `TEMP/TMP="C:/Users/jangviktor/AppData/Local/Temp"` |
| 远程 | `origin`=GitHub（push 走代理 7890）；`cnb`=CNB（push 加 `-c http.proxy=` 直连） |

## 2. 硬规则（违反 = 白干）

1. ⛔ **禁止 `json.dump` 全量重写**——只允许文本级行替换（`set_field()`）。
2. 🔴 **每个批次修改前必须备份，且备份不删除**：
   ```bash
   cp assets/data/acupoints.json assets/data/acupoints.json.bak-$(date +%Y%m%d)-enrich-batchN
   ```
   - 备份文件 `.bak-<日期>-enrich-batch<N>`，**绝不 git add**；
   - 🔴 **全部批次完成并验收后，禁止自行删除备份**——整理备份文件清单（路径 + 大小 + 创建时间），**询问用户要不要删**，用户明确说删才删；
   - 恢复：`cp 备份文件 assets/data/acupoints.json`（优先）或 `git checkout -- assets/data/acupoints.json`（兜底）。
3. 取材只认讲稿原文（`zhenjiu_lecture/*.md` + `acupuncture.json` + `zhenjiudacheng.txt`），**禁止臆写任何讲稿没有的句子**。
4. 每穴完成后立刻跑单穴校验；每批完成后跑完整验收（§6）。
5. ⚠️ 讲稿语料与 `acupoints.json` 数据源**措辞有版本差异**（源是 PDF 提取版，含粗体/时间戳/OCR 措辞）——溯源验证按 §5 的多源口径，未命中 ≠ 臆写，需人工确认。
6. ⛔ **本任务只允许改 `needling` / `moxibustion` / `contraindication` 三个字段，禁止触碰 `clinicalNotes`**（也不能改动 `name` / `meridian` / `location` / `description` / `attribute`）。
   - 唯一例外：把新字段插入 `clinicalNotes` **之前**时，该行的**尾逗号**会从无到有——这是合法副作用，**内容值必须逐字不变**。
   - 历史事故：增补第 3 批前，执行 agent 越界重写 `clinicalNotes`，把已按用户要求完成的 7 穴【要点归纳】段整体清掉，直到审计与快照对比才发现（见 §10 判例）。
   - 每批必须用 §6 第 5 步做「`clinicalNotes` 零改动」校验，不通过即回滚该批。

## 3. 候选清单与批次

清单 `tool/enrich_candidates.json` 结构：
```json
{ "needling_candidates": [{name, meridian, freq}...159],
  "moxibustion_candidates": [...170],
  "excluded_false_positives": ["气穴","太阳","子宫","阑尾"],
  "freq_rule": "..." }
```

- **排除的误报**：气穴（《气穴论》篇名）、太阳（太阳经/太阳病）、子宫（器官）、阑尾（器官）——这些穴名的讲稿频次不代表讲该穴。执行中发现新的疑似误报（穴名与常见词重名），加入排除并记录。
- **批次划分**：按 `freq` 降序，每批 **15 个穴位**（不是 15 个字段；同穴的 `needling` / `moxibustion` / `contraindication` 合并处理，一穴最多动 3 行），共约 **11 批**。

### 3.1 两表合并与递补规则（🔴 必须按此执行，避免批次名单争议）

清单里 `needling_candidates`(159) 与 `moxibustion_candidates`(170) 高度重叠但不等长。批次按以下规则生成：

1. **主序列**：`needling_candidates` 按 freq 降序，每批取 15 穴；同穴若 `moxibustion` 也空，一并补两个字段。
2. **递补**：若穴中某字段在讲稿本穴段落里**没有内容可补**（按 §4 判定应留空），不得凑数，从 `moxibustion_candidates` 降序中取下一个「仅 `moxibustion` 空、needling 已有内容」的高频穴递补，保持每批 15 穴。
3. **记录**：每次递补在批次备注里写明「替换了谁、递补了谁、原因（讲稿无该字段内容）」。
4. 已完成批次第 2 批即按此规则递补了劳宫/太渊/带脉/阳陵泉（均在 moxibustion 候选 TOP30），属合规。

> ⚠️ 批次名单以「实际有内容可补的穴位」为准，不是机械照抄 `needling_candidates` 的 TOP30；但**每批必须 15 穴、按 freq 降序、递补有记录**。
- **第一批名单（TOP15，直接开工）**：三阴交穴、内关穴、中脘穴、神门穴、委中穴、公孙穴、阴陵泉穴、列缺穴、肩井穴、涌泉穴、外关穴、支沟穴、血海穴、人中、肺俞穴。
- 注意：`外关穴` 的 `clinicalNotes` 已在 17 穴补全中写入（f65ff13），本任务只补它的 `needling`/`moxibustion` 空字段。

## 4. 取材规则

1. 定位：`grep -n "<穴名>" assets/zhenjiu_lecture/<对应经脉文件>.md`（文件按经脉编号，可先 `grep -rln` 找）；同时查 `acupuncture.json` 中该穴的讲解字段。
2. 提取**本穴段落**范围内的：
   - 针法内容（针几分、方向、手法、补泻）→ 写入 `needling`；
   - 灸法内容（灸几壮、隔姜/隔盐灸、禁灸）→ 写入 `moxibustion`；
   - 禁忌内容（禁灸/不宜深刺/孕妇）→ 写入 `contraindication`；
   - 讲稿没讲该字段 → **留空，禁止编造**。
3. 写法遵循 `acupoint_style_guide.md` §1：needling 书证优先（`《铜人》针X分…`）；moxibustion 灸壮格式或讲稿灸法原话；讲稿原话可保留口语。
4. ⚠️ 同名歧义穴位（如三毛、人中）先确认讲稿段落讲的就是本穴。

## 5. 溯源验证（防臆写，每穴必做）—— 三级口径

🔴 **背景**：数据普遍采用「**书证 + 倪师：/倪海厦： + 释义**」拼接格式（补全前基线已有 29 处），书证与释义分属讲稿不同段落。这种格式下**连续 15 字片段必然命中不了语料**，直接用旧口径会把合规内容误判为臆写（实测字面仅 71%，实质 100% 可溯源）。

三级验证（累计通过率 **≥95%** 才算过）：

1. **一级**：新值中 15 字片段（步长 9）查语料，排除旧值已有的片段；
2. **二级**：未命中 → 缩短到 10 字再查；
3. **三级**：仍未命中 → **剥离标签 + 按句拆分**：去掉 `倪师：` / `倪海厦：` / `师：`，按 `。；，！？、` 拆成 ≥6 字短句，任一句（或清洗后首尾 8 字）命中语料即算有源。

```python
import re, glob, json
corpus = re.sub(r'\s+', '',
    ''.join(open(f, encoding='utf-8').read() for f in glob.glob('assets/zhenjiu_lecture/*.md'))
    + json.dumps(json.load(open('assets/data/acupuncture.json', encoding='utf-8')), ensure_ascii=False)
    + open('assets/guji/zhenjiudacheng.txt', encoding='utf-8').read())

def traceable(fr):
    cleaned = re.sub(r'倪师：|倪海厦：|师：', '', fr)
    parts = [p for p in re.split(r'[。；，！？、\s]+', cleaned) if len(p) >= 6]
    return (any(p in corpus for p in parts)
            or cleaned[:8] in corpus or cleaned[-8:] in corpus)
# 对一级/二级未命中的片段逐个调用 traceable；仍 False 的列为「实质疑点」
```

- **实质疑点**必须逐个人工确认：读讲稿本穴段落原文（如 `grep -n "<穴名>" assets/zhenjiu_lecture/*.md`），确认有据即通过；确认臆写的**立即改回空**。
- 判例：肩井 needling「不能深针…下针要下得很浅」三级口径曾是疑点，人工核对逐字命中讲稿 183 行 → 通过。
- ⚠️ 一级/二级的字面命中率**不作为验收依据**，只用三级累计值判断。

## 6. 验收流程（每批，逐条过）

```bash
cd /d/AndroidProjects/nihaisha_app
# 1. JSON 合法 + 结构
python -c "import json; d=json.load(open('assets/data/acupoints.json',encoding='utf-8')); assert d['total']==401 and len(d['acupoints'])==401; print('ok')"
# 2. 审计：0 error；不新增 A5/A6 张冠李戴 warning
python tool/audit_acupoints.py
# 3. diff：每穴每字段 1 行；变更行数 = 本批穴数 × 补全字段数
git diff --stat assets/data/acupoints.json
# 4. 测试（10 文件 47 用例全过）
for f in test/acupoint_canon_order_test.dart test/acupoint_link_eligibility_test.dart \
         test/acupoint_meridian_order_test.dart test/acupoint_name_tiebreak_test.dart \
         test/acupoint_rich_text_test.dart test/acupuncture_erxue_test.dart \
         test/llm_acu_accuracy_test.dart test/llm_symptom_accuracy_test.dart \
         test/markdown_link_href_test.dart test/meridian_map_test.dart; do
  r=$(TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="$TEMP" /d/flutter/bin/flutter test $f 2>&1 | tail -1)
  echo "[$(basename $f)] $r"
done
# 5. clinicalNotes 零改动（🔴 硬校验，不看 diff 行只看字段值；尾逗号变化不算改动）
python - <<'PY'
import json, subprocess
h = {a['name']: a['clinicalNotes'] for a in json.loads(subprocess.run(
    ['git', 'show', 'HEAD:assets/data/acupoints.json'], capture_output=True,
    text=True, encoding='utf-8').stdout)['acupoints']}
w = {a['name']: a['clinicalNotes'] for a in json.load(
    open('assets/data/acupoints.json', encoding='utf-8'))['acupoints']}
bad = [k for k in w if h.get(k) != w[k]]
print('clinicalNotes 改动:', bad or '无')
assert not bad, '越界：clinicalNotes 内容被改动 %s，回滚本批' % bad
PY
```
> 本检查只针对**增补批次**。手工恢复/润色 `clinicalNotes` 属另一类操作，应在独立 commit 里说明原因，不能混进增补批次。

## 7. 提交（每批一个 commit）—— 🔴 push 前必须经用户确认

```bash
git add assets/data/acupoints.json
git commit -m "feat(acupoints): 增补第N批N穴的needling/moxibustion（TOP频次批次）"
```

- 🔴 **commit 只留在本地，禁止自行 push**。每批验收（§6）全绿后，向用户报告结果并**明确询问是否推送**；用户说出「推 / push / 上传」字样后才执行以下双推：

```bash
git -c http.postBuffer=52428800 -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 push origin main
git -c http.postBuffer=52428800 -c http.proxy= push cnb main
```

推完核对三端一致（`git rev-parse HEAD` vs 两个 `ls-remote`）。

## 8. 全部批次完成后（⛔ 不是自动执行）

1. 跑终审：`python tool/audit_acupoints.py`（0 error；A4 仅剩已知的 17 穴台账项——那些是截断补全的另一任务）；
2. 整理**备份文件清单**：`ls -la assets/data/*.bak-*`（路径、大小、时间）；
3. **向用户报告 + 询问：「备份文件共 N 个，是否删除？」**——用户明确说删才执行 `rm`。禁止自行删除。

## 9. 部署（用户确认后）

网页版：重建带 base-href（`/nihaixia-app/web/`）的产物覆盖 `docs/web/`，bash 传参加 `MSYS_NO_PATHCONV=1`；推完若 Pages 未自动构建，`gh api -X POST /repos/jangviktor-web/nihaixia-app/pages/builds` 手动触发。APK：走正常发版（`+N` 递增）。

## 10. 历史判例

| 案例 | 教训 |
|---|---|
| 巨阙/上脘/禾髎 字段错位 | 取材必须定位**本穴段落**，严禁跨穴复制 |
| json.dump 全量重写两次污染 diff | 只用文本级行替换 |
| bootstrap 大小误判线上未更新 | 判断 Web 产物版本看 `main.dart.js` 字节数 |
| MSYS 路径转换破坏 `/` 开头参数 | `--base-href`、`--open-task-id` 等以 `/` 开头的参数加 `MSYS_NO_PATHCONV=1` |
| 增补批次清掉 7 穴【要点归纳】 | 越界重写 `clinicalNotes`：本任务只改针法/灸法/禁忌三字段，验收必须跑 §6 第 5 步字段值对比（备份救回了成果） |
