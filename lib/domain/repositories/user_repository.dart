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

  Future<void> logout();
}
