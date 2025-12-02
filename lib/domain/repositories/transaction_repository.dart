import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>?> getTransactions(String uid);
  Future<TransactionEntity?> insertTransaction(TransactionEntity transaction);
  Future<bool> deleteTransaction(int id);
}
