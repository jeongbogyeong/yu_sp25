import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/viewmodels/SpendingViewModel.dart';
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)

/*class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const Map<int, String> categoryNames = {
    0: "식비",
    1: "교통",
    2: "주거",
    3: "쇼핑",
    4: "기타",
  };

  static const Map<int, Color> categoryColors = {
    0: Color(0xFFFFA726), // 주황
    1: Color(0xFF42A5F5), // 파랑
    2: Color(0xFF66BB6A), // 연두
    3: Color(0xFFAB47BC), // 보라
    4: Color(0xFF78909C), // 회색
  };

  // ✅ 카드 기본 스타일
  static const _cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
  static const double _cardElevation = 4.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SpendingViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: _secondaryColor,
          appBar: AppBar(
            title: const Text("통계"),
            backgroundColor: _secondaryColor,
            elevation: 0,
            titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 양쪽 패딩 유지
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalGoalCard(context, vm),
                const SizedBox(height: 20),
                _buildCategoryProgressCard(context, vm),
                const SizedBox(height: 20),
                _buildPieChartCard(vm),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // ## 1. 총 목표 요약 카드 (지출액 강조 디자인)
  // ----------------------------------------------------
  Widget _buildTotalGoalCard(BuildContext context, SpendingViewModel vm) {
    final formattedTotalGoal = NumberFormat('#,###원').format(vm.overallGoal.toInt());
    final formattedTotalExpense = NumberFormat('#,###원').format(vm.totalExpense.toInt());

    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 설정 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "총 목표 요약",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(
                  height: 36, // 버튼 높이 통일
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("목표 설정"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final controller = TextEditingController(text: vm.overallGoal.toInt().toString());
                      await showDialog(
                          context: context,
                          builder: (ctx) => _buildGoalSettingDialog(ctx, "총 목표 금액 설정", controller, (val) => vm.updateOverallGoal(val))
                      );
                    },
                  ),
                )
              ],
            ),

            const Divider(height: 20, thickness: 0.5, color: Colors.black12),

            // 총 지출 (크게 강조)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "이번 달 총 지출",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTotalExpense,
                  style: const TextStyle(
                    fontSize: 32, // 지출액 최대 강조
                    fontWeight: FontWeight.w900,
                    color: _expenseColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 목표 대비 진행률
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "총 목표 금액",
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                Text(
                  formattedTotalGoal,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (vm.overallGoal > 0) ? (vm.totalExpense / vm.overallGoal).clamp(0.0, 1.0) : 0.0,
                color: vm.totalExpense > vm.overallGoal * 0.8 ? _expenseColor : _primaryColor,
                backgroundColor: _secondaryColor,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 2. 카테고리별 목표 진행 카드
  // ----------------------------------------------------
  Widget _buildCategoryProgressCard(BuildContext context, SpendingViewModel vm) {
    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "카테고리별 목표 진행",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 20, thickness: 0.5, color: Colors.black12),
            ...vm.categoryGoals.entries.map((entry) {
              final key = entry.key;
              final goal = entry.value;
              final expense = vm.categoryExpenses[key] ?? 0.0;
              final progress = (goal > 0) ? (expense / goal).clamp(0.0, 1.0) : 0.0;
              final categoryName = categoryNames[key] ?? '알 수 없음';
              final categoryColor = categoryColors[key] ?? Colors.grey;
              final isOverGoal = expense > goal;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 카테고리 이름
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: categoryColor),
                            const SizedBox(width: 8),
                            Text(
                              categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),

                        // 목표 설정 아이콘 + 지출/목표 금액
                        InkWell(
                          onTap: () async {
                            final controller = TextEditingController(text: goal.toInt().toString());
                            await showDialog(
                                context: context,
                                builder: (ctx) => _buildGoalSettingDialog(ctx, "$categoryName 목표 설정", controller, (val) => vm.updateGoalAmount(key, val))
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                "${NumberFormat('#,###').format(expense.toInt())} / ${NumberFormat('#,###').format(goal.toInt())} 원",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isOverGoal ? _expenseColor : Colors.black87,
                                  fontWeight: isOverGoal ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.search, size: 18, color: categoryColor), // 돋보기 아이콘
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: isOverGoal ? _expenseColor : categoryColor,
                        backgroundColor: _secondaryColor,
                        minHeight: 12, // 높이 증가
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 3. 원형 차트 카드
  // ----------------------------------------------------
  Widget _buildPieChartCard(SpendingViewModel vm) {
    final total = vm.totalExpense;

    // 지출이 0원일 경우 처리
    if (total == 0) {
      return const Card(
        shape: _cardShape,
        elevation: _cardElevation,
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text("지출 내역이 없어 통계를 표시할 수 없습니다.", style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: SizedBox(
          height: 200, // 높이 조정
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PieChart(
                  PieChartData(
                    sections: vm.categoryExpenses.entries.map((entry) {
                      final val = entry.value;
                      final percent = total > 0 ? val / total * 100 : 0;
                      return PieChartSectionData(
                        value: val,
                        color: categoryColors[entry.key],
                        title: (percent >= 5) ? "${percent.toStringAsFixed(1)}%" : "", // 5% 미만은 텍스트 표시 안 함
                        radius: 80, // 반지름 증가
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 3, // 간격 증가
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: vm.categoryExpenses.entries.map((entry) {
                      final percent = total > 0 ? entry.value / total * 100 : 0.0;

                      // 지출이 있는 카테고리만 범례에 표시
                      if (entry.value == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: categoryColors[entry.key],
                                  borderRadius: BorderRadius.circular(2)
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 카테고리 이름과 퍼센트를 정렬하여 표시
                            Expanded(
                              child: Text(
                                "${categoryNames[entry.key]}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            Text(
                              "${percent.toStringAsFixed(0)}%",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 4. 목표 설정 Dialog 헬퍼 함수
  // ----------------------------------------------------
  Widget _buildGoalSettingDialog(BuildContext context, String title, TextEditingController controller, Function(double) onSave) {
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          suffixText: "원",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(controller.text.replaceAll(',', ''));
            if (val != null) {
              onSave(val);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("저장"),
        )
      ],
    );
  }
}*/

