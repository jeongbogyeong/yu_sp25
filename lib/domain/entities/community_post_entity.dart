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
}

