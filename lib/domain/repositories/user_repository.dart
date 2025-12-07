import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> login(String email, String password);

  // 🔥 incomeType 추가됨
  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
    String incomeType, // ← 추가
  );

  Future<void> logout();
}
