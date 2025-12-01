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

  // ✅ ETC_KEY를 11번째 카테고리인 10으로 변경 (0부터 시작)
  static const int etcKey = 10;

  // ✅ 카테고리 Map을 11개 항목 (0~10)으로 초기화
  Map<int, double> categoryGoals = {
    0: 0, 1: 0, 2: 0, 3: 0, 4: 0,
    5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0
  };
  Map<int, double> categoryExpenses = {
    0: 0, 1: 0, 2: 0, 3: 0, 4: 0,
    5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0
  };
  double overallGoal = 0;

  double get totalExpense =>
      categoryExpenses.values.fold(0.0, (sum, val) => sum + val);

  double get categoryGoalsSum =>
      categoryGoals.values.fold(0.0, (sum, val) => sum + val);

  String formatNumber(double number) =>
      NumberFormat('#,###').format(number.round());

  // ==================================================
  // loadSpendingData (기존 로직 유지하며 11개 카테고리 처리)
  // ==================================================
  Future<void> loadSpendingData(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _spendingList = await statUseCase.getStat(uid);

      // 초기화: 11개 카테고리 모두 0으로 설정
      categoryGoals.updateAll((key, value) => 0.0);
      categoryExpenses.updateAll((key, value) => 0.0);
      overallGoal = 0.0;

      if (_spendingList != null && _spendingList!.isNotEmpty) {
        double calculatedOverallGoal = 0.0;

        for (var s in _spendingList!) {
          // 데이터가 있다면, 해당 type에 맞게 값 업데이트
          if(categoryGoals.containsKey(s.type)) {
            categoryGoals[s.type] = s.goal.toDouble();
            categoryExpenses[s.type] = s.spending.toDouble();
            calculatedOverallGoal += s.goal.toDouble();
          }
        }
        // DB에서 불러온 카테고리 목표의 합을 총 목표로 설정
        overallGoal = calculatedOverallGoal;
      }

    } catch (e) {
      _errorMessage = "데이터 불러오기 오류: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // ✅ updateGoals (목표 설정 화면에서 모든 값을 일괄 업데이트)
  // ==================================================
  Future<bool> updateGoals(double newOverallGoal, Map<int, double> newCategoryGoals) async {

    overallGoal = newOverallGoal.clamp(0, double.infinity);

    // 카테고리 목표를 신규 값으로 업데이트
    categoryGoals = newCategoryGoals;

    // '기타' 목표 금액을 전체 목표와 다른 카테고리 목표의 차액으로 자동 조정
    _adjustEtcGoal();

    bool success = true;

    // 변경된 모든 목표 값을 DB에 업데이트
    for (var entry in categoryGoals.entries) {
      // 0원인 목표는 DB에 업데이트하지 않거나,
      // 모든 엔티티를 업데이트하여 상태를 일치시킵니다. (여기서는 모두 업데이트)
      final updateResult = await _updateEntityInDB(entry.key, entry.value);
      if (!updateResult) {
        success = false;
        // 실패 시 루프를 중단하거나 로깅할 수 있습니다.
      }
    }

    notifyListeners();
    return success;
  }

  // --------------------------------------------------
  // 기존 updateGoalAmount, updateOverallGoal 메서드는 제거되거나
  // GoalSettingScreen에서 사용하지 않으므로 주석 처리합니다.
  // --------------------------------------------------
  /*
  Future<bool> updateGoalAmount(int spendType, double newGoal) async { ... }
  Future<void> updateOverallGoal(double newGoal) async { ... }
  */

  // ==================================================
  // ✅ 기타 자동 조정 (newOverallGoal, newCategoryGoals 없이 자체 데이터 사용)
  // ==================================================
  void _adjustEtcGoal() {
    // '기타' (키 10)를 제외한 나머지 10개 카테고리 목표의 합계를 계산
    double sumExceptEtc = categoryGoals.entries
        .where((e) => e.key != etcKey)
        .fold(0.0, (sum, e) => sum + e.value);

    // 전체 목표에서 나머지 목표 합계를 뺀 값을 '기타' 목표로 설정
    double etcGoalCalculated = (overallGoal - sumExceptEtc).clamp(0.0, double.infinity);

    // '기타' 카테고리 목표 업데이트
    categoryGoals[etcKey] = etcGoalCalculated;

    // DB에 '기타' 목표 업데이트
    _updateEntityInDB(etcKey, etcGoalCalculated);
  }

  // ==================================================
  // DB 업데이트 (기존 로직 유지)
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
  // 엔티티 가져오기 또는 생성 (기존 로직 유지)
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