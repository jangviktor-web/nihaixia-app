#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把当前 tag 同步到 Gitee：推 tag/master + 建或更新发行版 + 上传 APK。

由 .github/workflows/build-apk.yml 在 GitHub Release 发布后调用，使「推 GitHub」
与「Gitee 发行版」自动保持一致，无需手动操作。

必需环境变量
    GITEE_TOKEN      Gitee 私人令牌（头像 → 设置 → 安全设置 → 私人令牌，勾 projects）
可选
    GITEE_OWNER      默认 jangviktor
    GITEE_REPO       默认 nihaixia-app
    APK_DIR          默认 build/app/outputs/flutter-apk（只认下列 4 个固定文件名）
    GITHUB_REF_NAME  CI 自动提供（tag 名，如 v1.11.23）

幂等：已存在的发行版只更新标题/正文；已上传的同名附件跳过。

⛔ 只上传 APK_NAMES 白名单里的文件。不要改成 `*.apk` 通配 —— 构建目录里常残留
   历史/调试 apk（本机实测被通配扫到 4 个无关包，且超过 Gitee 100MB 附件上限）。
"""
import io
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

OWNER = os.environ.get('GITEE_OWNER', 'jangviktor')
REPO = os.environ.get('GITEE_REPO', 'nihaixia-app')
TOK = (os.environ.get('GITEE_TOKEN') or '').strip()
TAG = (os.environ.get('GITHUB_REF_NAME') or '').strip()
APK_DIR = os.environ.get('APK_DIR', 'build/app/outputs/flutter-apk')
APK_NAMES = (
    'app-release.apk',
    'app-arm64-v8a-release.apk',
    'app-armeabi-v7a-release.apk',
    'app-x86_64-release.apk',
)
API = 'https://gitee.com/api/v5'


def log(msg):
    print(msg, flush=True)


if not TOK:
    log('未配置 GITEE_TOKEN —— 跳过 Gitee 同步（如需启用，见文件头注释）')
    sys.exit(0)
if not TAG:
    log('无 GITHUB_REF_NAME（非 tag 触发）—— 跳过 Gitee 同步')
    sys.exit(0)


def api(method, path, payload=None, raw=None, ctype=None, timeout=1800):
    url = API + path + ('&' if '?' in path else '?') + 'access_token=' + urllib.parse.quote(TOK)
    data = raw if raw is not None else (
        json.dumps(payload).encode('utf-8') if payload is not None else None)
    request = urllib.request.Request(url, data=data, method=method)
    request.add_header('Content-Type', ctype or 'application/json;charset=UTF-8')
    with urllib.request.urlopen(request, timeout=timeout) as resp:
        text = resp.read().decode('utf-8')
    return json.loads(text) if text.strip() else {}


# ---------- 1. 推送 tag（与 master 头）到 Gitee（失败不致命：镜像可能已同步） ----------
push_url = 'https://%s:%s@gitee.com/%s/%s.git' % (OWNER, TOK, OWNER, REPO)
for ref in ('refs/tags/%s:refs/tags/%s' % (TAG, TAG), 'HEAD:refs/heads/master'):
    p = subprocess.run(['git', 'push', push_url, ref], capture_output=True, text=True)
    log('git push %-28s rc=%d %s' % (ref, p.returncode, (p.stderr or '').strip()[:240]))

# ---------- 2. 建或更新发行版（正文取自 release_notes/<tag>.md） ----------
body = ''
# CI 会先生成带 SHA-256 校验段的 <tag>.body.md（App 内更新据此按资产名校验下载包）；
# 本地手动补发时若没有该文件，退回不含校验段的 <tag>.md。
note = 'release_notes/%s.body.md' % TAG
if not os.path.isfile(note):
    note = 'release_notes/%s.md' % TAG
if os.path.isfile(note):
    body = io.open(note, encoding='utf-8').read()
    # 图片改走 Gitee 本仓 raw，避免国内访问 jsDelivr 不稳
    body = body.replace(
        'https://cdn.jsdelivr.net/gh/jangviktor-web/nihaixia-app@master/docs/images/',
        'https://gitee.com/%s/%s/raw/master/docs/images/' % (OWNER, REPO))
else:
    log('提示：未找到 %s，发行版正文留空' % note)

rel = None
existing = api('GET', '/repos/%s/%s/releases' % (OWNER, REPO))
for r in (existing if isinstance(existing, list) else []):
    if r.get('tag_name') == TAG:
        rel = r
        break

payload = {'tag_name': TAG, 'name': TAG, 'body': body,
           'target_commitish': 'master', 'prerelease': False, 'draft': False}
if rel:
    rel = api('PATCH', '/repos/%s/%s/releases/%s' % (OWNER, REPO, rel['id']), payload)
    log('已更新现有发行版 id=%s' % rel.get('id'))
else:
    rel = api('POST', '/repos/%s/%s/releases' % (OWNER, REPO), payload)
    log('已创建发行版 id=%s' % rel.get('id'))

rel_id = rel.get('id')


def upload(path, fn):
    with open(path, 'rb') as f:
        content = f.read()
    boundary = ('----giteeupload' + uuid.uuid4().hex).encode()
    data = b''.join([
        b'--' + boundary + b'\r\n',
        ('Content-Disposition: form-data; name="file"; filename="%s"\r\n' % fn).encode('utf-8'),
        b'Content-Type: application/vnd.android.package-archive\r\n\r\n',
        content,
        b'\r\n--' + boundary + b'--\r\n',
    ])
    res = api('POST', '/repos/%s/%s/releases/%s/attach_files' % (OWNER, REPO, rel_id),
              raw=data, ctype='multipart/form-data; boundary=' + boundary.decode())
    return res, len(content)


def attached_names():
    d = api('GET', '/repos/%s/%s/releases/%s' % (OWNER, REPO, rel_id))
    return {a.get('name') for a in (d.get('assets') or [])}


# ---------- 3. 上传 4 个 APK（白名单）；最多两轮，第二轮只补前一轮没挂上的 ----------
for attempt in (1, 2):
    have = attached_names()
    pending = [fn for fn in APK_NAMES
               if os.path.isfile(os.path.join(APK_DIR, fn)) and fn not in have]
    if not pending:
        break
    log('第 %d 轮上传：%s' % (attempt, ', '.join(pending)))
    for fn in pending:
        try:
            res, size = upload(os.path.join(APK_DIR, fn), fn)
            log('  已提交 %-30s (%.1f MB) id=%s' % (fn, size / 1048576.0, res.get('id')))
        except urllib.error.HTTPError as e:
            log('  上传失败 %s HTTP %s %s' % (fn, e.code, e.read().decode('utf-8', 'replace')[:240]))
        except Exception as e:  # noqa: BLE001
            log('  上传失败 %s %s' % (fn, e))

# ---------- 4. 上传后核验：4 个包必须真的挂上 ----------
# 实测坑：Gitee attach_files 会「返回成功但未真正挂载」（本次通用包首发即如此，
# 表现为 API 报成功、下载 URL 404）。故提交后必须回读附件列表核验，不能只信返回值。
have = attached_names()
missing = [fn for fn in APK_NAMES if fn not in have]
if missing:
    log('⛔ 核验未通过，仍缺附件：%s' % ', '.join(missing))
else:
    log('✅ 核验通过：4 个 APK 均已挂载')

log('Gitee 同步完成：https://gitee.com/%s/%s/releases/tag/%s（缺失 %d）' % (
    OWNER, REPO, TAG, len(missing)))
sys.exit(1 if missing else 0)
