import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/spending_entitiy.dart';

class StatRemoteDataSource {
  final SupabaseClient client;
  StatRemoteDataSource(this.client);


  Future<List<SpendingEntity>> getSpending(String uid) async {
    try {
      final result = await client
          .from('spendingGoal_table')
          .select()
          .eq('uid', uid);

      // ✅ 데이터가 없으면 기본 5개 생성
      if (result.isEmpty) {
        return await _initializeDefaultSpendingGoals(uid);
      }

      // ✅ 이미 데이터가 있는 경우
      return result.map<SpendingEntity>((item) {
        return SpendingEntity(
          uid: item['uid'],
          goal: item['goal'],
          spending: item['spending'],
          type: item['type'],
        );
      }).toList();
    } catch (e) {
      print('❌ getSpending error: $e');
      rethrow; // 상위 레벨에서 처리하도록 던짐
    }
  }

  Future<List<SpendingEntity>> _initializeDefaultSpendingGoals(String uid) async {
    final List<SpendingEntity> defaultList = List.generate(11, (i) {
      return SpendingEntity(uid: uid, goal: 0, spending: 0, type: i);
    });

    // Supabase에 삽입
    final insertData = defaultList.map((e) => {
      'uid': e.uid,
      'goal': e.goal,
      'spending': e.spending,
      'type': e.type,
    }).toList();

    await client.from('spendingGoal_table').insert(insertData);
    return defaultList;
  }

  Future<bool> updateSpending(SpendingEntity spending) async {
    try {
      final response = await client
          .from('spendingGoal_table')
          .update({
        'goal': spending.goal,
        'spending': spending.spending,
        'type': spending.type,
      })
          .eq('uid', spending.uid)
          .eq('type', spending.type)
          .select();
      // Supabase에서 update() 결과는 변경된 행 리스트(List<dynamic>)를 반환
      return response.isNotEmpty; // 한 행이라도 수정됐으면 true
    } catch (e) {
      print('❌ updateSpending error: $e');
      return false;
    }
  }
}
