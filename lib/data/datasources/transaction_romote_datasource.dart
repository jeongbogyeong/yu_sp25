import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRomoteDatasource {
  final SupabaseClient client;
  TransactionRomoteDatasource(this.client);


  Future<List<TransactionEntity>?> getTransactions(String uid) async {
    try {
      final accountNum = await client
          .from('userInfo_table')
          .select('accountNumber')
          .eq('uid', uid);

      // ✅ 데이터가 없으면 null 리턴
      if (accountNum.isEmpty) {
        return null;
      }

      final result = await client
          .from('transaction_table')
          .select()
          .eq('accountNumber', accountNum);

      // ✅ 데이터가 있는 경우
      return result.map<TransactionEntity>((item) {
        return TransactionEntity(
          id: item['id'],
          accountNumber: item['accountNumber'],
          categoryId: item['categoryId'],
          amount: item['amount'],
          Memo: item['Memo'],
          createdAt: item['createdAt'],
          assetId: item['assetId'],
        );
      }).toList();
    } catch (e) {
      print('❌ getTranscations error: $e');
      rethrow; // 상위 레벨에서 처리하도록 던짐
    }
  }

  Future<bool> insertTransaction(TransactionEntity transaction) async {
    try {
      final response = await client.from('transaction_table').insert({
        'transactionId': transaction.id,
        'accountNumber': transaction.accountNumber,
        'categoryId': transaction.categoryId,
        'amount': transaction.amount,
        'Memo': transaction.Memo,
        'createdAt': transaction.createdAt,
        'assetId': transaction.assetId,
      });

      // 에러 여부 확인
      if (response == null) {
        return false;
      }

      return true;

    } catch (e) {
      print('❌ insertTransaction error: $e');
      return false;
    }
  }

}
