import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/viewmodels/StatViewModel.dart';
import '../viewmodels/TransactionViewModel.dart';

import '../widgets/GoalSettingScreen.dart';

const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)

// ✅ 카드 기본 스타일
const _cardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
);
const double _cardElevation = 4.0;

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // ✅ 11가지 카테고리 이름 확장
  static const Map<int, String> categoryNames = {
    0: "식비",
    1: "교통",
    2: "문화생활",
    3: "마트/편의점",
    4: "패션/미용",
    5: "생활용품",
    6: "주거/통신",
    7: "병원비/약값",
    8: "교육",
    9: "경조사/회비",
    10: "기타",
  };

  // ✅ 11가지 카테고리 색상 확장
  static const Map<int, Color> categoryColors = {
    0: Color(0xFFFFA726),
    1: Color(0xFF42A5F5),
    2: Color(0xFF8D6E63),
    3: Color(0xFFEF5350),
    4: Color(0xFFEC407A),
    5: Color(0xFF66BB6A),
    6: Color(0xFFAB47BC),
    7: Color(0xFF78909C),
    8: Color(0xFF26A69A),
    9: Color(0xFFFFCA28),
    10: Color(0xFFBDBDBD),
  };

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StatViewModel>(context, listen: true);

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("통계"),
        backgroundColor: _secondaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        // ✅ 목표 설정 버튼을 AppBar Actions로 이동
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.settings, size: 20),
            label: const Text("목표 설정"),
            style: TextButton.styleFrom(foregroundColor: _primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalSettingScreen(),
                ),
              );
            },
          ),
        ],
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
            const SizedBox(height: 20),
            // ✅ 새로 추가된 이번 주 소비 요약 카드
            _buildWeeklySummaryCard(context, vm),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 1. 총 목표 요약 카드 (지출액 강조 디자인)
  // ----------------------------------------------------
  Widget _buildTotalGoalCard(BuildContext context, StatViewModel vm) {
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
            // 목표 설정 헤더 (설정 버튼 제거됨)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "총 목표 요약",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (vm.overallGoal > 0)
                    ? (vm.totalExpense / vm.overallGoal).clamp(0.0, 1.0)
                    : 0.0,
                color: vm.totalExpense > vm.overallGoal * 0.8
                    ? _expenseColor
                    : _primaryColor,
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
  Widget _buildCategoryProgressCard(BuildContext context, StatViewModel vm) {
    // ✅ 목표 금액이 0보다 큰 카테고리만 필터링
    final relevantCategories = vm.categoryGoals.entries.where((entry) {
      final key = entry.key;
      final goal = entry.value;
      final expense = vm.categoryExpenses[key] ?? 0.0;

      return goal > 0.0 || expense > 0.0;
    }).toList();

    if (relevantCategories.isEmpty) {
      return const Card(
        shape: _cardShape,
        elevation: _cardElevation,
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text(
              "현재 설정된 카테고리 목표가 없습니다.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 0.5, color: Colors.black12),

            ...relevantCategories.map((entry) {
              final key = entry.key;
              final goal = entry.value;
              final expense = vm.categoryExpenses[key] ?? 0.0;
              final progress = (goal > 0)
                  ? (expense / goal).clamp(0.0, 1.0)
                  : 0.0;
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        // 지출 / 목표 금액
                        Text(
                          "${vm.formatNumber(expense)} / ${vm.formatNumber(goal)} 원",
                          style: TextStyle(
                            fontSize: 15,
                            color: isOverGoal ? _expenseColor : Colors.black87,
                            fontWeight: isOverGoal
                                ? FontWeight.bold
                                : FontWeight.normal,
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
  Widget _buildPieChartCard(StatViewModel vm) {
    final total = vm.totalExpense;

    if (total == 0) {
      return const Card(
        shape: _cardShape,
        elevation: _cardElevation,
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              "지출 내역이 없어 통계를 표시할 수 없습니다.",
              style: TextStyle(color: Colors.grey),
            ),
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
                        title: (percent >= 5)
                            ? "${percent.toStringAsFixed(1)}%"
                            : "",
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
                      final percent = total > 0
                          ? entry.value / total * 100
                          : 0.0;
                      if (entry.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: categoryColors[entry.key],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categoryNames[entry.key] ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              "${percent.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 4. 이번 주 소비 요약 카드 (월~일 PageView)
  // ----------------------------------------------------
  Widget _buildWeeklySummaryCard(BuildContext context, StatViewModel vm) {
    // 🔥 TransactionViewModel에서 transaction 리스트 가져와서 넘겨줌
    final txVm = Provider.of<TransactionViewModel>(context, listen: true);
    final weekly = vm.getWeeklySpendingByDay(txVm.transactions);

    if (weekly.isEmpty || weekly.every((v) => v == 0)) {
      return const Card(
        shape: _cardShape,
        elevation: _cardElevation,
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              "이번 주 지출 내역이 없습니다.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // 🔽 아래 부분은 아까 주던 코드랑 그대로 두면 됨
    final labels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekTotal = weekly.fold<double>(0, (prev, e) => prev + e);
    final maxDayValue = weekly.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: _cardShape,
      elevation: _cardElevation,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "이번 주 소비 요약",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "월요일 ~ 일요일 기준으로 하루 지출을 확인해 보세요.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  itemCount: 7,
                  controller: PageController(viewportFraction: 0.98),
                  itemBuilder: (context, index) {
                    final amount = weekly[index];
                    final percent = weekTotal > 0
                        ? (amount / weekTotal * 100)
                        : 0.0;
                    final barRatio = maxDayValue > 0
                        ? (amount / maxDayValue)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${labels[index]}요일",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${vm.formatNumber(amount)}원",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _expenseColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekTotal > 0
                              ? "이번 주 전체 지출의 ${percent.toStringAsFixed(1)}%를 차지했어요."
                              : "이번 주 전체 지출이 아직 없습니다.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: barRatio.clamp(0.0, 1.0),
                            minHeight: 10,
                            color: _primaryColor,
                            backgroundColor: _secondaryColor,
                          ),
                        ),
                        const Spacer(),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            "좌우로 스와이프해서 요일별로 확인해 보세요",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
