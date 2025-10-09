import 'package:hive/hive.dart';

part 'UserInfo.g.dart';

@HiveType(typeId: 0)
class UserInfo extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  int account_number;


  UserInfo({
    required this.uid,
    required this.name,
    required this.email,
    required this.account_number,
  });
}
