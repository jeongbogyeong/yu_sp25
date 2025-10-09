import 'package:flutter/foundation.dart';
import 'package:smartmoney/models/UserInfo.dart';


class UserViewModel with ChangeNotifier {
  UserInfo? _user;

  UserInfo? get user => _user;

  String get uid => _user?.uid ?? '';
  String get name => _user?.name ?? '';
  String get email => _user?.email ?? '';
  int get accountNumber => _user?.account_number ?? 0;

  // 초기화
  void setUser(UserInfo user) {
    _user = user;
    notifyListeners();
  }

  // 로그아웃 같은 비즈니스 로직도 포함할 수 있음
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
