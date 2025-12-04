import '../repositories/stat_repository.dart';
import '../entities/spending_entitiy.dart';

class StatUser {
  final StatRepository repository;
  String _currentUserId = '1';

  StatUser(this.repository);

  void setID(String id) {
    _currentUserId = id;
  }

  String get currentUserId => _currentUserId;

  Future<List<SpendingEntity>> getStat(String uid) async {
    final list = await repository.getSpending(uid);
    return list ?? []; // null이면 빈 리스트 반환
  }

  Future<bool> updateStat(SpendingEntity spending) async {
    return await repository.updateSpending(spending);
  }

  // 총 목표
  int totalGoal(List<SpendingEntity> list) {
    return list.fold(0, (sum, s) => sum + s.goal);
  }

  // 총 지출
  int totalExpense(List<SpendingEntity> list) {
    return list.fold(0, (sum, s) => sum + s.spending);
  }

  // 카테고리별 목표
  int goalByType(List<SpendingEntity> list, int type) {
    final s = list.firstWhere(
      (s) => s.type == type,
      orElse: () => SpendingEntity(
        uid: _currentUserId, // 현재 유저 ID
        goal: 0,
        spending: 0,
        type: type,
      ),
    );
    return s.goal;
  }

  // 카테고리별 지출
  int expenseByType(List<SpendingEntity> list, int type) {
    final s = list.firstWhere(
      (s) => s.type == type,
      orElse: () => SpendingEntity(
        uid: _currentUserId, // 현재 유저 ID
        goal: 0,
        spending: 0,
        type: type,
      ),
    );
    return s.spending;
  }
}
