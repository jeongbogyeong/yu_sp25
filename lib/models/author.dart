import 'package:hive/hive.dart';

part 'author.g.dart';

@HiveType(typeId: 10)
enum AuthorType {
  @HiveField(0)
  anonymous,
  @HiveField(1)
  nickname,
}

@HiveType(typeId: 11)
class Author {
  @HiveField(0)
  final AuthorType type;

  @HiveField(1)
  final String? nickname;

  const Author({required this.type, this.nickname});
}


