# -*- coding: utf-8 -*-
"""Wiki 更新：新增天纪讲义页；功能总览/命理与民俗/典籍与医案库补充入口。"""
import os
os.chdir(r'C:/Users/jangviktor/AppData/Roaming/WorkDaddy/client-tmp/workbuddy-cn/nihaixia_wiki')

# 1. 新增天纪讲义专页
TIANJI = open(r'C:/Users/jangviktor/AppData/Roaming/WorkDaddy/client-tmp/workbuddy-cn/tianji_wiki_body.md', encoding='utf-8').read()
with open('天纪讲义.md', 'w', encoding='utf-8', newline='\n') as f:
    f.write(TIANJI)
print('天纪讲义.md 已新增')

# 2. sidebar 加入新页（民俗文化域）
p = '_sidebar.md'
s = open(p, encoding='utf-8').read()
if '天纪讲义' not in s:
    s = s.replace('- [命理与民俗模块](命理与民俗模块)',
                  '- [命理与民俗模块](命理与民俗模块)\n- [📖 天纪讲义](天纪讲义)')
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('_sidebar.md 已加天纪讲义')

# 3. 功能总览：民俗域表格加天纪讲义行
p = '功能总览.md'
s = open(p, encoding='utf-8').read()
if '天纪讲义库' not in s:
    marker = '| 四柱命卦 | 先天/后天卦推算（天地数法），附倪师命卦讲义库 |'
    assert marker in s
    s = s.replace(marker, marker + '\n| 天纪讲义库（v1.11.34） | 10 篇 188 节，三层目录（篇 → 节 → 正文）；含《地纪》游记 21 节与 6 张八卦/脏腑盘面配图，全文可搜并接入问倪师AI 检索 |')
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('功能总览.md 已补天纪讲义库')

# 4. 命理与民俗：问倪师AI 段补命理口径与双入口
p = '命理与民俗模块.md'
s = open(p, encoding='utf-8').read()
if '盘面直送问倪师AI' not in s:
    marker = '引擎：`bazi_core`（纯 Dart）。'
    assert marker in s
    add = '''引擎：`bazi_core`（纯 Dart）。

### 问倪师AI · 命理解读入口（v1.11.34）

紫微斗数排盘与八字排盘页右上角新增对话图标，点一下就把当前盘面**连生辰、四化、大限一起**送进「问倪师AI」，提示词已预填「请按倪师天纪的论断思路解读这个命盘」。解读有三个约束：

- **事实分层**：盘面数据单独成块并标注「本地引擎计算」，不与倪师讲义原文混排——避免把排盘结果误当倪师原话；
- **民俗口径**：只讲倾向、不给定论，不作医疗、投资、法律结论；
- **检索相关度**：先从整理讲义 188 节与字幕 74 篇里按多词拆分检索，再按相关度排序喂模型（此前「八字」这类词命中 60/99 篇，等于随机摘录）。

紫微解读的盘面摘要带**当前大限**（宫位 + 主星 + 干支）；解读报告按「命宫格局 → 生年四化落宫 → 当前大限 → 未来十年趋势」组织，底部固定标注 AI 生成、非倪师原话。'''
    s = s.replace(marker, add, 1)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('命理与民俗模块.md 已补 AI 入口')

# 5. 典籍与医案库：补天纪讲义入口
p = '典籍与医案库.md'
s = open(p, encoding='utf-8').read()
if '天纪讲义' not in s:
    marker = '## 4. 黄帝内经'
    assert marker in s
    add = '''## 3.5 倪师天纪讲义（v1.11.34，10 篇 / 188 节）

独立于五套中医文献的民俗文化讲义库：天机道、十二宫详解、星曜详解、手相、相术总结、六神占断论、堪舆风水、风水布局、八煞黄泉，以及新增的**《地纪》游记**（倪师实地走访陕西、汉中、武当山、桂林阳朔的日记 21 节）。

- 三层目录：讲义 → 篇（9 篇按四组分类）→ 节（带搜索与预览）→ 正文；
- 盘面图表化：子午流注钟盘、身相部位图、先天/后天八卦盘、八卦爻象卡，替代原先的 HTML 代码；
- 全文可搜，并并入问倪师AI 的离线检索语料，讲义优先于视频字幕版。

详见 [天纪讲义](天纪讲义)。

'''
    s = s.replace(marker, add + marker, 1)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('典籍与医案库.md 已补天纪讲义')

print('Wiki 更新完成')
