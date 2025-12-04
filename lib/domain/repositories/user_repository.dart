import 'package:image_picker/image_picker.dart';

import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> login(String email, String password);

  // 🔥 bankName까지 받도록
  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
  );

  Future<String> uploadProfileImage(String userId, XFile file);

  Future<void> updatePhotoUrl(String uid, String url);
  Future<UserEntity?> getUserByEmail(String email);
  Future<void> logout();


}
