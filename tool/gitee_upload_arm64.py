#!/usr/bin/env python
# 仅把单个 arm64 APK 传到 Gitee 发行版（不上传其他架构包）。
# 用法：GITEE_TOKEN=xxx python tool/gitee_upload_arm64.py <tag> <apk_path>
import sys, os, json, subprocess

TOKEN = os.environ.get("GITEE_TOKEN")
OWNER = "jangviktor"
REPO = "nihaixia-app"
API = "https://gitee.com/api/v5"
TAG = sys.argv[1]
APK = os.path.abspath(sys.argv[2])  # 绝对路径，避免 Windows 下 curl -F @相对路径解析失败
assert TOKEN, "GITEE_TOKEN 未设置"
assert os.path.exists(APK), f"APK 不存在: {APK}"

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

# 2) 仅上传 arm64
print(f"==> 上传 {APK}")
up = curl("POST", f"/repos/{OWNER}/{REPO}/releases/{cid}/attach_files", files=[("file", APK)])
print("==> 上传响应:", up[:200])

# 3) 核验：仅 arm64 这一个 .apk（源码 zip/tar.gz 是 Gitee 自动产物，非 APK 变体，允许存在）
final = curl("GET", f"/repos/{OWNER}/{REPO}/releases/tags/{TAG}")
fj = json.loads(final)
names = [a["name"] for a in fj.get("assets", [])]
apks = [n for n in names if n.endswith(".apk")]
print("==> Gitee 全部附件:", names)
if "app-arm64-v8a-release.apk" in apks and set(apks) == {"app-arm64-v8a-release.apk"}:
    print("✅ 仅 arm64 已同步完成")
    print(f"==> https://gitee.com/{OWNER}/{REPO}/releases/tag/{TAG}")
else:
    print("⚠️ 校验未通过：APK 附件 =", apks)
    sys.exit(1)
