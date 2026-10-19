import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 排盘结果「存图 / 分享长图」。
///
/// ## 为什么不引 `screenshot` 包
/// 本库已有 [path_provider] 与 [share_plus]，一张长图 = 全量布局 + 截 layer +
/// 分享面板，几十行覆盖，不值得为一个功能加依赖。
///
/// ## 为什么截图副本要套 `OverflowBox(maxHeight: infinity)`
/// 长内容若放在 `ListView` / `SingleChildScrollView` 里，超出视口的部分**不会被
/// paint**，直接 `RepaintBoundary.toImage()` 只能截到可见区域（实测截出 85px
/// 宽的窄片）。`OverflowBox` 给子节点放开高度约束，内容按自然高度全量布局，
/// 超出视口的部分照样进 boundary 的 layer，长图才完整。
///
/// ⚠️ 别改成「把截图节点挪到屏幕外（如 `left: -100000`）」图省事——根视图绘制
/// 边界之外的 layer 会被光栅器裁掉，boundary 永不被 paint，`toImage()` 会一直
/// 挂着不返回（实测 10 分钟超时）。必须留在树内、留在视口坐标系内。
class ChartExport {
  ChartExport._();

  /// 截 [key] 处的 RepaintBoundary 为 PNG；失败返回 null。
  static Future<Uint8List?> capturePng(GlobalKey key,
      {double pixelRatio = 2.0}) async {
    final ro = key.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    try {
      var pr = pixelRatio;
      // 长图按高度降采样，单边不超 8000px（GPU 纹理上限，超出会截空/崩）。
      if (ro.size.height * pr > 8000) {
        pr = (8000 / ro.size.height).clamp(1.0, pixelRatio);
      }
      final img = await ro.toImage(pixelRatio: pr);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final bytes = data?.buffer.asUint8List();
      return (bytes != null && bytes.length > 1024) ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  /// 调起系统分享面板（面板自带「存到相册 / 存到文件 / 微信」等出口）。
  static Future<void> sharePng(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(f.path, mimeType: 'image/png')],
      subject: '汉唐中医',
    );
  }

  /// 存到 App 外部专属目录（无需存储权限），返回路径。
  static Future<String> savePng(Uint8List bytes, String filename) async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }
}

/// 长图页面：上层可滚动查看，底层全量布局供截图。
///
/// 用法：
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => ChartExportPage(
///   title: '八字排盘',
///   filename: 'bazi_20261018.png',
///   content: _buildExportContent(),
/// )));
/// ```
/// [content] 须是能自持布局的 widget（Column 等），**不要传 ListView**。
class ChartExportPage extends StatefulWidget {
  const ChartExportPage({
    super.key,
    required this.title,
    required this.filename,
    required this.content,
  });

  final String title;

  /// 导出文件名（如 `bazi_20261018.png`）。
  final String filename;

  /// 要导出成图的内容。
  final Widget content;

  @override
  State<ChartExportPage> createState() => _ChartExportPageState();
}

class _ChartExportPageState extends State<ChartExportPage> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  Future<void> _run(bool share) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await ChartExport.capturePng(_captureKey);
      if (bytes == null) {
        messenger.showSnackBar(const SnackBar(content: Text('生成图片失败，请重试')));
        return;
      }
      if (share) {
        await ChartExport.sharePng(bytes, widget.filename);
      } else {
        final path = await ChartExport.savePng(bytes, widget.filename);
        messenger.showSnackBar(SnackBar(content: Text('已保存：$path')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 底层：全量布局的截图副本。
          // ⚠️ OverflowBox 放开的溢出部分必须裁在视口内：2026-10-19 真机截图发现，
          // 溢出内容会画到底部按钮带上去——「三阶段推演」标题从半透明的「保存图片」
          // 轮廓钮后面漏出来、被「分享长图」实心钮截断（Stack 自身裁剪没兜住）。
          // ClipRect 包在 RepaintBoundary【外层】：只管视觉裁剪，capturePng 照旧
          // 拿得到全量布局（toImage 截的是 boundary 自己的 layer，不含祖先裁剪）。
          Positioned.fill(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  maxHeight: double.infinity,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: Material(
                        color: Colors.white,
                        child: DefaultTextStyle(
                          style: const TextStyle(color: Color(0xFF1F1B16)),
                          child: widget.content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 上层：不透明查看层，盖住截图副本，用户看到的是可滚动的正常页面
          Positioned.fill(
            child: Material(
              color: cs.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
      // 底钮给不透明背景：Row 本身是透明的，万一还有图层从视口漏出来，
      // 也穿不过这道底（Scaffold 先画 body 后画 bottomNavigationBar）。
      bottomNavigationBar: Material(
        color: cs.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(false),
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('保存图片'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _run(true),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('分享长图'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
