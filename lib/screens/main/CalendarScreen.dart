import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _ExpenseCalendarState();
}

class _ExpenseCalendarState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ✅ DB에서 불러온다고 가정 (예시 데이터)
  Map<DateTime, double> expenses = {
    DateTime.utc(2025, 9, 22): 12000,
    DateTime.utc(2025, 9, 23): 45000,
    DateTime.utc(2025, 9, 24): 18000,
    DateTime.utc(2025, 9, 26): 300000,
  };

  // ✅ 목표 지출액 설정
  final double targetExpense = 1000000;

  double? _getExpenseForDay(DateTime day) {
    // Note: The key in the map must match the format.
    return expenses[DateTime.utc(day.year, day.month, day.day)];
  }

  // ✅ 월별 지출액 및 평균 지출액 계산 로직
  Map<String, double> _calculateMonthlySummary() {
    double totalMonthlyExpenses = 0;
    int daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    int remainingDays = daysInMonth - _focusedDay.day;

    // Calculate total expenses for the focused month
    for (var entry in expenses.entries) {
      if (entry.key.year == _focusedDay.year && entry.key.month == _focusedDay.month) {
        totalMonthlyExpenses += entry.value;
      }
    }

    double remainingAmount = targetExpense - totalMonthlyExpenses;
    double dailyAverage = remainingDays > 0 ? remainingAmount / remainingDays : 0;

    return {
      'total': totalMonthlyExpenses,
      'remaining': remainingAmount,
      'daily_average': dailyAverage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            title: const Text("지출 캘린더"),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
            backgroundColor: Colors.grey[200],
            elevation: 0.0,
          ),
        ),
        body: SingleChildScrollView( // Added to prevent overflow
          child: Column(
            children: [
              _buildSummaryCard(), // ✅ 지출 요약 카드 추가
              SizedBox(height: 10),
              Calender(), // ✅ 캘린더 위젯 추가
            ],
          ),
        )
    );
  }

  // ✅ 지출 요약 정보를 담는 카드 위젯
  Card _buildSummaryCard() {
    final summary = _calculateMonthlySummary();
    final total = summary['total']!;
    final remaining = summary['remaining']!;
    final dailyAverage = summary['daily_average']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "이번 달 지출 요약 (${DateFormat('yyyy년 MM월').format(_focusedDay)})",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
              ),
            ),
            Divider(height: 20, thickness: 1),
            _buildSummaryRow("목표 지출액", targetExpense, Colors.blue),
            _buildSummaryRow("현재까지 지출액", total, Colors.red[300]!),
            _buildSummaryRow(
              "목표까지 남은 금액",
              remaining,
              remaining >= 0 ? Colors.green[600]! : Colors.red[600]!,
            ),
            _buildSummaryRow(
              "남은 기간 하루 평균 지출액",
              dailyAverage,
              dailyAverage >= 0 ? Colors.green[600]! : Colors.red[600]!,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 요약 정보 한 줄을 만드는 헬퍼 위젯
  Widget _buildSummaryRow(String label, double amount, Color color) {
    String formattedAmount = NumberFormat('#,###').format(amount.round());
    if (amount.isNegative) {
      formattedAmount = "- ${NumberFormat('#,###').format(amount.abs().round())}";
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            "$formattedAmount 원",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Card Calender() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child:  Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0)
        ),
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),

          focusedDay: _focusedDay,
          rowHeight: 55,

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });

            // ✅ 날짜 클릭 시 BottomSheet 띄우기
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "선택한 날짜",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(selectedDay),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // BottomSheet 닫기
                          },
                          child: const Text("닫기"),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              final expense = _getExpenseForDay(day);
              return Container(
                height: 50, // 셀 높이 고정
                width: 50,//셀 너비 고정
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "${day.day}",
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (expense != null)
                      Text(
                        "-${NumberFormat('#,###').format(expense)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (expense == null)
                      const SizedBox(height: 10), // 지출 없으면 자리 확보
                  ],
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final expense = _getExpenseForDay(day);
              bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              return Container(
                height: 50, // 셀 높이 고정
                width: 50,//셀 너비 고정
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "${day.day}",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (expense != null)
                      Text(
                        "-${NumberFormat('#,###').format(expense)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (expense == null) const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextFormatter: (date, locale) =>
                DateFormat.yMMMM(locale).format(date),
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(
              fontSize: 20.0,
              color: Colors.blue,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
            leftChevronIcon: const Icon(Icons.arrow_left, size: 40.0),
            rightChevronIcon: const Icon(Icons.arrow_right, size: 40.0),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
          ),

        ),
      ),
    );
  }
}
