import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고 (빨간색 계열)

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  // ✨ 카테고리별 색상 팔레트 정의
  static const Map<String, Color> _categoryColors = {
    "식비": Color(0xFFFFA726), // 주황
    "교통": Color(0xFF42A5F5), // 파랑
    "주거": Color(0xFF66BB6A), // 연두
    "쇼핑": Color(0xFFAB47BC), // 보라
    "기타": Color(0xFF78909C), // 회색
  };

  final Map<String, double> categoryExpenses = const {
    "식비": 600000,
    "교통": 200000,
    "주거": 300000,
    "쇼핑": 700000, // 기타를 쇼핑으로 변경하여 색상 팔레트와 일치
  };
  final Map<String, double> categoryGoals = const {
    "식비": 1000000,
    "교통": 300000,
    "주거": 500000,
    "쇼핑": 600000, // 목표 초과 예시를 위해 60만으로 변경
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _secondaryColor, // ✨ 배경색 통일
        appBar: AppBar(
          title: const Text("통계"),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: _secondaryColor,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChartCard(), // 카테고리별 지출 비율 (PieChart)
              const SizedBox(height: 20),
              _GoalProgressCard(), // 카테고리별 목표 달성도 (Gauge Card)
            ],
          ),
        )
    );
  }

  // ----------------------------------------------------
  // ✅ 1. 카테고리별 지출 비율 카드 (PieChart) - 디자인 개선
  // ----------------------------------------------------
  Widget _ChartCard() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)), // ✨ 모서리 둥글게 (16)
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "월별 지출 카테고리 분석",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 파이 차트
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(),
                        sectionsSpace: 3, // 섹션 간격 늘림
                        centerSpaceRadius: 30, // 중앙 공간 키움
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 범례 (Legend)
                Expanded(
                  flex: 1,
                  child: _buildLegend(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리별 PieChart 섹션 생성
  List<PieChartSectionData> _buildPieSections() {
    final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);

    return categoryExpenses.entries.map((entry) {
      final color = _categoryColors[entry.key] ?? Colors.grey;
      final percentage = (entry.value / total) * 100;

      // 5% 미만은 텍스트를 파이 바깥에 표시하거나, 아예 생략하고 툴팁으로 대체하는 것이 좋지만,
      // 여기서는 기본 텍스트 스타일을 유지합니다.
      final section = PieChartSectionData(
        color: color,
        value: entry.value,
        title: "${percentage.toStringAsFixed(1)}%",
        radius: 70, // 반지름 키움
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        // 작은 섹션은 제목을 표시하지 않을 수도 있습니다.
        showTitle: percentage > 5,
      );
      return section;
    }).toList();
  }

  // 파이 차트 범례
  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: categoryExpenses.entries.map((entry) {
        final color = _categoryColors[entry.key] ?? Colors.grey;
        final percentage = (entry.value / categoryExpenses.values.fold(0.0, (a, b) => a + b)) * 100;
        final formattedAmount = NumberFormat('#,###원').format(entry.value.toInt());

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "${entry.key} (${percentage.toStringAsFixed(0)}%)",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 카테고리별 목표 달성도 카드 (Gauge Card) - 디자인 개선
  // ----------------------------------------------------
  Widget _GoalProgressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ✨ 모서리 둥글게
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "카테고리별 예산 달성도",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ...categoryExpenses.entries.map((entry) {
              final goal = categoryGoals[entry.key] ?? entry.value;
              final progress = (entry.value / goal).clamp(0.0, 1.0);
              final isOverBudget = entry.value > goal;
              final color = isOverBudget ? _expenseColor : _primaryColor; // 초과 시 경고색

              final formattedExpense = NumberFormat('#,###').format(entry.value.toInt());
              final formattedGoal = NumberFormat('#,###').format(goal.toInt());

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "${formattedExpense}원 / ${formattedGoal}원",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOverBudget ? _expenseColor : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8), // 프로그레스 바 둥글게
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12, // 높이 증가
                            backgroundColor: _secondaryColor,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                          // 진행률 텍스트를 프로그레스 바 중앙에 표시
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  isOverBudget ? "예산 초과!" : "${(progress * 100).toInt()}% 달성",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOverBudget)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "⚠️ ${NumberFormat('#,###원').format(entry.value - goal)} 초과했습니다.",
                          style: const TextStyle(
                            color: _expenseColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
}