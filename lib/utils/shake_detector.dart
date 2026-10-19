import 'dart:async';

/// 摇一摇检测：外部灌入加速度**模长**流（|a|，静止时约 9.8 m/s²）。
///
/// 判定：连续 [consecutive] 次 ≥ [loudLevel] 记一次摇动；触发后须回落到
/// [quietLevel] 以下才重新武装 —— 一次摇动是一个「高-低」脉冲，靠这个
/// 双水位回差防止一摇连出多卦。不用时钟，行为在测试里完全确定。
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.loudLevel = 13.5,
    this.quietLevel = 11.0,
    this.consecutive = 2,
  });

  final void Function() onShake;
  final double loudLevel;
  final double quietLevel;
  final int consecutive;

  StreamSubscription<double>? _sub;
  bool _armed = true;
  int _hits = 0;

  /// 订阅模长流；重复调用会先取消旧订阅并复位状态。
  void start(Stream<double> magnitudes) {
    stop();
    _armed = true;
    _hits = 0;
    _sub = magnitudes.listen(_onMagnitude);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onMagnitude(double m) {
    if (!_armed) {
      // 未武装：等回落到安静水位再重新上岗。
      if (m < quietLevel) _armed = true;
      return;
    }
    if (m >= loudLevel) {
      if (++_hits >= consecutive) {
        _hits = 0;
        _armed = false;
        onShake();
      }
    } else {
      _hits = 0;
    }
  }
}
