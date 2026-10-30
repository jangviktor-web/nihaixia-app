import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/acupuncture_repository.dart';
import 'data/acupoint_repository.dart';
import 'data/changelog_repository.dart';
import 'data/formula_oral_hint_repository.dart';
import 'data/formula_repository.dart';
import 'data/herb_repository.dart';
import 'data/settings_repository.dart';
import 'data/ziwei_rules_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FormulaRepository.load();
  await FormulaOralHintRepository.load();
  await HerbRepository.load();
  await AcupunctureRepository.load();
  await AcupointRepository.load();
  await ChangelogRepository.load();
  await SettingsRepository.instance.load();
  // 紫微解读层外置规则；加载失败会在仓库内部静默降级为内建默认值，不影响启动。
  await ZiweiRulesRepository.load();
  runApp(const NiHaishaApp());
}

class NiHaishaApp extends StatelessWidget {
  const NiHaishaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsRepository.instance,
      builder: (context, _) {
        final settings = SettingsRepository.instance;
        return MaterialApp(
          title: '汉唐中医',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            // ⛔ 关闭 Zoom 转场快照：快照机制会在设备动画缩放异常/手势取消时
            // 把进场页冻结在半透明帧（子午流注屏「打开模糊一大片」根因）。
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(
                  allowSnapshotting: false,
                  allowEnterRouteSnapshotting: false,
                ),
              },
            ),
            extensions: [AppColors.light],
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(
                  allowSnapshotting: false,
                  allowEnterRouteSnapshotting: false,
                ),
              },
            ),
            extensions: [AppColors.dark],
          ),
          home: HomeScreen(textScaleFactor: settings.textScaleFactor),
          // 字号缩放必须放在 builder（包住整个 Navigator）：只包 home 的话，
          // push 出去的详情页/设置页和弹窗都拿不到用户字号，调到 200% 也只有
          // 首页四个 tab 变大（issue #4 相关反馈的根因）。
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.textScaleFactor),
            ),
            child: child!,
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh', 'CN'),
        );
      },
    );
  }
}
