class Bookmark {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String source;
  final int? folderId;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.source,
    this.folderId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as int?,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      source: json['source'] as String,
      folderId: json['folder_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'source': source,
        'folder_id': folderId,
        'created_at': createdAt.toIso8601String(),
      };
}
