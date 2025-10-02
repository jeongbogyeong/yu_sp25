import 'package:flutter/material.dart';
import 'package:smartmoney/screens/widgets/TransactionDetailScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final List<Map<String, dynamic>> _transactions = const [
    {
      "title": "외식",
      "date": "09/21",
      "amount": -15000,
      "icon": Icons.restaurant,
      "color": Colors.orange,
    },
    {
      "title": "교통",
      "date": "09/20",
      "amount": -1250,
      "icon": Icons.directions_bus,
      "color": Colors.blue,
    },
    {
      "title": "급여",
      "date": "09/20",
      "amount": 2000000,
      "icon": Icons.work,
      "color": Colors.green,
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          title: const Text("홈"),
          titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
          backgroundColor: Colors.grey[200],
          elevation: 0.0,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingCard(), // ✅ 인사말 카드
            const SizedBox(height: 16),

            SummationCard(), // ✅ 수입/지출/잔액
            const SizedBox(height: 16),

            GoalCard(), // ✅ 목표 예산
            const SizedBox(height: 16),

            CategorySummaryCard(), // ✅ 카테고리 요약
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("최근 거래", style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionDetailScreen(transactions: _transactions),
                      ),
                    );
                  },
                  child: const Text("더보기"),
                ),
              ],
            ),
            _recentCard(),
          ],
        ),
      ),
    );
  }

  // ✅ 인사말 카드
  Card GreetingCard() {
    final now = DateTime.now();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${now.month}월 ${now.day}일",
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text(
                  "오늘도 예산 안에서 소비하세요!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.waving_hand, color: Colors.orange, size: 28),
          ],
        ),
      ),
    );
  }

  // ✅ 요약 카드 (기존 유지)
  Card SummationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem("수입", "2,500,000원", Colors.green),
            _summaryItem("지출", "1,800,000원", Colors.red),
            _summaryItem("잔액", "700,000원", Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ✅ 목표 카드 (기존 유지)
  Card GoalCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.flag, color: Colors.blue),
        title: const Text("이번 달 예산: 2,000,000원"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("75% 사용됨 (1,500,000원)"),
            SizedBox(height: 6),
            LinearProgressIndicator(
              value: 0.75,
              color: Colors.blue,
              backgroundColor: Colors.grey,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // ✅ 카테고리 요약 카드
  Card CategorySummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("카테고리별 지출",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:  [
                _categoryItem(Icons.restaurant, "식비", "600,000원", Colors.orange),
                _categoryItem(Icons.directions_bus, "교통", "200,000원", Colors.blue),
                _categoryItem(Icons.home, "주거", "300,000원", Colors.green),
                _categoryItem(Icons.more_horiz, "기타", "400,000원", Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _categoryItem(
      IconData icon, String name, String amount, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
        Text(amount,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }

  // ✅ 최근 거래 (기존 유지)
  Card _recentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: _transactions.take(3).map((tx) {
          final isExpense = tx['amount'] < 0;
          return Column(
            children: [
              ListTile(
                leading: Icon(tx['icon'], color: tx['color']),
                title: Text(tx['title']),
                subtitle: Text(tx['date']),
                trailing: Text(
                  "${tx['amount'] > 0 ? '+' : ''}${tx['amount']}원",
                  style: TextStyle(
                    color: isExpense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (tx != _transactions.take(3).last) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}
