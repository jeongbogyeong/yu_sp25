import 'package:smartmoney/data/datasources/transaction_romote_datasource.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRomoteDatasource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TransactionEntity>?> getTransactions(String uid) async {
    return  await remoteDataSource.getTransactions(uid);
  }

  @override
  Future<TransactionEntity?> insertTransaction(TransactionEntity transaction){
    return remoteDataSource.insertTransaction(transaction);
  }

  @override
  Future<bool> deleteTransaction(int id){
    return remoteDataSource.deleteTransaction(id);
  }
}
