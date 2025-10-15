import 'author.dart';

class Comment {
  String id;
  String postId;
  String? parentCommentId; // null이면 일반 댓글, 아니면 대댓글
  Author author;
  DateTime createdAt;
  String text;
  int likeCount;
  bool likedByMe;

  Comment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.author,
    required this.createdAt,
    required this.text,
    this.likeCount = 0,
    this.likedByMe = false,
  });
}