class NoteModel {
  final String id;
  final String title;
  final String content;
  final String folderId;
  final int createdAt;
  final int updatedAt;
  final int isDeleted;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      folderId: json['folder_id'] as String? ?? 'all',
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      isDeleted: json['is_deleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder_id': folderId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? folderId,
    int? createdAt,
    int? updatedAt,
    int? isDeleted,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
