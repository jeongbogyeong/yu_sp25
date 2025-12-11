// lib/screens/viewmodels/TransactionViewModel.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/transaction_user.dart';

class TransactionViewModel with ChangeNotifier {
  final TransactionUser transactionUser;

  // ✅ 널 대신 "빈 리스트"로 시작
  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  TransactionViewModel(this.transactionUser);

  // ✅ 거래 내역 조회
  Future<List<TransactionEntity>> getTransactions(String uid) async {
    // usecase에서 null이 올 수 있으니 ?? [] 로 방어
    _transactions = await transactionUser.getTransactions(uid) ?? [];

    if (_transactions.isNotEmpty) {
      debugPrint('getTransactions 했을때 : 첫 번째 id = ${_transactions[0].id}');
    } else {
      debugPrint('getTransactions 했을때 : 거래 내역 없음');
    }

    // 최신 날짜가 위로 오도록 정렬
    _transactions.sort((a, b) {
      // createdAt 이 String 이라고 가정
      final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(0);
      final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(0);
      return dateB.compareTo(dateA); // 내림차순
    });

    notifyListeners();
    return _transactions;
  }

  // ✅ 거래 추가
  Future<bool> insertTranaction(TransactionEntity transaction) async {
    final TransactionEntity? insertedTx = await transactionUser
        .insertTransaction(transaction);

    if (insertedTx != null) {
      // 리스트에 추가
      _transactions.add(insertedTx);

      // 정렬
      _transactions.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(0);
        final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      // ⭐ 마지막 소비 기록 날짜 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_spending_input',
        DateTime.now().toIso8601String(),
      );

      notifyListeners();
      return true;
    }

    return false;
  }

  // ✅ 거래 삭제
  Future<bool> deleteTransaction(int id) async {
    final isSuccess = await transactionUser.deleteTransaction(id);

    if (isSuccess) {
      if (_transactions.isNotEmpty) {
        debugPrint('deleteTransaction 전 : 첫 번째 id = ${_transactions[0].id}');
      } else {
        debugPrint('deleteTransaction 전 : 리스트 비어있음');
      }

      _transactions.removeWhere((tx) => tx.id == id);
      notifyListeners();
    }
    return isSuccess;
  }
}
