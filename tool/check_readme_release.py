#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""发版后 README 自检：把「版本号类改动容易漏哪几处」做成机器校验。

用法（在仓库根执行）：
    python tool/check_readme_release.py 1.11.32 --old 1.11.31
    python tool/check_readme_release.py 1.11.32 --old 1.11.31 --check-links

检查项（任一不过即 exit 1）：
  1. 三份 README 都存在（简 / 繁 / 英）
  2. 旧版本的下载链接残留 = 0        ← 只改标题不改链接的经典事故
  3. 新版本的下载链接各 4 个（4 种架构）
  4. 下载区标题含新版本号
  5. <details> / <summary> 开闭数量配对
  6. 更新日志区出现该版本条目
  7. --check-links：对 4 个直链发 HEAD，要求 200

设计原则：只做确定性检查，不做风格评判；输出直接可读，失败项带修复提示。
"""
import argparse
import io
import os
import re
import subprocess
import sys

ARCH = ['release', 'arm64-v8a-release', 'armeabi-v7a-release', 'x86_64-release']
READMES = ['README.md', 'README.zh-Hant.md', 'README.en.md']


def repo_slug() -> str:
    """从 origin 推断 owner/repo，用于拼下载链接。"""
    try:
        url = subprocess.check_output(['git', 'remote', 'get-url', 'origin'],
                                      text=True).strip()
    except Exception:
        return ''
    m = re.search(r'[:/]([^/:]+/[^/:]+?)(?:\.git)?$', url)
    return m.group(1) if m else ''


def read(p: str) -> str:
    return io.open(p, encoding='utf-8').read()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('version', help='新版本号，如 1.11.32')
    ap.add_argument('--old', help='上一版本号，用于检查残留链接，如 1.11.31')
    ap.add_argument('--check-links', action='store_true',
                    help='对 4 个下载直链发 HEAD，要求 200（需网络）')
    args = ap.parse_args()

    v, old = args.version, args.old
    fails, warns, oks = [], [], []

    def ok(msg):
        oks.append(msg)

    def fail(msg, fix=''):
        fails.append((msg, fix))

    # 1. 文件存在
    for f in READMES:
        if not os.path.exists(f):
            fail(f'{f} 不存在', '确认仓库根目录，或补回该语言版本')
        else:
            ok(f'{f} 存在')

    if not os.path.exists('README.md'):
        return report(oks, warns, fails)

    # 2/3/4/5/6 逐文件
    for f in [x for x in READMES if os.path.exists(x)]:
        s = read(f)

        # 2. 旧链接残留
        if old:
            n_old = s.count(f'/download/v{old}/')
            if n_old:
                fail(f'{f}: 仍有 {n_old} 个下载链接指向 v{old}',
                     f'把 releases/download/v{old}/ 全部替换为 v{v}')
            else:
                ok(f'{f}: 无旧版本链接残留')

        # 3. 新链接数
        n_new = s.count(f'/download/v{v}/')
        if n_new == len(ARCH):
            ok(f'{f}: 新版本下载链接 {n_new}/{len(ARCH)}')
        else:
            missing = [a for a in ARCH
                       if f'/download/v{v}/app-{a}.apk' not in s]
            fail(f'{f}: 新版本下载链接 {n_new}/{len(ARCH)}',
                 f'缺: {", ".join(f"app-{a}.apk" for a in missing) or "检查是否重复"}')

        # 4. 下载区标题（简 / 繁 / 英三种写法都要认）
        if re.search(r'(下载预编译|下載預編譯)\s*APK（V?%s）|Download Prebuilt APK \(V?%s\)'
                     % (re.escape(v), re.escape(v)), s):
            ok(f'{f}: 下载区标题含 V{v}')
        else:
            fail(f'{f}: 下载区标题未更新到 V{v}',
                 '改「方式一：下载预编译 APK（V1.XX.YY）」/ 对应英文标题')

        # 5. 标签配对
        d_open, d_close = s.count('<details'), s.count('</details>')
        s_open, s_close = s.count('<summary'), s.count('</summary>')
        if d_open == d_close and s_open == s_close:
            ok(f'{f}: details/summary 配对（{d_open}/{s_open}）')
        else:
            fail(f'{f}: 标签不配对 details {d_open}/{d_close}, '
                 f'summary {s_open}/{s_close}',
                 '新增折叠块时漏写闭合标签会吞掉后续所有内容')

        # 6. 更新日志条目
        if re.search(r'V?%s' % re.escape(v), s):
            ok(f'{f}: 出现版本条目')
        else:
            fail(f'{f}: 找不到 V{v} 的任何条目', '补更新日志块')

    # 7. 链接可达
    if args.check_links:
        slug = repo_slug()
        if not slug:
            warns.append('无法从 origin 推断仓库，跳过链接检查')
        else:
            for a in ARCH:
                url = (f'https://github.com/{slug}/releases/download/'
                       f'v{v}/app-{a}.apk')
                try:
                    # Windows 下没有 /dev/null，必须用 os.devnull，否则 curl
                    # 直接退出非 0 → check_output 抛异常，全被判成 ERR。
                    code = subprocess.check_output(
                        ['curl', '-sIL', '--max-time', '40', '-o', os.devnull,
                         '-w', '%{http_code}', url], text=True, timeout=60).strip()
                except Exception as e:
                    code = f'ERR({type(e).__name__})'
                if code == '200':
                    ok(f'链接可达 app-{a}.apk')
                else:
                    fail(f'链接返回 {code} app-{a}.apk',
                         '确认 Release 已发布且该架构包已上传')

    return report(oks, warns, fails)


def report(oks, warns, fails) -> int:
    if oks:
        print('✅ 通过：')
        for m in oks:
            print('   -', m)
    if warns:
        print('\n⚠️  提醒：')
        for m in warns:
            print('   -', m)
    if fails:
        print('\n❌ 未通过：')
        for m, fix in fails:
            print('   -', m)
            if fix:
                print('     → 修复：', fix)
        print(f'\n共 {len(fails)} 项未通过。README 不能就这样交差。')
        return 1
    print('\n全部检查通过。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
