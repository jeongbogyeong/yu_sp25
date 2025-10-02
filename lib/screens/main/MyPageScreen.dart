import 'package:flutter/material.dart';
import 'package:smartmoney/screens/login/LoginScreen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("마이페이지"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 영역
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/images/profile.png"), // 프로필 이미지
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "홍길동",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text("hong@test.com", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 이번 달 요약 카드
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text("이번 달 요약", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text("수입", style: TextStyle(color: Colors.green)),
                            SizedBox(height: 4),
                            Text("₩ 2,000,000", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text("지출", style: TextStyle(color: Colors.red)),
                            SizedBox(height: 4),
                            Text("₩ 1,200,000", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text("잔액", style: TextStyle(color: Colors.blue)),
                            SizedBox(height: 4),
                            Text("₩ 800,000", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 메뉴 리스트
            ListTile(
              leading: const Icon(Icons.category, color: Colors.green),
              title: const Text("카테고리 관리"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
              title: const Text("자산 계좌 관리"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: const Text("통계 보기"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.settings, color: Colors.green),
              title: const Text("설정"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("로그아웃"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
