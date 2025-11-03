import '../../domain/entities/spending_entitiy.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/stat_repository.dart';
import '../datasources/stat_remote_datasource.dart';

class StatRepositoryImpl implements StatRepository {
  final StatRemoteDataSource remoteDataSource;

  StatRepositoryImpl(this.remoteDataSource);


  @override
  Future<List<SpendingEntity>> getSpending(String uid){
    return remoteDataSource.getSpending(uid);
  }

  @override
  Future<bool> updateSpending(SpendingEntity spending){
    return remoteDataSource.updateSpending(spending);
  }
}
