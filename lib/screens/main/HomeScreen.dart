import 'package:flutter/material.dart';
import '../widgets/TransactionDetailScreen.dart';



// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 가계부에 어울리는 녹색 계열
const Color _secondaryColor = Color(0xFFF0F4F8); // 밝은 배경색

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> _transactions = const [
    {
      "typeKey": 0, // 0: 식비 (지출)
      "date": "09/21",
      "amount": -15000,
      // "title": "외식", ⬅️ 이제 필요 없음
      // "icon": Icons.restaurant_menu_rounded,
      // "color": Colors.orange,
    },
    {
      "typeKey": 1, // 1: 교통/차량 (지출)
      "date": "09/20",
      "amount": -1250,
      // ...
    },
    {
      "typeKey": 11, // 11: 월급 (수입)
      "date": "09/20",
      "amount": 2000000,
      // ...
    },
    {
      "typeKey": 3, // 3: 마트/편의점 (지출)
      "date": "09/19",
      "amount": -55000,
      // ...
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // ✨ 배경색 통일
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Nudge_gap"), // ✨ 앱 이름으로 변경
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54),
            onPressed: () {
              // 알림 기능
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingCard(), // ✅ 인사말 카드
            const SizedBox(height: 16),

            _SummationCard(), // ✅ 수입/지출/잔액
            const SizedBox(height: 16),

            _GoalCard(context), // ✅ 목표 예산
            const SizedBox(height: 20),

            _CategorySummaryCard(), // ✅ 카테고리 요약
            const SizedBox(height: 20),

            // ----------------------------------------------------
            // 최근 거래 섹션 제목
            // ----------------------------------------------------
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "최근 거래",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionDetailScreen(initialTransactions: _transactions),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _primaryColor),
                    label: const Text(
                        "전체 내역",
                        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
            ),
            _RecentTransactionCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 1. 인사말 카드 (Greeting Card)
  // ----------------------------------------------------
  Widget _GreetingCard() {
    final now = DateTime.now();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ✨ 모서리 둥글게 (16)
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${now.month}월 ${now.day}일, 반가워요!",
                  style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "이번 달 예산을 확인해 볼까요? 💰",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            const Icon(Icons.sentiment_satisfied_alt_rounded, color: _primaryColor, size: 30), // ✨ 아이콘 변경 및 색상 통일
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 요약 카드 (Summation Card)
  // ----------------------------------------------------
  Widget _SummationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ✨ 모서리 둥글게
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem("총 수입", "2,500,000원", _primaryColor, Icons.add_circle_outline), // ✨ 아이콘 및 primaryColor 사용
            _summaryItem("총 지출", "1,800,000원", Colors.redAccent, Icons.remove_circle_outline), // ✨ 아이콘 및 색상 통일
            _summaryItem("잔액", "700,000원", Colors.blueAccent, Icons.account_balance_wallet_outlined), // ✨ 아이콘 및 색상 통일
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
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

  // ----------------------------------------------------
  // ✅ 3. 목표 카드 (Goal Card)
  // ----------------------------------------------------
  Widget _GoalCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ✨ 모서리 둥글게
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(Icons.track_changes_rounded, color: _primaryColor, size: 36), // ✨ 아이콘 변경 및 primaryColor 사용
        title: const Text(
          "이번 달 예산: 2,000,000원",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              "75% 사용 (남은 예산 500,000원)", // 남은 예산 정보 추가
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10), // 프로그레스 바 둥글게
              child: const LinearProgressIndicator(
                value: 0.75,
                minHeight: 10, // 높이 설정
                color: _primaryColor, // ✨ primaryColor 사용
                backgroundColor: _secondaryColor,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
        onTap: () {
          // 예산 상세 설정 화면으로 이동
        },
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 4. 카테고리 요약 카드 (Category Summary Card)
  // ----------------------------------------------------
  Widget _CategorySummaryCard() {
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
                "가장 많은 지출 (Top 4)", // 문구 수정
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:  [
                _categoryItem(Icons.local_dining_rounded, "식비", "600,000원", Colors.orange),
                _categoryItem(Icons.shopping_bag_rounded, "쇼핑", "400,000원", Colors.purple),
                _categoryItem(Icons.home_work_rounded, "주거", "300,000원", Colors.blue),
                _categoryItem(Icons.favorite_rounded, "취미", "200,000원", Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _categoryItem(
      IconData icon, String name, String amount, Color color) {
    return SizedBox(
      width: 60, // 아이템 너비 고정
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // ✨ 아이콘 배경색 추가
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28), // ✨ 아이콘 크기 키움
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(amount,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }


// ----------------------------------------------------
// ✅ 5. 최근 거래 카드 (Recent Transaction Card)
// ----------------------------------------------------
  Widget _RecentTransactionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: _transactions.take(3).map((tx) {
          final amount = tx['amount'] as int;
          final isExpense = amount < 0;

          // 1. typeKey를 가져와 기본값 처리 (HomeScreen은 typeKey 필수가 아니었으므로 안전하게 처리)
          final typeKey = tx['typeKey'] as int? ?? (isExpense ? 0 : 11);

          // 2. TransactionDetailScreen의 상수 Map을 참조할 수 없으므로,
          //    간단한 기본 색상/아이콘 로직을 사용하거나,
          //    해당 상수를 HomeScreen으로 가져와야 합니다.
          //    (여기서는 간단한 로직으로 처리합니다.)
          final primaryColor = isExpense ? Colors.redAccent : _primaryColor;
          final iconData = tx['icon'] as IconData? ?? (isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline);

          final amountText = "${amount > 0 ? '+' : ''}${amount.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원";

          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ✅ 오류 수정: primaryColor를 사용하여 아이콘 배경색 지정
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // ✅ 오류 수정: primaryColor를 사용하여 아이콘 색상 지정
                  child: Icon(iconData, color: primaryColor, size: 28),
                ),
                title: Text(
                  tx['title'] as String? ?? (isExpense ? '지출' : '수입'), // title이 없으면 기본값 사용
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                subtitle: Text(
                  tx['date'],
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor, // 지출/수입 색상 통일
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // 거래 상세 화면으로 이동
                },
              ),
              if (tx != _transactions.take(3).last) const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}