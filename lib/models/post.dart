import 'package:hive/hive.dart';
import 'author.dart';

part 'post.g.dart';

@HiveType(typeId: 20)
class Post extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  Author author;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String text;

  @HiveField(4)
  List<String> imagePaths;

  @HiveField(5)
  int likeCount;

  @HiveField(6)
  bool likedByMe;

  @HiveField(7)
  String? passwordHash; // null이면 비번 없음

  Post({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.text,
    List<String>? imagePaths,
    this.likeCount = 0,
    this.likedByMe = false,
    this.passwordHash,
  }) : imagePaths = imagePaths ?? [];
}


