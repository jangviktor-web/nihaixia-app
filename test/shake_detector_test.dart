import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/utils/shake_detector.dart';

void main() {
  // sync 控制器：事件同步送达，断言不需要 pump。
  StreamController<double> ctrl() => StreamController<double>(sync: true);

  test('连续 2 次超阈值 → 触发一次', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    c.add(9.8);
    c.add(14.0);
    c.add(14.2);
    expect(fires, 1);
  });

  test('单次尖峰不触发（抗噪）', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    c.add(15.0);
    c.add(9.8);
    c.add(15.0);
    c.add(9.8);
    expect(fires, 0);
  });

  test('一次摇动不连发：触发后持续高位不重复触发', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    c.add(14.0);
    c.add(14.0);
    expect(fires, 1);
    c.add(16.0);
    c.add(18.0);
    c.add(20.0);
    expect(fires, 1);
  });

  test('回落到安静水位后重新武装，可再次触发', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    c.add(14.0);
    c.add(14.0);
    c.add(9.8); // 回落
    c.add(14.0);
    c.add(14.0);
    expect(fires, 2);
  });

  test('边缘值：恰在 loudLevel 触发，低于则不触发', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    c.add(13.4);
    c.add(13.49);
    expect(fires, 0);
    c.add(13.5); // >= loudLevel
    c.add(13.5);
    expect(fires, 1);
  });

  test('stop 后事件不再触发；start 复位状态', () {
    // broadcast：单订阅流只能 listen 一次，而真实场景每次 start 拿的是新流。
    final c = StreamController<double>.broadcast(sync: true);
    addTearDown(c.close);
    var fires = 0;
    final d = ShakeDetector(onShake: () => fires++);
    d.start(c.stream);
    c.add(14.0);
    d.stop();
    c.add(14.0);
    expect(fires, 0);

    // 重启后从干净状态开始（_hits 已清零，不会差一次就触发）
    d.start(c.stream);
    c.add(14.0);
    expect(fires, 0);
    c.add(14.0);
    expect(fires, 1);
  });

  test('缓慢倾斜不触发：模长恒为重力（|a| 与朝向无关）', () {
    final c = ctrl();
    addTearDown(c.close);
    var fires = 0;
    ShakeDetector(onShake: () => fires++).start(c.stream);
    // 手机从竖直到平放，模长始终 ≈ 9.8，只是方向变了。
    for (var i = 0; i < 200; i++) {
      c.add(9.8 + (i.isEven ? 0.3 : -0.3));
    }
    expect(fires, 0);
  });
}
