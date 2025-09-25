import 'package:hive/hive.dart';
import 'author.dart';

part 'comment.g.dart';

@HiveType(typeId: 30)
class Comment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String postId;

  @HiveField(2)
  String? parentCommentId; // null이면 댓글, 아니면 대댓글

  @HiveField(3)
  Author author;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String text;

  @HiveField(6)
  int likeCount;

  @HiveField(7)
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


