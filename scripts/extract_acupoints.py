#!/usr/bin/env python3
"""从倪海厦skill提取穴位详细解释，生成acupoints.json"""
import json, re, sys
sys.stdout.reconfigure(encoding='utf-8')

MODULES_FILE = r"D:\360Downloads\agent\.claude\skills\nihaisha-perspective\modules\09_zhenjiu_bencao.md"
LECTURE_FILE = r"D:\360Downloads\agent\.claude\skills\nihaisha-perspective\references\讲义-针灸教程-raw.txt"
OUT = r"D:\360Downloads\nihaisha_app\assets\data\acupoints.json"

# ── 假阳性过滤词 ──
SKIP_PATTERNS = [
    '病在', '病变', '病起', '补泻', '五脏', '担法', '截法',
    '三关', '眼诊', '癫、痫', '四穴放血', '与四季', '火罐',
    '针号', '九针', '逼毒', '急救', '针灸的使用', '丈量',
    '针刺的深浅', '入穴方式', '四季', '子午流注',
    '任脉经穴', '肺经母穴',
]

def is_valid_acupoint_name(name):
    """判断是否为有效穴位名"""
    # 长度检查：穴位名一般2-6个字
    if len(name) > 8 or len(name) < 2:
        return False
    # 过滤假阳性
    for skip in SKIP_PATTERNS:
        if skip in name:
            return False
    # 必须以"穴"结尾
    if not name.endswith('穴'):
        return False
    # 过滤含特殊字符的
    if any(c in name for c in ['①', '②', '③', '④', '⑤', '至', '奇：', '经外奇']):
        return False
    return True

def clean_acupoint_name(name):
    """清理穴位名：去掉编号前缀、脚注标记等"""
    # 去掉 "数字、" 或 "数字" 前缀（如 "2下关" → "下关"）
    name = re.sub(r'^\d+[、.\s]?\s*', '', name)
    # 去掉脚注标记 ①②③④⑤
    name = re.sub(r'[①②③④⑤⑥⑦⑧⑨⑩]', '', name)
    # 去掉 "奇穴：" 或 "奇：" 或 "经外奇：" 前缀
    name = re.sub(r'^(?:经外)?奇穴?[：:]', '', name)
    # 去掉 "母穴：" 或 "母：" 前缀
    name = re.sub(r'^母穴?[：:]', '', name)
    # 去掉位置描述前缀（如 "大椎外五分定喘穴" → "定喘穴"）
    m = re.search(r'(?:外|内|上|下|旁|前|后)(?:约)?(?:一|二|三|四|五|六|七|八|九|十|半)(?:寸|分|横指)\s*(.+?穴)$', name)
    if m:
        name = m.group(1)
    # 去掉末尾多余空格
    name = name.strip()
    return name

def split_compound_name(name):
    """拆分复合穴位名（如"脊中与筋缩穴"→ ["脊中穴", "筋缩穴"]）"""
    # 处理 "X与Y穴" 或 "X和Y穴"
    m = re.match(r'^(.+?)[与和](.+?穴)$', name)
    if m:
        return [m.group(1).strip() + '穴', m.group(2).strip()]
    # 处理 "X、Y穴" 格式（1个或多个顿号分隔）
    if '、' in name:
        parts = name.split('、')
        result = []
        for p in parts:
            p = p.strip()
            if not p:
                continue
            if not p.endswith('穴'):
                p = p + '穴'
            result.append(p)
        if len(result) > 1:
            return result
    return [name]

def extract_location_from_notes(notes):
    """从临床笔记中提取位置描述"""
    if not notes:
        return ''
    # 尝试匹配常见的位置描述模式
    patterns = [
        r'(?:在|位于|穴在|此穴).{5,60}(?:处|上|下|旁|内|外|方|间)',
        r'脐[下上](?:约)?(?:一|二|三|四|五|六|七|八|九|十|半)(?:寸|分|横指)',
        r'(?:第[一二三四五六七八九十]+|旁开)(?:寸|分|横指).{5,40}',
        r'(?:寸|分).{5,40}(?:寸|分)',
    ]
    for pat in patterns:
        m = re.search(pat, notes)
        if m:
            start = max(0, m.start() - 20)
            end = min(len(notes), m.end() + 20)
            loc = notes[start:end].strip()
            # 清理换行
            loc = loc.replace('\n', ' ')
            return loc
    # 如果没匹配到，取前100字作为位置描述（很多讲义位置描述在开头）
    first_para = notes.split('\n')[0][:150]
    return first_para.strip()

# ── Step 1: 从模块文件提取穴位列表 ──
with open(MODULES_FILE, 'r', encoding='utf-8') as f:
    modules_text = f.read()

acupoints = {}  # name -> {meridian, attribute, description}

