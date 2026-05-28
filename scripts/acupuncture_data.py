#!/usr/bin/env python3
"""解析215条针灸经验markdown，生成结构化acupuncture.json"""
import json, re, sys
sys.stdout.reconfigure(encoding='utf-8')

SRC = r"D:\360Downloads\agent\.claude\skills\nihaisha-perspective\references\sources\215条针灸经验穴位和31条透针透穴.md"
OUT = r"D:\360Downloads\nihaisha_app\assets\data\acupuncture.json"

with open(SRC, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# ── 解析穴位处方 ──
categories = []
current_cat = None
misc_entries = []  # @开头的杂项
pending_case = None  # 待附加的医案
entry_id_global = 0

def parse_acupoints(text):
    """从文本中提取穴位列表，返回 [{'name':..., 'method':...}]"""
    # 去掉末尾分号
    text = text.rstrip('；;。.')
    # 按顿号、逗号、分号分割
    parts = re.split(r'[、，,；;]', text)
    result = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        method = None
        name = p
        # 检查括号标注
        m = re.match(r'^(.+?)（(.+?)）$', p)
        if m:
            name = m.group(1).strip()
            method = m.group(2).strip()
        elif '(' in p:
            idx = p.index('(')
            name = p[:idx].strip()
            method = p[idx+1:].rstrip(')').strip()
        if name:
            result.append({'name': name, 'method': method})
    return result

def parse_entry_line(line):
    """解析 'N. 症状名：穴位列表' 格式"""
    m = re.match(r'^\d+\.\s*(.+?)：(.+)$', line)
    if not m:
        # 有些用冒号是全角
        m = re.match(r'^\d+\.\s*(.+?)：(.+)$', line)
    if not m:
        m = re.match(r'^\d+\.\s*(.+?)∶(.+)$', line)
    if not m:
        return None
    symptom_text = m.group(1).strip()
    acupoint_text = m.group(2).strip()

    # 拆分症状名和别名
    aliases = []
    if '_' in symptom_text:
        parts = symptom_text.split('_')
        symptom_text = parts[0].strip()
        aliases = [p.strip() for p in parts[1:] if p.strip()]
    elif '/' in symptom_text:
        parts = symptom_text.split('/')
        symptom_text = parts[0].strip()
        aliases = [p.strip() for p in parts[1:] if p.strip()]

    acupoints = parse_acupoints(acupoint_text)
    return {
        'symptom': symptom_text,
        'aliases': aliases,
        'acupoints': acupoints,
        'notes': '',
        'medicalCase': ''
    }

# 逐行解析
i = 0
while i < len(lines):
    line = lines[i].rstrip('\n')
    stripped = line.strip()

    # 跳过空行
    if not stripped:
        i += 1
        continue

    # 杂项：@开头
    if stripped.startswith('@') or stripped.startswith('＠'):
        text = stripped.lstrip('@＠').strip()
        # 去掉末尾冒号和穴位部分
        if '：' in text:
            parts = text.split('：', 1)
            symptom = parts[0].strip()
            acupoint_text = parts[1].strip()
            acupoints = parse_acupoints(acupoint_text)
        else:
            symptom = text
            acupoints = []
        misc_entries.append({
            'id': len(misc_entries) + 1,
            'symptom': symptom,
            'aliases': [],
            'acupoints': acupoints,
            'notes': '',
            'medicalCase': ''
        })
        i += 1
        continue

    # 分类标题：#### XX分类名
    cat_m = re.match(r'^####\s+(\d{2})\s*(.+)$', stripped)
    if cat_m:
        current_cat = {
            'id': cat_m.group(1),
            'name': cat_m.group(2).strip(),
            'entries': []
        }
        categories.append(current_cat)
        i += 1
        continue

    # 编号条目：N. 症状：穴位
    entry_m = re.match(r'^(\d+)\.\s+', stripped)
    if entry_m and current_cat is not None:
        entry = parse_entry_line(stripped)
        if entry:
            entry_id_global += 1
            entry['id'] = entry_id_global
            current_cat['entries'].append(entry)
            # 检查后续行是否有医案（跳过空行）
            j = i + 1
            while j < len(lines):
                next_line = lines[j].strip()
                if not next_line:
                    j += 1
                    continue
                if next_line.startswith('【医案】') or next_line.startswith('【医案】：'):
                    case_text = next_line
                    if next_line.startswith('【医案】：'):
                        case_text = next_line
                    elif next_line.startswith('【医案】'):
                        case_text = next_line
                    # 收集后续行直到遇到下一个编号条目或分类标题
                    k = j + 1
                    while k < len(lines):
                        nl = lines[k].strip()
                        if nl.startswith(('#', '####', '##')) or re.match(r'^\d+\.\s+', nl) or nl.startswith('@') or nl.startswith('＠'):
                            break
                        if nl.startswith('【') and '医案' not in nl:
                            break
                        case_text += '\n' + nl
                        k += 1
                    entry['medicalCase'] = case_text.strip()
                    i = k - 1  # -1 因为外层循环会 i += 1
                    break
                # 如果遇到下一个编号条目或标题，停止
                if next_line.startswith(('#', '####', '##')) or re.match(r'^\d+\.\s+', next_line) or next_line.startswith('@') or next_line.startswith('＠'):
                    break
                # 如果有备注行
                if next_line.startswith('备注') or next_line.startswith('注意'):
                    entry['notes'] = next_line
                    j += 1
                    continue
                # 其他说明文字（非医案）
                if next_line and not next_line.startswith('【'):
                    # 可能是补充说明
                    if entry['notes']:
                        entry['notes'] += '\n' + next_line
                    else:
                        entry['notes'] = next_line
                    j += 1
                    continue
                break
            i += 1
            continue

    i += 1

# 如果有杂项，作为第一个分类
if misc_entries:
    categories.insert(0, {
        'id': '00',
        'name': '杂项',
        'entries': misc_entries
    })

# ── 解析透针透穴 ──
penetrations = []
in_penetration = False
i = 0
while i < len(lines):
    line = lines[i].rstrip('\n')
    stripped = line.strip()

    if '## 31条透针透穴' in stripped:
        in_penetration = True
        i += 1
        continue

    if not in_penetration:
        i += 1
        continue

    # 透穴条目：N. X透Y
    pen_m = re.match(r'^(\d+)\.\s+(.+)$', stripped)
    if pen_m:
        pen_id = int(pen_m.group(1))
        pen_name = pen_m.group(2).strip()
        indications = []
        source = ''
        clinical_insight = ''
        medical_case = ''

        # 收集后续行
        j = i + 1
        section = None
        case_lines = []
        insight_lines = []
        while j < len(lines):
            nl = lines[j].strip()
            if not nl:
                j += 1
                continue
            # 遇到下一个编号条目
            if re.match(r'^\d+\.\s+', nl) and '透' in nl:
                break
            if nl.startswith('治症：') or nl.startswith('治症:'):
                section = 'indication'
                text = nl.split('：', 1)[-1] if '：' in nl else nl.split(':', 1)[-1]
                indications = [x.strip() for x in re.split(r'[、，,]', text) if x.strip()]
                j += 1
                continue
            if nl.startswith('来源：') or nl.startswith('来源:'):
                section = 'source'
                source = nl.split('：', 1)[-1] if '：' in nl else nl.split(':', 1)[-1]
                j += 1
                continue
            if nl.startswith('临证心悟'):
                section = 'insight'
                j += 1
                continue
            if nl.startswith('【医案】') or nl.startswith('此方法常常效验') or nl.startswith('举医案一隅'):
                section = 'case'
                if nl.startswith('【医案】'):
                    case_lines.append(nl)
                elif nl.startswith('此方法常常效验') or nl.startswith('举医案一隅'):
                    case_lines.append(nl)
                j += 1
                continue
            if section == 'case':
                case_lines.append(nl)
            elif section == 'insight':
                insight_lines.append(nl)
            elif section == 'source':
                # 来源可能跨多行
                source += '\n' + nl
            j += 1

        penetrations.append({
            'id': pen_id,
            'name': pen_name,
            'indications': indications,
            'source': source.strip(),
            'clinicalInsight': '\n'.join(insight_lines).strip(),
            'medicalCase': '\n'.join(case_lines).strip()
        })
        i = j
        continue

    i += 1

# ── 输出 ──
output = {
    'acupuncture': {
        'categories': categories
    },
    'penetration': penetrations
}

# 统计
total_entries = sum(len(c['entries']) for c in categories)
print(f"Categories: {len(categories)}")
for c in categories:
    print(f"  {c['id']} {c['name']}: {len(c['entries'])} entries")
print(f"Total acupuncture entries: {total_entries}")
print(f"Total penetration entries: {len(penetrations)}")

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\nWritten to {OUT}")
