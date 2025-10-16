import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

class UserViewModel extends ChangeNotifier {
  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;

  void setUser(UserEntity user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;
}