current_meridian = ''
for line in modules_text.split('\n'):
    # 经络标题
    m = re.match(r'^###\s+(.+经脉?|任脉要穴|督脉要穴|公孙穴)', line)
    if m:
        current_meridian = m.group(1).replace('要穴', '').strip()
        continue

    # 穴位条目
    m = re.match(r'^-\s+\*\*(.+?穴)\*\*[：:]\s*(.*)$', line)
    if m:
        name = m.group(1).strip()
        desc = m.group(2).strip()
        if not is_valid_acupoint_name(name):
            continue
        attribute = ''
        attr_match = re.search(r'(募穴|俞穴|原穴|合穴|郄穴|络穴|井穴|荥穴|经穴|下合穴|膏之原|母穴|子穴)', desc)
        if attr_match:
            attribute = attr_match.group(1)

        acupoints[name] = {
            'name': name,
            'meridian': current_meridian,
            'attribute': attribute,
            'description': desc,
            'location': '',
            'needling': '',
            'moxibustion': '',
            'contraindication': '',
            'clinicalNotes': '',
        }

print(f"From modules: {len(acupoints)} acupoints")

# ── Step 2: 从讲义原文提取详细解释 ──
with open(LECTURE_FILE, 'r', encoding='utf-8') as f:
    lecture_lines = f.readlines()

acupoint_sections = {}
i = 0
while i < len(lecture_lines):
    line = lecture_lines[i].strip()

    title_match = None
    acupoint_name = None

    # 匹配 "数字、XXX—穴位名" 或 "数字、穴位名"
    m = re.match(r'^\d+[、.]\s*(?:.*?[—\-])?\s*(.+?穴(?:\s*[与和]\s*.+?穴)?)\s*[（(]', line)
    if m:
        name_part = m.group(1).strip()
        # 拆分复合名，取第一个
        names = split_compound_name(name_part)
        acupoint_name = names[0] if names else None
        if acupoint_name and not is_valid_acupoint_name(acupoint_name):
            acupoint_name = None
        else:
            title_match = line

    # 匹配 "穴位名穴" 在标题行
    if not title_match:
        m = re.match(r'^(.+?穴)\s*[（(]', line)
        if m and '之' not in line[:5] and ' chapter' not in line.lower():
            candidate = m.group(1).strip()
            candidate = clean_acupoint_name(candidate)
            if is_valid_acupoint_name(candidate):
                title_match = line
                acupoint_name = candidate

    if acupoint_name:
        content_lines = []
        j = i + 1
        while j < len(lecture_lines):
            next_line = lecture_lines[j].strip()
            if re.match(r'^\d+[、.]\s*(?:.*?[—\-])?\s*.+?穴', next_line):
                break
            if next_line.startswith('V2-201') or next_line.startswith('人纪系列'):
                j += 1
                continue
            if next_line.startswith('第') and '章' in next_line:
                break
            if next_line.startswith('##') or next_line.startswith('###'):
                break
            if next_line:
                content_lines.append(next_line)
            j += 1

        content = '\n'.join(content_lines)
        if len(content) > 50:
            if acupoint_name not in acupoint_sections or len(content) > len(acupoint_sections[acupoint_name]):
                acupoint_sections[acupoint_name] = content

    i += 1

print(f"From lecture: {len(acupoint_sections)} acupoint sections")

# ── Step 3: 合并数据 ──
merged = 0
for name, section in acupoint_sections.items():
    # 清理名称
    clean_name = clean_acupoint_name(name)
    # 拆分复合名，只取第一个穴位
    if '、' in clean_name or '与' in clean_name or '和' in clean_name:
        parts = split_compound_name(clean_name)
        clean_name = parts[0] if parts else clean_name
    # 确保以"穴"结尾
    if not clean_name.endswith('穴'):
        clean_name = clean_name + '穴'
    if clean_name in acupoints:
        existing = acupoints[clean_name]
        if len(section) > len(existing.get('clinicalNotes', '')):
            existing['clinicalNotes'] = section[:2000]
            merged += 1
    else:
        # 跳过无效名称
        if not is_valid_acupoint_name(clean_name):
            continue
        acupoints[clean_name] = {
            'name': clean_name,
            'meridian': '',
            'attribute': '',
            'description': '',
            'location': '',
            'needling': '',
            'moxibustion': '',
            'contraindication': '',
            'clinicalNotes': section[:2000],
        }

print(f"Merged: {merged} detailed explanations")

# ── Step 4: 从临床笔记中提取位置信息 ──
for name, data in acupoints.items():
    notes = data.get('clinicalNotes', '')
    if notes and not data['location']:
        data['location'] = extract_location_from_notes(notes)

# ── Step 5: 清理异常名称 ──
to_remove = []
to_add = []
for name, data in acupoints.items():
    cleaned = clean_acupoint_name(name)
    if cleaned != name:
        data['name'] = cleaned
        to_remove.append(name)
        to_add.append((cleaned, data))

for name in to_remove:
    del acupoints[name]
for name, data in to_add:
    if name not in acupoints:
        acupoints[name] = data

# ── Step 6: 输出 ──
output = {
    'total': len(acupoints),
    'acupoints': list(acupoints.values())
}

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

with_notes = sum(1 for a in acupoints.values() if a['clinicalNotes'])
with_location = sum(1 for a in acupoints.values() if a['location'])
print(f"\nTotal acupoints: {len(acupoints)}")
print(f"With clinical notes: {with_notes}")
print(f"With location: {with_location}")
print(f"Written to {OUT}")
