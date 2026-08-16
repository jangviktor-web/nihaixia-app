import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'knowledge_screen.dart';
import 'bookmarks_screen.dart';
import 'tools_screen.dart';
import '../services/update_service.dart';
import '../services/whats_new_service.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final double textScaleFactor;
  const HomeScreen({super.key, this.textScaleFactor = 1.0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 启动后弹出「本次更新了什么」（若有版本更新）
    Future.delayed(
        const Duration(milliseconds: 800), () => WhatsNewService.checkAndShow(context));
    // 延迟检查更新，避免影响启动速度
    Future.delayed(const Duration(seconds: 3), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    if (!mounted) return;
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;

    if (!context.mounted) return;
    final action = await UpdateDialog.show(context, info);
    if (!mounted || action == null) return;

    switch (action) {
      case UpdateAction.ignore:
        await UpdateService.ignoreVersion(info.version);
      case UpdateAction.permanentlyIgnore:
        await UpdateService.permanentlyIgnoreVersion(info.version);
    }
  }

  final List<Widget> _screens = [
    const ChatScreen(),
    const KnowledgeScreen(),
    const ToolsScreen(),
    const BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(widget.textScaleFactor),
      ),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: '辨证',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: '知识库',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: '工具',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: '收藏',
            ),
          ],
        ),
      ),
    );
  }
}
