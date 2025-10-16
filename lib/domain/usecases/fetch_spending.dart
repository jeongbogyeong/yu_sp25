import '../entities/spending_entitiy.dart';
import '../../data/repositories/user_repository.dart';

class FetchSpending {
  final UserRepository repository;

  FetchSpending(this.repository);

  Future<bool> call(SpendingEntity spending) async {
    return await repository.FetchSpending(spending);
  }
}
