import '../entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';

class FetchUser {
  final UserRepository repository;

  FetchUser(this.repository);

  // UID를 받아 사용자 정보를 가져옵니다.
  Future<UserEntity?> call(String uid) async {
    return await repository.fetchUser(uid);
  }
}

