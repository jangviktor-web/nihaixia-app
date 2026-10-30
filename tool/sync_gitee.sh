#!/usr/bin/env bash
# 把 GitHub Release（含 4 个 APK）同步到 Gitee 发行版。
#
# 为什么不在 GitHub Actions 里做：runner 到 Gitee 的 attach_files 上传会挂死
# （900s 收到 0 字节 / release2gitee 60s 超时），而 API 读写在 runner 上是通的。
# 本脚本在**国内本机**跑，用 hepengju/release2gitee 完成「建发行版 + 传 4 个 APK」。
#
# 用法（Git Bash）：
#   export GITEE_TOKEN=xxxx        # Gitee → 设置 → 私人令牌，勾 projects
#   bash tool/sync_gitee.sh        # 默认同步最新 Release
#   bash tool/sync_gitee.sh v1.11.28
#
# 也可把 GITEE_TOKEN=... 写进 tool/.gitee.env（已 gitignore），脚本会自动读取。
# 访问 GitHub 需要代理时：HTTPS_PROXY=http://127.0.0.1:7890 bash tool/sync_gitee.sh
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f tool/.gitee.env ] && . tool/.gitee.env
: "${GITEE_TOKEN:?先 export GITEE_TOKEN=...（或写进 tool/.gitee.env）}"

GH_OWNER=jangviktor-web
GH_REPO=nihaixia-app
GITEE_OWNER=${GITEE_OWNER:-jangviktor}
GITEE_REPO=${GITEE_REPO:-nihaixia-app}
API=https://gitee.com/api/v5

if [ -x "D:/Python310/python.exe" ]; then PY="D:/Python310/python.exe"; else PY=python; fi

TAG="${1:-}"
[ -n "$TAG" ] || TAG=$(gh release view --repo "$GH_OWNER/$GH_REPO" --json tagName -q .tagName)
echo "==> 目标 tag：$TAG"

# 1) 同名发行版若附件不足 4 个（空壳/半残），先删掉，让 release2gitee 重建并上传
REL=$(curl -s "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/tags/$TAG?access_token=$GITEE_TOKEN" || true)
ID=$(printf '%s' "$REL" | "$PY" -c "import sys,json
try: print(json.load(sys.stdin).get('id') or '')
except Exception: print('')")
if [ -n "$ID" ]; then
  N=$(printf '%s' "$REL" | "$PY" -c "import sys,json
d=json.load(sys.stdin)
print(sum(1 for a in d.get('assets',[]) if '/releases/download/' in a.get('browser_download_url','')))")
  echo "==> Gitee 已有发行版 id=$ID，已挂 APK 数=$N"
  if [ "$N" -lt 4 ]; then
    curl -s -X DELETE "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/$ID?access_token=$GITEE_TOKEN" >/dev/null
    echo "==> 附件不足，已删除，稍后重建"
  else
    echo "==> 4 个 APK 已在，无需重复上传"
    exit 0
  fi
fi

# 2) 准备 release2gitee（Windows 版，缓存在 tool/.bin）
BIN_DIR=tool/.bin
BIN="$BIN_DIR/release2gitee.exe"
mkdir -p "$BIN_DIR"
if [ ! -f "$BIN" ]; then
  echo "==> 下载 release2gitee v1.2.2"
  gh release download v1.2.2 -R hepengju/release2gitee -p '*windows*' -D "$BIN_DIR" --clobber
  "$PY" -c "import glob,zipfile; zipfile.ZipFile(glob.glob('$BIN_DIR/*.zip')[0]).extractall('$BIN_DIR')"
fi

# 3) 同步（999 = 不清理历史版本的附件）
export GITHUB_OWNER=$GH_OWNER GITHUB_REPO=$GH_REPO
export GITEE_OWNER GITEE_REPO GITEE_TOKEN
export release2gitee__github_latest_release_count=3
export release2gitee__gitee_retain_release_attach_files_count=999
export release2gitee__release_body_url_replace=true
"$BIN"

# 4) 核验
FINAL=$(curl -s "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/tags/$TAG?access_token=$GITEE_TOKEN")
printf '%s' "$FINAL" | "$PY" -c "import sys,json
d=json.load(sys.stdin)
names={a['name'] for a in d.get('assets',[]) if '/releases/download/' in a.get('browser_download_url','')}
need={'app-release.apk','app-arm64-v8a-release.apk','app-armeabi-v7a-release.apk','app-x86_64-release.apk'}
print('==> Gitee 附件：', sorted(names))
missing=need-names
if missing:
    print('缺少：', sorted(missing)); sys.exit(1)
print('✅ 4 个 APK 已同步完成')
"
echo "==> https://gitee.com/$GITEE_OWNER/$GITEE_REPO/releases/tag/$TAG"
