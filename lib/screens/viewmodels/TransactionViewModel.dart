import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/transaction_user.dart';

class TransactionViewModel with ChangeNotifier {
  final TransactionUser transactionUser;
  List<TransactionEntity>? _transactions;
  List<TransactionEntity>? get transactions => _transactions;
  TransactionViewModel(this.transactionUser);

  Future<List<TransactionEntity>?> getTransactions(String uid) async {
    _transactions = await transactionUser.getTransactions(uid);
    int? i = _transactions?[0].id;
    print('getTransactions 했을때 : $i');
    // 거래 내역이 있을 경우에만 정렬 실행
    if (_transactions != null) {
      // DateTime 객체로 변환하여 정렬합니다. 최신 날짜가 맨 위로 오도록 내림차순 정렬합니다.
      _transactions!.sort((a, b) {
        // TransactionEntity에 date 필드가 String 형태라고 가정하고 DateTime으로 파싱
        final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(0);

        // 내림차순 (b가 a보다 최신이면 b가 먼저, 즉 -1)
        return dateB.compareTo(dateA);
      });
    }

    notifyListeners();
    return _transactions;
  }

  Future<bool> insertTranaction(TransactionEntity transaction) async {
    final TransactionEntity? insertedTx = await transactionUser.insertTransaction(transaction);
    if(insertedTx!=null){
      // 1. 새로운 거래 내역을 리스트에 추가합니다.
      _transactions?.add(insertedTx);

      // 2. 새로운 내역이 추가된 후 전체 리스트를 다시 정렬합니다.
      if (_transactions != null) {
        _transactions!.sort((a, b) {
          final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(0);
          return dateB.compareTo(dateA); // 내림차순 정렬
        });
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(int id) async {
    bool isSuccess = await transactionUser.deleteTransaction(id);
    int? i = _transactions?[0].id;
    print('deleteTransaction 했을때 : $i');
    if(isSuccess){
      _transactions?.removeWhere((tx) => tx.id == id);
      notifyListeners();
    }
    return isSuccess;
  }
}
