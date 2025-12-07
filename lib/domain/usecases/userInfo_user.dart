import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UserInfoUser {
  final UserRepository repository;

  UserInfoUser(this.repository);

  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
    String incomeType, // <-- 추가된 부분
  ) {
    return repository.signup(
      email,
      password,
      name,
      accountNumber,
      bankName,
      incomeType,
    );
  }

  Future<void> logout() {
    return repository.logout();
  }

  Future<UserEntity?> login(String email, String password) {
    return repository.login(email, password);
  }
}
