import 'user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/spending_entitiy.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<bool> signup(UserEntity user, String password) async {
    // UserEntity와 비밀번호를 PHP가 요구하는 Map<String, dynamic> 형태로 변환
    final Map<String, dynamic> userData = {
      'user_id': user.id,
      'user_email': user.email,
      'user_password': password,
      'user_name': user.name,
      'user_regdate': user.regdate, // 서버에서 처리하는 경우 생략 가능
    };

    // 실제 데이터 통신은 DataSource에 위임
    return await remoteDataSource.registerUserToMySQL(userData);
  }

  @override
  Future<UserEntity?> fetchUser(String uid) async {
    final userDataMap = await remoteDataSource.fetchUserFromMySQL(uid);

    if (userDataMap != null) {
      // 서버에서 받은 Map 데이터를 UserEntity로 변환
      return UserEntity(
        id: userDataMap['user_id'] as String,
        email: userDataMap['user_email'] as String,
        password: userDataMap['user_password'] as String,
        name: userDataMap['user_name'] as String,
        regdate: userDataMap['user_regdate'] as String, // regDate는 로그인 시 필수가 아니므로 빈 문자열 처리
      );
    }
    return null;
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final userDataMap = await remoteDataSource.loginUserToMySQL(email, password);

    if (userDataMap != null) {
      // 서버에서 받은 Map 데이터를 UserEntity로 변환
      return UserEntity(
        id: userDataMap['user_id'] as String, // DB의 고유 ID (auto_increment 된 ID)
        email: userDataMap['user_email'] as String,
        password: userDataMap['user_password'] as String,
        name: userDataMap['user_name'] as String,
        regdate: userDataMap['user_regdate']?.toString() ?? '',
      );
    }
    return null;
  }

  @override
  Future<List<SpendingEntity>?> getSpending(int uid) async {
    final spendingDataList = await remoteDataSource.getSpendingFromMySQL(uid);

    if (spendingDataList != null && spendingDataList.isNotEmpty) {
      // List<Map<String, dynamic>> → List<SpendingEntity> 변환
      return spendingDataList.map((data) {
        return SpendingEntity(
          id: data['user_id'].toString(),
          goalAmount: int.parse(data['goal_amount'].toString()),
          spendingAmount: int.parse(data['spending_amount'].toString()),
          spendType: int.parse(data['spend_type'].toString()),
        );
      }).toList();
    }

    return null;
  }


  @override
  Future<bool> FetchSpending(SpendingEntity spending)async {
    // UserEntity와 비밀번호를 PHP가 요구하는 Map<String, dynamic> 형태로 변환
    final Map<String, dynamic> spendingData = {
      'user_id': spending.id,
      'goal_amount': spending.goalAmount.toString(),
      'spending_amount': spending.spendingAmount.toString(),
      'spend_type': spending.spendType.toString(),
    };

    // 실제 데이터 통신은 DataSource에 위임
    return await remoteDataSource.fetchSpendingFromMySQL(spendingData);
  }
}