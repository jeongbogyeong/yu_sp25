import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          title: const Text("홈"),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20
          ),
          backgroundColor: Colors.grey[200],
          elevation: 0.0,
        ),
      ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 요약 카드
            SummationCard(),
            const SizedBox(height: 16),

            // 2. 목표/알림 카드
            GoalCard(),
            const SizedBox(height: 16),

            // 3. 최근 거래 내역
            Text("최근 거래", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RecentCard(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("더보기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  요약 카드
  Card SummationCard(){
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
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

  // 요약 카드용 위젯
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

  //목표 카드
  Card GoalCard(){
    return  Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.flag, color: Colors.blue),
        title: const Text("이번 달 예산: 2,000,000원"),
        subtitle: const Text("75% 사용됨 (1,500,000원)"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }




  // 최근 거래 내역
  Card RecentCard(){
      return  Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: const [
            ListTile(
              leading: Icon(Icons.restaurant, color: Colors.orange),
              title: Text("외식"),
              subtitle: Text("09/21"),
              trailing: Text("-15,000원",
                  style: TextStyle(color: Colors.red)),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.directions_bus, color: Colors.blue),
              title: Text("교통"),
              subtitle: Text("09/20"),
              trailing: Text("-1,250원",
                  style: TextStyle(color: Colors.red)),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.work, color: Colors.green),
              title: Text("급여"),
              subtitle: Text("09/20"),
              trailing: Text("+2,000,000원",
                  style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
  }

}
