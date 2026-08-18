import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bookmark.dart';
import '../theme/app_colors.dart';
import '../data/database_helper.dart';

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
    _loadData();
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无收藏',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '在辨证结果或方剂详情中点击收藏',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(b.title),
                                content: SingleChildScrollView(
                                  child: Text(b.content),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                            );
                          },
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
