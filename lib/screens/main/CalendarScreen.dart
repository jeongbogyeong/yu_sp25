import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)

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
    DateTime.utc(2025, 10, 7): 25000,
    DateTime.utc(2025, 10, 9): 25000,

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

    // 현재 focusedDay가 있는 달의 일수를 구함
    final int daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);

    // 현재 날짜
    final now = DateTime.now();

    // 현재 포커스된 달이 현재 달과 같을 때만 남은 기간을 계산
    int remainingDays = 0;
    // 현재 달과 같고, 미래의 날짜가 아닌 경우만 계산
    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      remainingDays = daysInMonth - now.day;
    }

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

  // 캘린더 월 변경 시 Summary 카드 업데이트를 위해 사용
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 캘린더 locale을 설정
    Intl.defaultLocale = 'ko_KR';

    return Scaffold(
        backgroundColor: _secondaryColor, // 배경색 통일
        appBar: AppBar(
          title: const Text("지출 캘린더"),
          titleTextStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold
          ),
          backgroundColor: _secondaryColor,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildSummaryCard(), // ✅ 지출 요약 카드 추가
              const SizedBox(height: 16),
              _buildCalendar(), // ✅ 캘린더 위젯
              const SizedBox(height: 16), // ✅ 캘린더 위젯 아래에 최종 여백 추가
            ],
          ),
        )
    );
  }
// ----------------------------------------------------
// ✅ 1. 지출 요약 카드 (Summary Card) - 총 지출액 왼쪽, 보조 정보 오른쪽 열 정렬
// ----------------------------------------------------
  Widget _buildSummaryCard() {
    final summary = _calculateMonthlySummary();
    final total = summary['total']!;
    final dailyAverage = summary['daily_average']!;

    // 현재 달인지 확인하여 일일 평균 표시 여부 결정
    final isCurrentMonth = _focusedDay.year == DateTime.now().year && _focusedDay.month == DateTime.now().month;

    // 금액 포맷팅 헬퍼
    String formatAmount(double amount) {
      String formatted = NumberFormat('#,###').format(amount.abs().round());
      return formatted + "원";
    }

    // 일일 평균 권장액 포맷팅
    String formatDailyAvg(double amount) {
      String formatted = NumberFormat('#,###').format(amount.abs().round());
      return amount.isNegative ? "초과 ${formatted}원" : "${formatted}원";
    }

    return Padding(
      // 상단에 패딩을 추가하여 카드를 아래로 살짝 내립니다.
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 왼쪽: 총 지출액 (최대 강조)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${DateFormat('MM월').format(_focusedDay)} 총 지출",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAmount(total),
                    style: const TextStyle(
                      fontSize: 34, // ✨ 최대 크기로 강조
                      fontWeight: FontWeight.w900,
                      color: _expenseColor,
                    ),
                  ),
                ],
              ),

              // 2. 오른쪽: 보조 정보 (일일 권장 지출 + 목표 예산)
              if (isCurrentMonth)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2-1. 일일 권장 지출
                    Text(
                      dailyAverage >= 0 ? "일일 권장 지출" : "일일 초과 금액",
                      style: TextStyle(
                        fontSize: 13,
                        color: dailyAverage >= 0 ? Colors.black54 : _expenseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDailyAvg(dailyAverage),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: dailyAverage >= 0 ? _primaryColor : _expenseColor,
                      ),
                    ),

                    const SizedBox(height: 12), // 항목 간 간격

                    // 2-2. 이번 달 목표 예산
                    const Text(
                      "이번 달 목표 예산",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat('#,###').format(targetExpense.round()) + "원",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }


  // ----------------------------------------------------
  // ✅ 2. 캘린더 위젯 - Padding 수정
  // ----------------------------------------------------
  Widget _buildCalendar() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 모서리 둥글게
      elevation: 4, // 그림자 강화
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        // ✅ 하단 패딩을 16.0으로 통일하여 여백을 확보합니다.
        padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          rowHeight: 65, // 높이 증가

          onPageChanged: _onPageChanged,

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });

            _showExpenseSheet(selectedDay);
          },

          // 캘린더 헤더 스타일 (변경 없음)
          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextFormatter: (date, locale) => DateFormat('yyyy년 MM월', locale).format(date),
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
            leftChevronIcon: const Icon(Icons.chevron_left_rounded, size: 30.0, color: Colors.black54),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded, size: 30.0, color: Colors.black54),
          ),

          // 캘린더 기본 스타일 (변경 없음)
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
          ),

          // 날짜 셀 빌더 (변경 없음)
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final expense = _getExpenseForDay(day);

              return Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 날짜 숫자
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        fontSize: 16,
                        color: day.weekday == DateTime.sunday ? Colors.red[400] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 지출액 표시
                    if (expense != null)
                      Text(
                        "-${NumberFormat('#,###').format(expense)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: _expenseColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (expense == null)
                      const SizedBox(height: 15), // 지출 없으면 자리 확보
                  ],
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final expense = _getExpenseForDay(day);

              return Container(
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 날짜 숫자
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        fontSize: 16,
                        color: day.weekday == DateTime.sunday ? Colors.red[400] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 지출액 표시
                    if (expense != null)
                      Text(
                        "-${NumberFormat('#,###').format(expense)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: _expenseColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (expense == null)
                      const SizedBox(height: 15), // 지출 없으면 자리 확보
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ 지출 상세 BottomSheet (변경 없음)
  void _showExpenseSheet(DateTime selectedDay) {
    final expense = _getExpenseForDay(selectedDay);
    final formattedDate = DateFormat('yyyy년 MM월 dd일 (E)').format(selectedDay);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                  ),
                ),
                const Divider(height: 20, thickness: 0.5),
                if (expense != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("총 지출액", style: TextStyle(fontSize: 16, color: Colors.black54)),
                        Text(
                          "-${NumberFormat('#,###').format(expense.round())} 원",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _expenseColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text("지출 내역이 없습니다.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 지출 추가/상세 화면으로 이동하는 로직 추가 가능
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("거래 내역 보기/추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}