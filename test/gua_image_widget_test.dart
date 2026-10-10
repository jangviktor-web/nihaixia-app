import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/yijing_data.dart';
import 'package:nihaisha_app/screens/yijing_detail_screen.dart';

/// 64 卦插画接入的运行时渲染验证。
///
/// 目的：证明卦详情页在运行时确实把 [Image] widget 绑定到了
/// `assets/images/gua/<卦名>.jpg` 这一 AssetImage，而不仅仅是「源码里写了」。
void main() {
  Future<void> pumpHex(WidgetTester tester, Hexagram hex) async {
    await tester.pumpWidget(
      MaterialApp(home: YiJingHexagramDetailScreen(hex: hex)),
    );
    await tester.pump();
  }

  /// 在页面中找到卦象插画 Image，并断言其 image 为指定 asset 的 AssetImage。
  void expectGuaAsset(WidgetTester tester, String name) {
    final finder = find.byType(Image);
    expect(finder, findsOneWidget, reason: '卦详情页应出现且仅出现 1 个 Image（卦象插画）');
    final img = tester.widget<Image>(finder);
    expect(img.image, isA<AssetImage>(), reason: '插画应使用 AssetImage 而非网络图/内存图');
    final asset = img.image as AssetImage;
    expect(asset.assetName, 'assets/images/gua/$name.jpg',
        reason: '运行时绑定的 asset 路径应与卦名一一对应');
  }

  testWidgets('乾为天详情页运行时绑定 gua 插画', (tester) async {
    final hex = kHexagrams.firstWhere((h) => h.name == '乾为天');
    await pumpHex(tester, hex);
    expectGuaAsset(tester, '乾为天');
    expect(tester.takeException(), isNull);
  });

  testWidgets('地天泰详情页运行时绑定 gua 插画', (tester) async {
    final hex = kHexagrams.firstWhere((h) => h.name == '地天泰');
    await pumpHex(tester, hex);
    expectGuaAsset(tester, '地天泰');
    expect(tester.takeException(), isNull);
  });

  testWidgets('缺图时 errorBuilder 兜底为空 SizedBox 且不抛异常', (tester) async {
    const fake = Hexagram(
      seq: 999,
      name: '虚构卦象XYZ',
      upper: 0,
      lower: 0,
      judgement: '',
      lines: ['', '', '', '', '', ''],
      renjian: '',
    );
    // 注入一个「必定加载失败」的 AssetBundle，确定性地触发 errorBuilder。
    // 默认 rootBundle 在 flutter_test 的 fake-async 下资源错误不会同步送达，
    // 会导致 errorBuilder 不被触发，断言前提不成立。
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: _FailingAssetBundle(),
          child: YiJingHexagramDetailScreen(hex: fake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // errorBuilder 返回 const SizedBox.shrink()，插画的渲染子树（RawImage）被替换掉；
    // 若未触发，页面会留下一个 image 为 null 的 RawImage。
    expect(find.byType(RawImage), findsNothing,
        reason: '缺图应由 errorBuilder 收起，而非渲染空白 RawImage');
    // Image 节点本身仍留在 element tree 中，由 errorBuilder 决定其子内容。
    expect(find.byType(Image), findsOneWidget,
        reason: 'Image widget 节点保留，其内容由 errorBuilder 接管');
    expect(tester.takeException(), isNull, reason: '缺图不应把异常冒泡出去');
  });
}

/// 对所有键都抛错的 AssetBundle，用于确定性触发 [Image.errorBuilder]。
class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('asset not found: $key');
  }
}
