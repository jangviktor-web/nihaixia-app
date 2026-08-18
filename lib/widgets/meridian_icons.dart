import 'package:flutter/material.dart';

/// 六经 → Material 图标 的 UI 层映射（替代历史 emoji 标记，P0-1 根治）。
/// 设计师 Token/图标方案落地后如需调整，只需改此一处，勿在页面内各自写映射。
IconData meridianIcon(String meridian) {
  switch (meridian) {
    case '太阳':
      return Icons.wb_sunny;
    case '阳明':
      return Icons.local_fire_department;
    case '少阳':
      return Icons.wb_twilight;
    case '太阴':
      return Icons.bedtime;
    case '少阴':
      return Icons.nightlight;
    case '厥阴':
      return Icons.balance;
    default:
      return Icons.local_hospital;
  }
}
