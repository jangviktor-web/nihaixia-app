import 'dart:async';

import 'package:flutter/material.dart';

import '../data/reading_progress_repository.dart';

/// 让一个可滚动的阅读页记住上次读到哪，重开 App 后回到原处。
///
/// 接入方式（三步）：
/// 1. `class _XxxState extends State<Xxx> with ReadingProgressMixin`；
/// 2. 把 [readingScroll] 交给 `Markdown(controller: ...)`；
/// 3. 实现 [readingProgressKey]，并在正文加载完成后调用
///    [restoreReadingProgress]；
/// 4. 若页面会重载正文（如切换繁体），重载前 `await beforeReadingReload()`。
///
/// 逻辑集中在这里的原因：过小不存、末尾清除、比例换算、只恢复一次这四个分支
/// 分散到多个页面必然走样，共用一份才改得动。
mixin ReadingProgressMixin<T extends StatefulWidget> on State<T> {
  /// 交给 Markdown / ListView 的滚动控制器。
  final ScrollController readingScroll = ScrollController();

  Timer? _saveTimer;
  bool _restored = false;

  /// 进度存储键：有 asset 用 asset 路径，否则用页面标题。
  String get readingProgressKey;

  @override
  void initState() {
    super.initState();
    readingScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // fire-and-forget：dispose 不能 await，写入失败也只是丢一次进度
    _persistReadingProgress();
    readingScroll.removeListener(_onScroll);
    readingScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer =
        Timer(const Duration(milliseconds: 600), _persistReadingProgress);
  }

  Future<void> _persistReadingProgress() async {
    if (!readingScroll.hasClients) return;
    try {
      await ReadingProgressRepository.save(
        readingProgressKey,
        readingScroll.offset,
        readingScroll.position.maxScrollExtent,
      );
    } catch (_) {
      // 进度是增强功能：写失败只是丢一次位置，绝不能让阅读页报错。
    }
  }

  /// 重载正文前调用：先把当前位置落库并允许重新恢复。
  ///
  /// 不调用的话，重载后内容长度变化、且 `_restored` 仍为 true，页面会停在顶部。
  Future<void> beforeReadingReload() async {
    _saveTimer?.cancel();
    _restored = false;
    await _persistReadingProgress();
  }

  /// 正文加载完成后调用。每个页面实例只自动恢复一次，
  /// 之后用户手动滚走不会被拉回。
  Future<void> restoreReadingProgress() async {
    if (_restored) return;
    _restored = true;
    ReadingProgress? saved;
    try {
      saved = await ReadingProgressRepository.load(readingProgressKey);
    } catch (_) {
      // 数据库不可用（如纯 widget 测试环境）时按「没有记录」处理，
      // 页面照常从顶部开始读。
      return;
    }
    if (saved == null || !mounted) return;
    // 捕获为非空 final：可空局部变量进不了闭包的类型提升
    final progress = saved;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !readingScroll.hasClients) return;
      final max = readingScroll.position.maxScrollExtent;
      readingScroll.jumpTo(progress.resolvedOffset(max).clamp(0.0, max));
      // Markdown 是懒渲染列表：首帧时 maxScrollExtent 只算到已布局部分，
      // 直接按它换算会偏前，故延迟补跳一次。
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted || !readingScroll.hasClients) return;
      final max2 = readingScroll.position.maxScrollExtent;
      final target = progress.resolvedOffset(max2).clamp(0.0, max2);
      if ((readingScroll.offset - target).abs() > 24) {
        readingScroll.jumpTo(target);
      }
    });
  }
}
