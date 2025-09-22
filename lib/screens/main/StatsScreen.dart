import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  final Map<String, double> categoryExpenses = const {
    "식비": 600000,
    "교통": 200000,
    "주거": 300000,
    "기타": 700000,
  };
  final Map<String, double> categoryGoals = const {
    "식비": 1000000,
    "교통": 300000,
    "주거": 500000,
    "기타": 900000,
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("통계 화면")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartCard(),
            const SizedBox(height: 16),
            GaugeCard(),
          ],
        ),
      )
    );
  }

  //  카테고리별 지출 차트 자리
  Card ChartCard(){
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("카테고리별 지출 비율",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리별 PieChart 섹션 생성
  List<PieChartSectionData> _buildPieSections() {
    final total = categoryExpenses.values.fold(0.0, (a, b) => a + b);

    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
    ];

    int colorIndex = 0;

    return categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final section = PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: entry.value,
        title: "${percentage.toStringAsFixed(1)}%\n${entry.key}",
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      colorIndex++;
      return section;
    }).toList();
  }

  Card GaugeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("카테고리별 목표 달성도",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...categoryExpenses.entries.map((entry) {
              final goal = categoryGoals[entry.key] ?? entry.value;
              final progress = (entry.value / goal).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${entry.key}  ${entry.value.toInt()} / ${goal.toInt()}원"),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.blue,
                      backgroundColor: Colors.grey[300],
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



