import 'package:image_picker/image_picker.dart';
import 'package:smartmoney/data/datasources/user_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity?> signup(
    String email,
    String password,
    String name,
    int accountNumber,
    String bankName,
    String incomeType, // ✅ 추가
  ) async {
    // remoteDataSource 에서 named parameter 로 받는 형태로 통일
    final response = await remoteDataSource.signup(
      email: email,
      password: password,
      name: name,
      accountNumber: accountNumber,
      bankName: bankName,
      incomeType: incomeType, // ✅ 여기까지 전달
    );
    return response;
  }

  @override
  Future<String> uploadProfileImage(String userId, XFile file) async{
    return await remoteDataSource.uploadProfileImage(userId, file);
  }
  @override
  Future<void> updatePhotoUrl(String uid, String url) async{
    await remoteDataSource.updatePhotoUrl(uid, url);
  }
  @override
  Future<UserEntity?> getUserByEmail(String email) async {
      return await remoteDataSource.getUserByEmail(email);
  }
  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}
