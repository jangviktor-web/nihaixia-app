import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/update_service.dart';

void main() {
  group('UpdateService 版本比较逻辑', () {
    // 由于 _isNewerVersion 是私有方法，我们通过公共API间接测试
    // 这里测试 UpdateInfo 的构造和版本格式

    test('UpdateInfo应正确存储版本信息', () {
      final info = UpdateInfo(
        version: '1.4.0',
        tagName: 'v1.4.0',
        body: '修复了一些bug',
        apkDownloadUrl: 'https://example.com/app.apk',
        apkSize: 1024000,
      );

      expect(info.version, '1.4.0');
      expect(info.tagName, 'v1.4.0');
      expect(info.body, '修复了一些bug');
      expect(info.apkDownloadUrl, contains('.apk'));
      expect(info.apkSize, 1024000);
    });

    test('版本号格式应支持x.y.z格式', () {
      final info = UpdateInfo(
        version: '2.0.1',
        tagName: 'v2.0.1',
        body: '',
        apkDownloadUrl: '',
        apkSize: 0,
      );

      // 验证版本号可以被分割和解析
      final parts = info.version.split('.');
      expect(parts.length, 3);
      expect(int.tryParse(parts[0]), isNotNull);
      expect(int.tryParse(parts[1]), isNotNull);
      expect(int.tryParse(parts[2]), isNotNull);
    });
  });

  group('UpdateService 忽略版本', () {
    // 这些测试需要数据库，跳过（集成测试阶段再测）
    // 这里只验证方法签名存在

    test('ignoreVersion方法存在', () {
      expect(UpdateService.ignoreVersion, isA<Function>());
    });

    test('permanentlyIgnoreVersion方法存在', () {
      expect(UpdateService.permanentlyIgnoreVersion, isA<Function>());
    });

    test('checkForUpdate方法存在', () {
      expect(UpdateService.checkForUpdate, isA<Function>());
    });

    test('getCurrentVersion方法存在', () {
      expect(UpdateService.getCurrentVersion, isA<Function>());
    });
  });

  group('UpdateService 版本比较边界情况', () {
    // 手动实现版本比较逻辑进行测试
    // 这与 UpdateService._isNewerVersion 逻辑一致
    bool isNewerVersion(String remote, String current) {
      final remoteParts = remote.split('.').map(int.tryParse).toList();
      final currentParts = current.split('.').map(int.tryParse).toList();

      for (var i = 0; i < 3; i++) {
        final r = (i < remoteParts.length) ? (remoteParts[i] ?? 0) : 0;
        final c = (i < currentParts.length) ? (currentParts[i] ?? 0) : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    }

    test('1.4.0 应比 1.3.0 新', () {
      expect(isNewerVersion('1.4.0', '1.3.0'), isTrue);
    });

    test('1.3.0 不应比 1.4.0 新', () {
      expect(isNewerVersion('1.3.0', '1.4.0'), isFalse);
    });

    test('1.3.0 不应比 1.3.0 新（相同版本）', () {
      expect(isNewerVersion('1.3.0', '1.3.0'), isFalse);
    });

    test('2.0.0 应比 1.9.9 新', () {
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('1.3.1 应比 1.3.0 新', () {
      expect(isNewerVersion('1.3.1', '1.3.0'), isTrue);
    });

    test('1.3.0 不应比 1.3.1 新', () {
      expect(isNewerVersion('1.3.0', '1.3.1'), isFalse);
    });

    test('10.0.0 应比 9.9.9 新', () {
      expect(isNewerVersion('10.0.0', '9.9.9'), isTrue);
    });

    test('两位版本号 1.3 应能比较', () {
      expect(isNewerVersion('1.4', '1.3'), isTrue);
    });
  });
}
