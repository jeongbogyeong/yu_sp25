import '../../data/repositories/user_repository.dart';
import '../entities/spending_entitiy.dart';

class GetSpending {
  final UserRepository repository;
  String _currentUserId ='1';

  GetSpending(this.repository);

  void setID(String id){
    _currentUserId =id;
  }
  String get currentUserId => _currentUserId;
  Future<List<SpendingEntity>> call(int uid) async {
    final list = await repository.getSpending(uid);
    return list ?? []; // null이면 빈 리스트 반환
  }

  // 총 목표
  int totalGoal(List<SpendingEntity> list) {
    return list.fold(0, (sum, s) => sum + s.goalAmount);
  }

  // 총 지출
  int totalExpense(List<SpendingEntity> list) {
    return list.fold(0, (sum, s) => sum + s.spendingAmount);
  }

  // 카테고리별 목표
  int goalByType(List<SpendingEntity> list, int spendType) {
    final s = list.firstWhere(
          (s) => s.spendType == spendType,
      orElse: () => SpendingEntity(
        id: _currentUserId, // 현재 유저 ID
        goalAmount: 0,
        spendingAmount: 0,
        spendType: spendType,
      ),
    );
    return s.goalAmount;
  }

  // 카테고리별 지출
  int expenseByType(List<SpendingEntity> list, int spendType) {
    final s = list.firstWhere(
          (s) => s.spendType == spendType,
      orElse: () => SpendingEntity(
        id: _currentUserId, // 현재 유저 ID
        goalAmount: 0,
        spendingAmount: 0,
        spendType: spendType,
      ),
    );
    return s.spendingAmount;
  }
}
