import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/transaction_user.dart';

class Transactionviewmodel with ChangeNotifier {
  final TransactionUser transactionUser;
  List<TransactionEntity>? _transactions;
  List<TransactionEntity>? get transactions => _transactions;
  Transactionviewmodel(this.transactionUser);

  Future<List<TransactionEntity>?> getTransactions(String uid) async {
    _transactions = await transactionUser.getTransactions(uid);
    notifyListeners();
    return _transactions;
  }

  Future<bool> insertTranaction(TransactionEntity transaction) async {
    bool isSuccess = await transactionUser.insertTransaction(transaction);
    if(isSuccess){
      _transactions?.add(transaction);
      notifyListeners();
    }
    return isSuccess;
  }
}
