import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/userInfo_user.dart';

class UserViewModel with ChangeNotifier {
  final UserInfoUser userInfoUser;
  bool _isUploading = false;
  UserEntity? _user;
  UserEntity? get user => _user;

  UserViewModel(this.userInfoUser);

  Future<UserEntity?> login(String email, String password) async {
    _user = await userInfoUser.login(email, password);
    notifyListeners();
    return _user;
  }

  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
  ) async {
    _user = await userInfoUser.signup(
      email,
      password,
      name,
      accountNumber,
      bankName,
    );
    notifyListeners();
    return _user;
  }

  Future<void> updateProfileImage(String imageUrl) async {
    if (_user == null) return;
    final uid = _user!.id;
    await userInfoUser.updatePhotoUrl(uid, imageUrl);
    print("updateProfileImage!! " + imageUrl);
    _user = UserEntity(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      account_number: _user!.account_number,
      photoUrl: imageUrl,
    );

    notifyListeners();
  }

  Future<String> uploadProfileImage(String userId, XFile file) async {
    _isUploading = true;
    notifyListeners();

    try {
      final url = await userInfoUser.uploadProfileImage(userId, file);
      return url;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final email = user.email;
    if (email == null) return;

    final userData = await userInfoUser.getUserByEmail(email);

    if (userData != null) {
      _user = userData;
      notifyListeners();
    }
  }


  Future<void> logout() async {
    await userInfoUser.logout();
    _user = null;
    notifyListeners();
  }
}
