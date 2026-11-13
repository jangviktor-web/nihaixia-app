import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/update_service.dart';

/// 回归：更新下载的「多源 + 主机白名单 + 按资产名选包 + SHA-256 校验」。
///
/// 背景：主源 GitHub，备用源 Gitee（本项目镜像仓，官方）；可选的第三方加速代理
/// ghproxy.net 属于第三方中继，**默认不放行**，只有在设置里显式开启
/// 「更新镜像加速」后才允许（allowMirror: true）。
void main() {
  test('放行：本项目 GitHub 官方资产主机', () {
    expect(
        UpdateService.isTrustedDownloadHost(
            'https://github.com/jangviktor-web/nihaixia-app/releases/download/v1.11.23/app-arm64-v8a-release.apk'),
        isTrue);
    expect(
        UpdateService.isTrustedDownloadHost(
            'https://objects.githubusercontent.com/foo/bar'),
        isTrue);
  });

  test('放行：本项目 Gitee 发行版备用主机', () {
    expect(
        UpdateService.isTrustedDownloadHost(
            'https://gitee.com/jangviktor/nihaixia-app/releases/download/v1.11.23/app-arm64-v8a-release.apk'),
        isTrue);
    // Gitee 下载 302 到 foruda.gitee.com
    expect(
        UpdateService.isTrustedDownloadHost(
            'https://foruda.gitee.com/attach_file/123/app-release.apk?token=x'),
        isTrue);
  });

  test('第三方代理 ghproxy：默认拒绝，显式开启后才放行', () {
    const mirror =
        'https://ghproxy.net/https://github.com/jangviktor-web/nihaixia-app/releases/download/v1.11.23/app-arm64-v8a-release.apk';
    expect(UpdateService.isTrustedDownloadHost(mirror), isFalse);
    expect(UpdateService.isTrustedDownloadHost(mirror, allowMirror: true), isTrue);
  });

  test('拒绝：第三方域名 / 仿冒域名 / 空值 / 非 URL', () {
    expect(UpdateService.isTrustedDownloadHost('https://evil.com/x.apk'), isFalse);
    expect(
        UpdateService.isTrustedDownloadHost('https://gitee.com.evil.com/x.apk'),
        isFalse);
    expect(
        UpdateService.isTrustedDownloadHost('https://notghproxy.net/x.apk',
            allowMirror: true),
        isFalse);
    expect(
        UpdateService.isTrustedDownloadHost('https://ghproxy.net.evil.com/x',
            allowMirror: true),
        isFalse);
    expect(UpdateService.isTrustedDownloadHost('not a url'), isFalse);
  });

  // ---------------- 按资产名选包 ----------------

  const allFour = [
    'app-arm64-v8a-release.apk',
    'app-armeabi-v7a-release.apk',
    'app-x86_64-release.apk',
    'app-release.apk',
  ];

  test('选包：优先本机 ABI 分架构包，通用包兜底（须是发布里真实存在的名字）', () {
    final picked = UpdateService.pickApkAssetName(allFour);
    expect(picked, isNotNull);
    expect(allFour, contains(picked));

    final pref = UpdateService.preferredApkAssetNames();
    expect(pref.last, 'app-release.apk'); // 通用包永远是最后兜底
    if (pref.length > 1) {
      expect(picked, pref.first); // 有本机 ABI 对应的包就选它
    } else {
      expect(picked, 'app-release.apk'); // 非 Android（测试/桌面）只剩通用包
    }
  });

  test('选包：有匹配 ABI 包就选中；无匹配则 null（不把 arm64 发给别的 ABI）', () {
    // 模拟 arm64 设备
    expect(
        UpdateService.pickApkAssetName(allFour,
            preferred: const [
              'app-arm64-v8a-release.apk',
              'app-release.apk'
            ]),
        'app-arm64-v8a-release.apk');
    // 模拟 v7a 设备，资产里只有 arm64（Gitee 现状）→ 诚实跳过，不发错包
    expect(
        UpdateService.pickApkAssetName(
            const ['app-arm64-v8a-release.apk'],
            preferred: const [
              'app-armeabi-v7a-release.apk',
              'app-release.apk'
            ]),
        isNull);
    // 通用包兜底仍有效
    expect(
        UpdateService.pickApkAssetName(const ['app-release.apk'],
            preferred: const [
              'app-arm64-v8a-release.apk',
              'app-release.apk'
            ]),
        'app-release.apk');
  });

  test('选包：legacy 单包 / 空 / 只有源码归档 → null', () {
    // 旧行为是「退回第一个 apk」，会让非 arm64 设备装错包，已改为放弃更新。
    expect(UpdateService.pickApkAssetName(const ['legacy-release.apk']), isNull);
    expect(UpdateService.pickApkAssetName(const []), isNull);
    expect(
        UpdateService.pickApkAssetName(
            const ['v1.11.23.zip', 'v1.11.23.tar.gz']),
        isNull);
  });

  test('备用源：Gitee 放行 arm64 + 通用包，v7a/x86_64 拒绝；GitHub 全放行', () {
    const gh =
        'https://github.com/jangviktor-web/nihaixia-app/releases/download';
    const gitee =
        'https://gitee.com/jangviktor/nihaixia-app/releases/download';
    expect(
        UpdateService.fallbackApkUrl(
            gitee, 'v1.11.32', 'app-arm64-v8a-release.apk'),
        '$gitee/v1.11.32/app-arm64-v8a-release.apk');
    // 方案 B 起 Gitee 补传通用包，非 arm64 设备也能走 Gitee 备用源
    expect(
        UpdateService.fallbackApkUrl(gitee, 'v1.11.32', 'app-release.apk'),
        '$gitee/v1.11.32/app-release.apk');
    for (final n in const [
      'app-armeabi-v7a-release.apk',
      'app-x86_64-release.apk'
    ]) {
      expect(UpdateService.fallbackApkUrl(gitee, 'v1.11.32', n), isNull,
          reason: '$n 在 Gitee 上实测 404，不该生成备用链接');
    }
    expect(
        UpdateService.fallbackApkUrl(
            gh, 'v1.11.32', 'app-armeabi-v7a-release.apk'),
        '$gh/v1.11.32/app-armeabi-v7a-release.apk');
    expect(UpdateService.fallbackApkUrl('', 'v1.11.32', 'app-release.apk'),
        isNull);
  });

  // ---------------- SHA-256 解析 ----------------

  const hexA =
      '4ec0f5fc73f03fe5107ac70d3b077c0a0026b2190850b96b9a0f964f34acd7ef';
  const hexB =
      '74059c79909d4d5e94b38a422af905b0f15d84db1363eb8fada124032dd055b5';

  final sampleBody = '# 汉唐中医 v1.11.23 发布说明\n\n'
      '正文里可能出现 64 位十六进制串 $hexA 但后面没跟文件名，不应被当成配对。\n\n'
      '---\n\n## 安装包 SHA-256（供 App 内更新校验）\n\n'
      '```\n'
      '$hexA  app-arm64-v8a-release.apk\n'
      '$hexB  app-x86_64-release.apk\n'
      '```\n';

  test('解析正文里的「资产名 → SHA-256」表', () {
    final m = UpdateService.parseAssetHashes(sampleBody);
    expect(m.length, 2, reason: '只认「哈希 + 文件名」成对的行');
    expect(m['app-arm64-v8a-release.apk'], hexA);
    expect(m['app-x86_64-release.apk'], hexB);
    expect(m.containsKey('app-release.apk'), isFalse); // 没列出的包不造假值
  });

  test('老的「单个 SHA256: <hex>」无文件名，不再采用（避免配错包）', () {
    expect(UpdateService.parseAssetHashes('SHA256: $hexA').isEmpty, isTrue);
  });

  test('选中的包能查到对应哈希；未列出的包查不到（=> 仅做体积校验）', () {
    final m = UpdateService.parseAssetHashes(sampleBody);
    final picked = UpdateService.pickApkAssetName(
        const ['app-arm64-v8a-release.apk', 'app-x86_64-release.apk'],
        preferred: const ['app-arm64-v8a-release.apk', 'app-release.apk']);
    expect(picked, isNotNull);
    expect(m[picked!.toLowerCase()], isNotNull);
    expect(m['app-armeabi-v7a-release.apk'], isNull);
  });
}
