class BookmarkFolder {
  final int? id;
  final String name;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;

  BookmarkFolder({
    this.id,
    required this.name,
    this.icon = 'folder',
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookmarkFolder.fromJson(Map<String, dynamic> json) {
    return BookmarkFolder(
      id: json['id'] as int?,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? 'folder',
      sortOrder: (json['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };
}
