import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/userInfo_user.dart';

class UserViewModel with ChangeNotifier {
  final UserInfoUser userInfoUser;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  UserEntity? _user;
  UserEntity? get user => _user;

  UserViewModel(this.userInfoUser);

  Future<UserEntity?> login(String email, String password) async {
    _user = await userInfoUser.login(email, password);
    notifyListeners();
    return _user;
  }

  /// ✅ incomeType 추가된 회원가입
  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
    String incomeType, // PART_TIME / SALARY / ALLOWANCE
  ) async {
    _user = await userInfoUser.signup(
      email,
      password,
      name,
      accountNumber,
      bankName,
      incomeType,
    );
    notifyListeners();
    return _user;
  }

  /// ✅ 프로필 이미지 URL 업데이트
  Future<void> updateProfileImage(String imageUrl) async {
    if (_user == null) return;

    final uid = _user!.id;

    // DB 업데이트
    await userInfoUser.updatePhotoUrl(uid, imageUrl);
    debugPrint("updateProfileImage!! $imageUrl");

    // 로컬 UserEntity 갱신 (incomeType, bankName까지 유지)
    _user = UserEntity(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      account_number: _user!.account_number,
      bankName: _user!.bankName,
      photoUrl: imageUrl,
      incomeType: _user!.incomeType,
    );

    notifyListeners();
  }

  /// ✅ 이미지 업로드 (Storage에 올리고 URL 리턴)
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

  /// ✅ 앱 시작 시 현재 로그인한 유저 불러오기
  Future<void> loadCurrentUser() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    final email = authUser.email;
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
