import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> login(String email, String password);
  signup(String email, String password,String name, int accountNumber);
  Future<void> logout();
}
