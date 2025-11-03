import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmoney/domain/usecases/stat_user.dart';
import '../../domain/entities/spending_entitiy.dart';

class StatViewModel with ChangeNotifier {
  final StatUser statUseCase;

  StatViewModel(this.statUseCase);

  bool _isLoading = false;
  String? _errorMessage;
  List<SpendingEntity>? _spendingList;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const int etcKey = 4;

  Map<int, double> categoryGoals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
  Map<int, double> categoryExpenses = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
  double overallGoal = 0;

  double get totalExpense =>
      categoryExpenses.values.fold(0.0, (sum, val) => sum + val);

  double get categoryGoalsSum =>
      categoryGoals.values.fold(0.0, (sum, val) => sum + val);

  String formatNumber(double number) =>
      NumberFormat('#,###').format(number.round());

  // ==================================================
  // loadSpendingData
  // ==================================================
  Future<void> loadSpendingData(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _spendingList = await statUseCase.getStat(uid);

      if (_spendingList!.length>0) {
        for (var s in _spendingList!) {
          categoryGoals[s.type] = s.goal.toDouble();
          categoryExpenses[s.type] = s.spending.toDouble();
        }
        overallGoal = categoryGoals.values.fold(0.0, (sum, val) => sum + val);
      }
      else{
        overallGoal=0;
        categoryGoals.forEach((key, value) {
          categoryGoals[key] = 0;
        });
        categoryExpenses.forEach((key, value) {
          categoryExpenses[key] = 0;
        });
      }
      print("지금 uid : " + uid.toString());
    } catch (e) {
      _errorMessage = "데이터 불러오기 오류: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // updateGoalAmount
  // ==================================================
  Future<bool> updateGoalAmount(int spendType, double newGoal) async {
    newGoal = newGoal.clamp(0, double.infinity);

    _adjustEtcGoal(spendType, newGoal);
    categoryGoals[spendType] = newGoal;

    final success = await _updateEntityInDB(spendType, newGoal);
    notifyListeners();
    return success;
  }

  // ==================================================
  // updateOverallGoal
  // ==================================================
  Future<void> updateOverallGoal(double newGoal) async {
    overallGoal = newGoal.clamp(0, double.infinity);

    _adjustEtcGoal(null);

    final result = await _updateEntityInDB(etcKey, categoryGoals[etcKey]!);
    print("db저장 : " +  result.toString());
    notifyListeners();
  }

  // ==================================================
  // 기타 자동 조정
  // ==================================================
  void _adjustEtcGoal(int? spendType, [double? newGoal]) {
    double sumExceptEtc = categoryGoals.entries
        .where((e) => e.key != etcKey && e.key != spendType)
        .fold(0.0, (sum, e) => sum + e.value);

    if (spendType != null && newGoal != null) {
      sumExceptEtc += newGoal;
    }

    categoryGoals[etcKey] = (overallGoal - sumExceptEtc).clamp(0.0, double.infinity);
    _updateEntityInDB(etcKey,  categoryGoals[etcKey]!);
  }

  // ==================================================
  // DB 업데이트
  // ==================================================
  Future<bool> _updateEntityInDB(int type, double goal) async {
    final entity = _getOrCreateEntity(type);
    final updated = SpendingEntity(
      uid: entity.uid,
      goal: goal.round(),
      spending: entity.spending,
      type: type,
    );

    try {
      return await statUseCase.updateStat(updated);
    } catch (e) {
      _errorMessage = "DB 업데이트 오류: $e";
      return false;
    }
  }

  // ==================================================
  // 엔티티 가져오기 또는 생성
  // ==================================================
  SpendingEntity _getOrCreateEntity(int type) {
    return _spendingList?.firstWhere(
          (s) => s.type == type,
      orElse: () => SpendingEntity(
        uid: statUseCase.currentUserId,
        goal: 0,
        spending: 0,
        type: type,
      ),
    ) ??
        SpendingEntity(
          uid: statUseCase.currentUserId,
          goal: 0,
          spending: 0,
          type: type,
        );
  }

}
