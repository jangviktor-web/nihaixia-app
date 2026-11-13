#!/usr/bin/env python
# 把 APK 传到 Gitee 发行版（默认 arm64，可选通用包；幂等补传）。
# 用法：GITEE_TOKEN=xxx python tool/gitee_upload_arm64.py <tag> <arm64_apk> [universal_apk]
# 方案 B：补传 app-release.apk 让 v7a / x86_64 设备也能走 Gitee 备用源。
# 通用包从 GitHub Release 下载时**必须走代理**（直连实测 0 字节超时），见 skill。
import sys, os, json, subprocess

TOKEN = os.environ.get("GITEE_TOKEN")
OWNER = "jangviktor"
REPO = "nihaixia-app"
API = "https://gitee.com/api/v5"
TAG = sys.argv[1]
APK = os.path.abspath(sys.argv[2])  # 绝对路径，避免 Windows 下 curl -F @相对路径解析失败
UNIVERSAL = os.path.abspath(sys.argv[3]) if len(sys.argv) > 3 else None
assert TOKEN, "GITEE_TOKEN 未设置"
assert os.path.exists(APK), f"APK 不存在: {APK}"
assert os.path.basename(APK) == "app-arm64-v8a-release.apk", "arm64 包文件名须规范"
if UNIVERSAL:
    assert os.path.exists(UNIVERSAL), f"通用包不存在: {UNIVERSAL}"
    assert os.path.basename(UNIVERSAL) == "app-release.apk", "通用包文件名须规范"

def curl(method, path, json_data=None, files=None):
    url = f"{API}{path}"
    sep = "?" if "?" not in path else "&"
    url += f"{sep}access_token={TOKEN}"
    cmd = ["curl", "-sS", "-4", "--tcp-nodelay",
           "--retry", "6", "--retry-delay", "5", "--retry-max-time", "3600",
           "--connect-timeout", "30", "--max-time", "3600",
           "-H", "Expect:",   # 禁用 100-continue，避免长连接被中间件挂起导致 0 bytes received
           "-X", method, url]
    if json_data is not None:
        cmd += ["-H", "Content-Type: application/json", "-d", json.dumps(json_data)]
    if files is not None:
        for name, fp in files:
            cmd += ["-F", f"{name}=@{fp}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"curl 失败({method} {path}): {r.stderr}")
    return r.stdout

# 1) 查已有 release（幂等：存在则复用，保留其自动生成的源码归档）
rel = curl("GET", f"/repos/{OWNER}/{REPO}/releases/tags/{TAG}")
try:
    relj = json.loads(rel)
except Exception:
    relj = None

if isinstance(relj, dict) and relj.get("id"):
    cid = relj["id"]
    print(f"==> 复用已有 Gitee release id={cid}（保留其源码归档 zip/tar.gz）")
else:
    # 读取 release notes 作为正文
    notes_path = os.path.join(os.path.dirname(__file__), "..", "release_notes", f"{TAG}.md")
    body = ""
    if os.path.exists(notes_path):
        with open(notes_path, encoding="utf-8") as f:
            body = f.read()
    created = curl("POST", f"/repos/{OWNER}/{REPO}/releases", json_data={
        "tag_name": TAG, "name": f"汉唐中医 {TAG}", "body": body,
        "prerelease": False, "draft": False, "target_commitish": "master",
    })
    print("==> 创建 release 响应:", created[:200])
    cid = json.loads(created).get("id")
    assert cid, f"创建 release 失败: {created}"

# 2) 幂等补传：先读已有附件，缺哪个传哪个（Gitee attach_files 一次一个文件）
cur = json.loads(curl("GET", f"/repos/{OWNER}/{REPO}/releases/tags/{TAG}"))
existing = {a["name"] for a in cur.get("assets", [])}
targets = [(APK, "app-arm64-v8a-release.apk")]
if UNIVERSAL:
    targets.append((UNIVERSAL, "app-release.apk"))
for path, name in targets:
    if name in existing:
        print(f"==> 已存在，跳过 {name}")
        continue
    print(f"==> 上传 {name}: {path}")
    up = curl("POST", f"/repos/{OWNER}/{REPO}/releases/{cid}/attach_files",
              files=[("file", path)])
    print("==> 上传响应:", up[:200])

# 3) 核验：源码 zip/tar.gz 是 Gitee 自动产物，不算 APK 变体
final = curl("GET", f"/repos/{OWNER}/{REPO}/releases/tags/{TAG}")
fj = json.loads(final)
names = [a["name"] for a in fj.get("assets", [])]
apks = [n for n in names if n.endswith(".apk")]
expected = {name for _, name in targets}
print("==> Gitee 全部附件:", names)
if expected.issubset(set(apks)):
    print("✅ 已同步:", sorted(expected))
    print(f"==> https://gitee.com/{OWNER}/{REPO}/releases/tag/{TAG}")
else:
    print("⚠️ 校验未通过：期望", sorted(expected), "实际 APK =", apks)
    sys.exit(1)
