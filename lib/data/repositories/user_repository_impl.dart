import 'package:smartmoney/data/datasources/user_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> login(String email, String password) async {
    return  await remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity?> signup(String email, String password,String name, int accountNumber) async {
    final response = await remoteDataSource.signup(
        email: email,
        password: password,
        name: name,
        accountNumber : accountNumber
    );
    return response;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}
