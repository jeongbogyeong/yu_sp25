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

  double? _getExpenseForDay(DateTime day) {
    return expenses[DateTime.utc(day.year, day.month, day.day)];
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
      body: Calender()
    );
  }

  Card Calender() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView(
        shrinkWrap: true,  // ← 자식 크기에 맞게
        physics: const BouncingScrollPhysics(),
        children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.0)
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12.0)
              ),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),

                focusedDay: _focusedDay,
                rowHeight: 73,
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
                      decoration: BoxDecoration(
                          color: isWeekend ? Colors.black12 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 0.5),
                            left: BorderSide(color: Colors.grey, width: 0.5),
                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                            top: BorderSide(color: Colors.grey, width: 0.5),
                          )
                      ),
                      height: 65, // 셀 높이 고정
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
                      decoration: BoxDecoration(
                          color: isWeekend ? Colors.black12 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 0.5),
                            left: BorderSide(color: Colors.grey, width: 0.5),
                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                            top: BorderSide(color: Colors.grey, width: 0.5),
                          )
                      ),
                      height: 65, // 셀 높이 고정
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
          ],
        ),
      );
  }
}
