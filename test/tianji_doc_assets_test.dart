import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/tianji_doc_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('天纪讲义：列表里的每个资产都能加载，且无残留图片引用', () async {
    expect(TianjiDocListScreen.docs, isNotEmpty);
    for (final (_, title, __, asset) in TianjiDocListScreen.docs) {
      final text = await rootBundle.loadString(asset);
      expect(text.trim(), isNotEmpty, reason: '$title（$asset）内容为空');
      expect(text.contains('!['), isFalse, reason: '$title（$asset）残留图片引用');
    }
  });
}
