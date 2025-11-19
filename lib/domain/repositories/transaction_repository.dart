import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>?> getTransactions(String uid);
  Future<bool> insertTransaction(TransactionEntity transaction);
}
