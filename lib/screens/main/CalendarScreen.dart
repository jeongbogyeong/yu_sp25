import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // ✅ DB에서 불러온다고 가정 (예시 지출 데이터)
  Map<DateTime, double> expenses = {
    DateTime.utc(2025, 9, 22): 12000,
    DateTime.utc(2025, 9, 23): 45000,
    DateTime.utc(2025, 9, 24): 18000,
    DateTime.utc(2025, 9, 26): 300000,
    DateTime.utc(2025, 10, 7): 25000,
    DateTime.utc(2025, 10, 9): 25000,
  };

  // ✅ MyIncomeScreen에서 저장한 월급 정보
  int? _salaryDay; // 월급날 (1~28)
  int _salaryAmount10k = 0; // 월급 (십만 원 단위)
  bool _isLoadingIncome = false;

  SupabaseClient get _client => Supabase.instance.client;

  // 월급을 목표 예산으로 사용 (없으면 기본 100만 원)
  double get _targetExpense =>
      _salaryAmount10k > 0 ? _salaryAmount10k * 100000.0 : 1000000.0;

  @override
  void initState() {
    super.initState();
    _loadIncomeSettings();
  }

  // 🔹 userInfo_table에서 월급날/월급 금액 불러오기
  Future<void> _loadIncomeSettings() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    setState(() {
      _isLoadingIncome = true;
    });

    try {
      final uid = session.user.id;

      final userInfo = await _client
          .from('userInfo_table')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (userInfo != null) {
        _salaryDay = (userInfo['salaryDay'] as num?)?.toInt();
        _salaryAmount10k = (userInfo['salaryAmount10k'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ loadIncomeSettings error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingIncome = false;
        });
      }
    }
  }

  double? _getExpenseForDay(DateTime day) {
    return expenses[DateTime.utc(day.year, day.month, day.day)];
  }

  // 이 날이 월급날인지?
  bool _isSalaryDay(DateTime day) {
    if (_salaryDay == null) return false;
    return day.day == _salaryDay;
  }

  // ✅ 월별 지출액 및 평균 지출액 계산 로직
  Map<String, double> _calculateMonthlySummary() {
    double totalMonthlyExpenses = 0;

    final int daysInMonth = DateUtils.getDaysInMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    final now = DateTime.now();
    int remainingDays = 0;

    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      remainingDays = daysInMonth - now.day;
    }

    for (var entry in expenses.entries) {
      if (entry.key.year == _focusedDay.year &&
          entry.key.month == _focusedDay.month) {
        totalMonthlyExpenses += entry.value;
      }
    }

    double remainingAmount = _targetExpense - totalMonthlyExpenses;
    double dailyAverage = remainingDays > 0
        ? remainingAmount / remainingDays
        : 0;

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
    Intl.defaultLocale = 'ko_KR';

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("지출 캘린더"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 1. 지출 요약 카드
  // ----------------------------------------------------
  Widget _buildSummaryCard() {
    final summary = _calculateMonthlySummary();
    final total = summary['total']!;
    final dailyAverage = summary['daily_average']!;

    final isCurrentMonth =
        _focusedDay.year == DateTime.now().year &&
        _focusedDay.month == DateTime.now().month;

    String formatAmount(double amount) {
      String formatted = NumberFormat('#,###').format(amount.abs().round());
      return "$formatted원";
    }

    String formatDailyAvg(double amount) {
      String formatted = NumberFormat('#,###').format(amount.abs().round());
      return amount.isNegative ? "초과 $formatted원" : "$formatted원";
    }

    final salaryLabel = _salaryAmount10k > 0
        ? NumberFormat('#,###').format(_salaryAmount10k * 100000) + "원"
        : "미설정";

    return Padding(
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
              // 왼쪽: 총 지출액
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${DateFormat('MM월').format(_focusedDay)} 총 지출",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAmount(total),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: _expenseColor,
                    ),
                  ),
                ],
              ),

              // 오른쪽: 일일 권장 지출 + 월급 정보
              if (isCurrentMonth)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dailyAverage >= 0 ? "일일 권장 지출" : "일일 초과 금액",
                      style: TextStyle(
                        fontSize: 13,
                        color: dailyAverage >= 0
                            ? Colors.black54
                            : _expenseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDailyAvg(dailyAverage),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: dailyAverage >= 0
                            ? _primaryColor
                            : _expenseColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "이번 달 월급(예산)",
                      style: TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salaryLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    if (_salaryDay != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "월급날: 매월 $_salaryDay일",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 캘린더 위젯
  // ----------------------------------------------------
  Widget _buildCalendar() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          rowHeight: 65,
          onPageChanged: _onPageChanged,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _showExpenseSheet(selectedDay);
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextFormatter: (date, locale) =>
                DateFormat('yyyy년 MM월', locale).format(date),
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              size: 30.0,
              color: Colors.black54,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              size: 30.0,
              color: Colors.black54,
            ),
          ),
          calendarStyle: const CalendarStyle(outsideDaysVisible: false),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final expense = _getExpenseForDay(day);
              final isSalary = _isSalaryDay(day);

              return _buildDayCell(day, expense, isSalary, isToday: false);
            },
            todayBuilder: (context, day, focusedDay) {
              final expense = _getExpenseForDay(day);
              final isSalary = _isSalaryDay(day);

              return _buildDayCell(day, expense, isSalary, isToday: true);
            },
          ),
        ),
      ),
    );
  }

  // 날짜 셀 공통 빌더
  Widget _buildDayCell(
    DateTime day,
    double? expense,
    bool isSalary, {
    required bool isToday,
  }) {
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
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? _primaryColor
                  : (day.weekday == DateTime.sunday
                        ? Colors.red[400]
                        : Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          // 지출액
          if (expense != null)
            Text(
              "-${NumberFormat('#,###').format(expense)}",
              style: const TextStyle(
                fontSize: 11,
                color: _expenseColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            )
          else
            const SizedBox(height: 15),
          // 월급날 표시
          if (isSalary)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "월급날",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ 지출 상세 BottomSheet
  void _showExpenseSheet(DateTime selectedDay) {
    final expense = _getExpenseForDay(selectedDay);
    final formattedDate = DateFormat('yyyy년 MM월 dd일 (E)').format(selectedDay);
    final isSalary = _isSalaryDay(selectedDay);

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
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 20, thickness: 0.5),
                if (isSalary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          size: 18,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "월급날",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (_salaryAmount10k > 0)
                          Text(
                            "+${NumberFormat('#,###').format(_salaryAmount10k * 100000)} 원",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (expense != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "총 지출액",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      Text(
                        "-${NumberFormat('#,###').format(expense.round())} 원",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _expenseColor,
                        ),
                      ),
                    ],
                  )
                else if (!isSalary)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        "지출 내역이 없습니다.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: 지출 추가/상세 화면으로 이동
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "거래 내역 보기/추가",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
