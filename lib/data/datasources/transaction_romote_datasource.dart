import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRomoteDatasource {
  final SupabaseClient client;
  TransactionRomoteDatasource(this.client);


  Future<List<TransactionEntity>?> getTransactions(String uid) async {
    try {
      final accountNumResult = await client
          .from('userInfo_table')
          .select('accountNumber')
          .eq('uid', uid);

      // ✅ 데이터가 없으면 null 리턴
      if (accountNumResult.isEmpty) {
        return null;
      }

      final int? accountNumber = accountNumResult[0]['accountNumber'] as int?;
      if (accountNumber == null) {
        print('❌ Account number field not found or is null.');
        return null;
      }

      final result = await client
          .from('transaction_table')
          .select()
          .eq('accountNumber', accountNumber);

      // ✅ 데이터가 있는 경우
      return result.map<TransactionEntity>((item) {
        return TransactionEntity(
          id: item['transactionId'] as int? ?? 0,
          accountNumber: item['accountNumber']as int? ?? 0,
          categoryId: item['categoryId']as int? ?? 0,
          amount: item['amount']as int? ?? 0,
          memo: item['memo']as String? ??'',
          createdAt: item['createdAt']as String? ??'',
          assetId: item['assetId']as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      print('❌ getTranscations error: $e');
      rethrow; // 상위 레벨에서 처리하도록 던짐
    }
  }

  Future<TransactionEntity?> insertTransaction(TransactionEntity transaction) async {
    try {
      final response = await client.from('transaction_table').insert({
        'accountNumber': transaction.accountNumber,
        'categoryId': transaction.categoryId,
        'amount': transaction.amount,
        'memo': transaction.memo,
        'createdAt': transaction.createdAt,
        'assetId': transaction.assetId,
      })
      .select();
      if (response.isEmpty ||response.isEmpty) {
        return null;
      }
      final Map<String, dynamic> insertedData = response[0];

      // Entity를 재구성하여 ID를 포함한 완벽한 객체를 반환합니다.
      return TransactionEntity(
        id: insertedData['id'] as int? ?? 0, // DB에서 할당된 실제 ID
        accountNumber: insertedData['accountNumber']as int? ?? 0,
        categoryId: insertedData['categoryId']as int? ?? 0,
        amount: insertedData['amount']as int? ?? 0,
        memo: insertedData['memo']as String? ?? '',
        createdAt: insertedData['createdAt']as String? ?? '',
        assetId: insertedData['assetId']as int? ?? 0,
      );

    } catch (e) {
      print('❌ insertTransaction error: $e');
      return null;
    }
  }
  Future<bool> deleteTransaction(int id) async {
    try {
      print("삭제아이디 $id");
      await client
          .from('transaction_table')
          .delete()
          .eq('transactionId', id); // 'id' 컬럼이 주어진 id와 같은 행을 선택
      return true;

    } catch (e) {
      print('❌ DeleteTransaction error: $e');
      return false;
    }
  }

}