// ✅ 카드 기본 스타일
const _cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
const double _cardElevation = 4.0;


// ****************************************************
// StatsScreen 클래스 시작
// ****************************************************
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const Map<int, String> categoryNames = {
    0: "식비", 1: "교통", 2: "주거", 3: "쇼핑", 4: "기타",
  };

  static const Map<int, Color> categoryColors = {
    0: Color(0xFFFFA726), 1: Color(0xFF42A5F5), 2: Color(0xFF66BB6A),
    3: Color(0xFFAB47BC), 4: Color(0xFF78909C),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<SpendingViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: _secondaryColor,
          appBar: AppBar(
            title: const Text("통계"),
            backgroundColor: _secondaryColor,
            elevation: 0,
            titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalGoalCard(context, vm),
                const SizedBox(height: 20),
                _buildCategoryProgressCard(context, vm),
                const SizedBox(height: 20),
                _buildPieChartCard(vm),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // ## 1. 총 목표 요약 카드 (지출액 강조 디자인)
  // ----------------------------------------------------
  Widget _buildTotalGoalCard(BuildContext context, SpendingViewModel vm) {
    final formattedTotalGoal = vm.formatNumber(vm.overallGoal);
    final formattedTotalExpense = vm.formatNumber(vm.totalExpense);

    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 설정 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "총 목표 요약",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("목표 설정"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final controller = TextEditingController();
                      await showDialog(
                          context: context,
                          // 총 목표 설정 시에는 categoryKey = null
                          builder: (ctx) => _buildGoalSettingDialog(ctx, "총 목표 금액 설정", controller, (val) => vm.updateOverallGoal(val), null)
                      );
                    },
                  ),
                )
              ],
            ),

            const Divider(height: 20, thickness: 0.5, color: Colors.black12),

            // 총 지출 (크게 강조)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "이번 달 총 지출",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  "$formattedTotalExpense원",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _expenseColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 목표 대비 진행률
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "총 목표 금액",
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                Text(
                  "$formattedTotalGoal원",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (vm.overallGoal > 0) ? (vm.totalExpense / vm.overallGoal).clamp(0.0, 1.0) : 0.0,
                color: vm.totalExpense > vm.overallGoal * 0.8 ? _expenseColor : _primaryColor,
                backgroundColor: _secondaryColor,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 2. 카테고리별 목표 진행 카드
  // ----------------------------------------------------
  Widget _buildCategoryProgressCard(BuildContext context, SpendingViewModel vm) {
    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "카테고리별 목표 진행",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 20, thickness: 0.5, color: Colors.black12),
            ...vm.categoryGoals.entries.map((entry) {
              final key = entry.key;
              final goal = entry.value;
              final expense = vm.categoryExpenses[key] ?? 0.0;
              final progress = (goal > 0) ? (expense / goal).clamp(0.0, 1.0) : 0.0;
              final categoryName = categoryNames[key] ?? '알 수 없음';
              final categoryColor = categoryColors[key] ?? Colors.grey;
              final isOverGoal = expense > goal;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 카테고리 이름
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: categoryColor),
                            const SizedBox(width: 8),
                            Text(
                              categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),

                        // 목표 설정 아이콘 + 지출/목표 금액
                        InkWell(
                          onTap: () async {
                            final controller = TextEditingController();
                            await showDialog(
                                context: context,
                                // 카테고리 키 전달
                                builder: (ctx) => _buildGoalSettingDialog(ctx, "$categoryName 목표 설정", controller, (val) => vm.updateGoalAmount(key, val), key)
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                "${vm.formatNumber(expense)} / ${vm.formatNumber(goal)} 원",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isOverGoal ? _expenseColor : Colors.black87,
                                  fontWeight: isOverGoal ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.search, size: 18, color: categoryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: isOverGoal ? _expenseColor : categoryColor,
                        backgroundColor: _secondaryColor,
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 3. 원형 차트 카드
  // ----------------------------------------------------
  Widget _buildPieChartCard(SpendingViewModel vm) {
    final total = vm.totalExpense;

    if (total == 0) {
      return const Card(
        shape: _cardShape,
        elevation: _cardElevation,
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text("지출 내역이 없어 통계를 표시할 수 없습니다.", style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PieChart(
                  PieChartData(
                    sections: vm.categoryExpenses.entries.map((entry) {
                      final val = entry.value;
                      final percent = total > 0 ? val / total * 100 : 0;
                      return PieChartSectionData(
                        value: val,
                        color: categoryColors[entry.key],
                        title: (percent >= 5) ? "${percent.toStringAsFixed(1)}%" : "",
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 20,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 50.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: vm.categoryExpenses.entries.map((entry) {
                      final percent = total > 0 ? entry.value / total * 100 : 0.0;

                      if (entry.value == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: categoryColors[entry.key],
                                  borderRadius: BorderRadius.circular(2)
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${categoryNames[entry.key]}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            Text(
                              "${percent.toStringAsFixed(0)}%",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 4. 목표 설정 Dialog 헬퍼 함수 및 콤마 포맷터
  // ----------------------------------------------------
  Widget _buildGoalSettingDialog(BuildContext context, String title, TextEditingController controller, Function(double) onSave, int? categoryKey) {
    final vm = Provider.of<SpendingViewModel>(context, listen: false);
    final numberFormat = NumberFormat('#,###');

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        // ✅ 콤마 포맷터 적용
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _ThousandsFormatter(),
        ],
        decoration: const InputDecoration(
          suffixText: "원",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final rawText = controller.text.replaceAll(RegExp(r','), '');
            final val = double.tryParse(rawText);

            if (val != null) {
              // 카테고리 목표 설정 시 총 목표 초과 검사
              if (categoryKey != null) {
                double sumExceptCurrent = vm.categoryGoals.entries
                    .where((e) => e.key != 4 && e.key != categoryKey)
                    .fold(0.0, (sum, e) => sum + e.value);

                double newTotal = sumExceptCurrent + val;

                if (newTotal > vm.overallGoal) {
                  // ✅ 목표 초과 알림창 (SnackBar)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '총 목표 금액 (${numberFormat.format(vm.overallGoal)}원)을 초과할 수 없습니다.',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return; // 저장하지 않고 종료
                }
              }

              onSave(val);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("저장"),
        )
      ],
    );
  }
}

// ****************************************************
// 콤마 포맷터 클래스 (StatsScreen과 같은 파일에 정의)
// ****************************************************
class _ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r','), '');
    final double? number = double.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final String newText = _formatter.format(number);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}