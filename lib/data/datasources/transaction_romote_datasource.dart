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
      final response = await client
          .from('transaction_table')
          .insert({
        'accountNumber': transaction.accountNumber,
        'categoryId': transaction.categoryId,
        'amount': transaction.amount,
        'memo': transaction.memo,
        'createdAt': transaction.createdAt,
        'assetId': transaction.assetId,
      })
          .select();

      if (response.isEmpty) return null;

      final data = response[0];

      return TransactionEntity(
        id: data['id'] ?? 0,
        accountNumber: data['accountNumber'] ?? 0,
        categoryId: data['categoryId'] ?? 0,
        amount: data['amount'] ?? 0,
        memo: data['memo'] ?? '',
        createdAt: data['createdAt'] ?? '',
        assetId: data['assetId'] ?? 0,
      );
    } catch (e) {
      print('❌ insertTransaction error: $e');
      return null;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      // 1) 삭제할 트랜잭션 정보를 먼저 가져오기
      final transactionResult = await client
          .from('transaction_table')
          .select('accountNumber, categoryId, amount')
          .eq('transactionId', id);

      if (transactionResult.isEmpty) {
        print('❌ 삭제할 transaction을 찾을 수 없음');
        return false;
      }

      final int accountNumber = transactionResult[0]['accountNumber'];
      final int categoryId = transactionResult[0]['categoryId'];
      final int amount = transactionResult[0]['amount'];

      // 2) 트랜잭션 삭제
      await client
          .from('transaction_table')
          .delete()
          .eq('transactionId', id);

      // 3) 지출(0~10)이었다면 spendingGoal_table 에서 금액 감소
     /* if (categoryId <= 10) {
        // uid 조회
        final userResult = await client
            .from('userInfo_table')
            .select('uid')
            .eq('accountNumber', accountNumber);

        if (userResult.isNotEmpty) {
          final uid = userResult[0]['uid'];

          // 현재 spending 값 가져오기
          final goalResult = await client
              .from('spendingGoal_table')
              .select('spending')
              .eq('uid', uid)
              .eq('type',categoryId );

          int current = 0;
          if (goalResult.isNotEmpty) {
            current = goalResult[0]['spending'] ?? 0;
          }

          // 4) spending 값 감소 (음수 방지)
          int updated = current + amount;
          if (updated < 0) updated = 0;

          await client
              .from('spendingGoal_table')
              .update({
            'spending': updated,
          })
              .eq('uid', uid)
              .eq('type',categoryId );
        }
      }*/

      return true;
    } catch (e) {
      print('❌ DeleteTransaction error: $e');
      return false;
    }
  }


}
