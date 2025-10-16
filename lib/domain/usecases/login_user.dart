import '../entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';

class LoginUser {
  final UserRepository repository;

  LoginUser(this.repository);

  // 이메일과 비밀번호를 받아 UserEntity를 반환합니다.
  Future<UserEntity?> call(String email, String password) async {
    return await repository.login(email, password);
  }
}