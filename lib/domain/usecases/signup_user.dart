import '../entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';

class SignupUser {
  final UserRepository repository;

  SignupUser(this.repository);

  // 이 UseCase는 회원가입 로직(MySQL 등록)을 캡슐화합니다.
  Future<bool> call(UserEntity user, String password) async {
    return await repository.signup(user, password);
  }
}
