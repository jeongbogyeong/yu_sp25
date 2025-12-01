import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class TransactionUser {
  final TransactionRepository repository;

  TransactionUser(this.repository);

  Future<List<TransactionEntity>> getTransactions(String uid) async {
    final list = await repository.getTransactions(uid);
    return list ?? []; // null이면 빈 리스트 반환
  }
  Future<TransactionEntity?> insertTransaction(TransactionEntity transaction) {
    return repository.insertTransaction(transaction);
  }

  Future<bool> deleteTransaction(int id) {
    return repository.deleteTransaction(id);
  }
}
