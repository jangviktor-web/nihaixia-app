/// 摇一摇是否可用（编译期常量，tree-shake 得掉）。
///
/// 浏览器里没有可用的加速度计事件（手机浏览器也常被系统手势接管），
/// 桌面同样没有；只有 io 平台（Android / iOS）才有意义。梅花页据此把
/// 「摇一摇」置灰并注明原因，保留「随机起卦」按钮。
const bool kShakeSupported = bool.fromEnvironment('dart.library.io');
