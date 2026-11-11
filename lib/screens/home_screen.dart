import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'knowledge_screen.dart';
import 'bookmarks_screen.dart';
import 'tools_screen.dart';
import '../services/update_service.dart';
import '../services/whats_new_service.dart';
import '../utils/responsive.dart';
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
      const Duration(milliseconds: 800),
      () {
        if (mounted) WhatsNewService.checkAndShow(context);
      },
    );
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
    const KnowledgeScreen(),
    const ToolsScreen(),
    const ChatScreen(),
    const BookmarksScreen(),
  ];

  static const _destinations = <_Dest>[
    _Dest(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: '知识库',
    ),
    _Dest(icon: Icons.build_outlined, selectedIcon: Icons.build, label: '工具'),
    _Dest(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: '辨证',
    ),
    _Dest(
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      label: '收藏',
    ),
  ];

  void _select(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 宽屏（电脑浏览器 / 平板横屏）改用左侧常驻导航：底部导航在 1000dp 以上的
    // 窗口里既远又空，且会把整个内容区挤成一条竖长条。
    final useSideNav = context.useSideNav;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.textScaleFactor)),
      child: Scaffold(
        // IndexedStack 常驻各 Tab，切换后保留问诊/搜索等页面 State（如聊天进度、滚动位置）
        body: useSideNav
            ? Row(
                children: [
                  _SideNav(
                    destinations: _destinations,
                    selectedIndex: _currentIndex,
                    onSelected: _select,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    ),
                  ),
                ],
              )
            : IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: useSideNav
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _select,
                destinations: const [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
      ),
    );
  }
}

/// 单个导航项（底部 NavigationBar 与侧边栏共用一份配置，避免两处文案走样）。
class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Dest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 桌面侧边导航栏：固定在左侧，选中项用主色药丸高亮。
class _SideNav extends StatelessWidget {
  final List<_Dest> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      color: cs.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.local_hospital, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '汉唐中医',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              _SideNavItem(
                dest: destinations[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '纯离线 · 仅供学习参考',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? cs.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? dest.selectedIcon : dest.icon,
                  size: 22,
                  color: fg,
                ),
                const SizedBox(width: 14),
                Text(
                  dest.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: fg,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
