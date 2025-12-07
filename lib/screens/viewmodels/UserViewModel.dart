import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/userInfo_user.dart';

class UserViewModel with ChangeNotifier {
  final UserInfoUser userInfoUser;

  UserEntity? _user;
  UserEntity? get user => _user;

  UserViewModel(this.userInfoUser);

  Future<UserEntity?> login(String email, String password) async {
    _user = await userInfoUser.login(email, password);
    notifyListeners();
    return _user;
  }

  // ✅ incomeType 추가됨
  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
    String incomeType, // <-- 추가된 부분
  ) async {
    _user = await userInfoUser.signup(
      email,
      password,
      name,
      accountNumber,
      bankName,
      incomeType, // <-- 전달
    );
    notifyListeners();
    return _user;
  }

  Future<void> logout() async {
    await userInfoUser.logout();
    _user = null;
    notifyListeners();
  }
}
