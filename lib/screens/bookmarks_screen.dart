import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:flutter/services.dart';
import '../models/bookmark.dart';
import '../data/database_helper.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../screens/formula_detail_screen.dart';
import '../screens/herb_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  List<Map<String, dynamic>> _folders = [];
  String? _selectedCategory;
  int? _selectedFolderId;
  String _viewMode = 'all'; // all | folder

  @override
  void initState() {
    super.initState();
    DatabaseHelper.bookmarkVersion.addListener(_onBookmarkChanged);
    _loadData();
  }

  @override
  void dispose() {
    DatabaseHelper.bookmarkVersion.removeListener(_onBookmarkChanged);
    super.dispose();
  }

  void _onBookmarkChanged() {
    if (mounted) _loadData();
  }

  void _loadData() async {
    final db = DatabaseHelper.instance;
    final folders = await db.getAllFolders();
    List<Bookmark> bookmarks;
    if (_selectedFolderId != null) {
      final rows = await db.getBookmarksWithFolder();
      bookmarks = rows
          .where((r) => r['folder_id'] == _selectedFolderId)
          .map((json) => Bookmark.fromJson(json))
          .toList();
    } else if (_selectedCategory != null) {
      bookmarks = await db.getBookmarksByCategory(_selectedCategory!);
    } else {
      bookmarks = await db.getAllBookmarks();
    }
    setState(() {
      _folders = folders;
      _bookmarks = bookmarks;
    });
  }

  void _deleteBookmark(int id) async {
    final db = DatabaseHelper.instance;
    await db.deleteBookmark(id);
    _loadData();
  }

  /// 点击收藏项：优先跳转到对应条目的详情页（方剂→方剂介绍页，药物→药物页）。
  /// 若按名称查不到对应条目（如名称变更），则回退为原始文本展示。
  void _openBookmark(Bookmark b) {
    if (b.category == '方剂') {
      final formula = FormulaRepository.getByName(b.title);
      if (formula != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormulaDetailScreen(formula: formula)),
        );
        return;
      }
    } else if (b.category == '本草') {
      final herb = HerbRepository.getByName(b.title);
      if (herb != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HerbDetailScreen(herb: herb)),
        );
        return;
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(b.title),
        content: SingleChildScrollView(child: Text(b.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ==================== 文件夹管理 ====================

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入文件夹名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await DatabaseHelper.instance.insertFolder(controller.text.trim());
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(int folderId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除文件夹'),
        content: Text('确定删除文件夹「$name」吗？\n文件夹内的收藏将被移出，不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteFolder(folderId);
              Navigator.pop(ctx);
              if (_selectedFolderId == folderId) {
                _selectedFolderId = null;
              }
              _loadData();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(Bookmark bookmark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('移动到文件夹', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off),
              title: const Text('移出文件夹'),
              onTap: () async {
                await DatabaseHelper.instance.moveBookmarkToFolder(bookmark.id!, null);
                Navigator.pop(ctx);
                _loadData();
              },
            ),
            ..._folders.map((f) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(f['name']),
                  onTap: () async {
                    await DatabaseHelper.instance.moveBookmarkToFolder(
                        bookmark.id!, f['id']);
                    Navigator.pop(ctx);
                    _loadData();
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==================== 导出 ====================

  void _exportBookmarks() async {
    final db = DatabaseHelper.instance;
    final data = await db.exportBookmarks();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('收藏数据已复制到剪贴板（JSON格式）')),
      );
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final categories = _bookmarks.map((b) => b.category).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') _exportBookmarks();
              if (value == 'new_folder') _showCreateFolderDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_folder',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder, size: 20),
                    SizedBox(width: 8),
                    Text('新建文件夹'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('导出收藏'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 文件夹列表
          if (_folders.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('全部'),
                      selected: _selectedFolderId == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedFolderId = null;
                          _viewMode = 'all';
                        });
                        _loadData();
                      },
                    ),
                  ),
                  ..._folders.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onLongPress: () =>
                              _showDeleteFolderDialog(f['id'], f['name']),
                          child: FilterChip(
                            avatar: const Icon(Icons.folder, size: 16),
                            label: Text(f['name']),
                            selected: _selectedFolderId == f['id'],
                            onSelected: (_) {
                              setState(() {
                                _selectedFolderId = f['id'];
                                _viewMode = 'folder';
                              });
                              _loadData();
                            },
                          ),
                        ),
                      )),
                ],
              ),
            ),
          // 分类标签
          if (categories.isNotEmpty && _selectedFolderId == null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setState(() =>
                                _selectedCategory = _selectedCategory == cat ? null : cat);
                            _loadData();
                          },
                        ),
                      )),
                ],
              ),
            ),
          // 收藏列表
          Expanded(
            child: _bookmarks.isEmpty
                ? StateView.empty(
                    title: '暂无收藏',
                    hint: '在辨证结果或方剂详情中点击收藏',
                    icon: Icons.bookmark_border,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = _bookmarks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              b.category == '方剂'
                                  ? Icons.medication
                                  : b.category == '本草'
                                      ? Icons.eco
                                      : Icons.bookmark,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            b.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            b.content.length > 80
                                ? b.content.substring(0, 80) + '...'
                                : b.content,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('删除收藏'),
                                    content: const Text('确定删除这条收藏吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteBookmark(b.id!);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (value == 'move') _showMoveToFolderDialog(b);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'move',
                                child: Row(
                                  children: [
                                    Icon(Icons.folder, size: 20),
                                    SizedBox(width: 8),
                                    Text('移动到文件夹'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text('删除'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _openBookmark(b),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
