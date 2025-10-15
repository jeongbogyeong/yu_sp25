import 'author.dart';

class Post {
  String id;
  Author author;
  DateTime createdAt;
  String text;
  List<String> imagePaths;
  int likeCount;
  bool likedByMe;
  String category;

  Post({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.text,
    List<String>? imagePaths,
    this.likeCount = 0,
    this.likedByMe = false,
    this.category = '자유',
  }) : imagePaths = imagePaths ?? [];
}



