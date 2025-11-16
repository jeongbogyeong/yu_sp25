import '../entities/spending_entitiy.dart';

abstract class StatRepository {
  Future<List<SpendingEntity>> getSpending(String uid);
  Future<bool> updateSpending(SpendingEntity spending);
}
