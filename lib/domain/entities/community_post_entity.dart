class CommunityPostEntity {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String category;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPostEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
  });

    CommunityPostEntity copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? category,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPostEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

