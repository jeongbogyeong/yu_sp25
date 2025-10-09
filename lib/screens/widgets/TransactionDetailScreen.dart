import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 수입 강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)
const Color _incomeColor = _primaryColor;

class TransactionDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionDetailScreen({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // 배경색 통일
      appBar: AppBar(
        title: const Text("최근 거래 내역"),
        // ✅ 뒤로가기 버튼 및 기타 아이콘 색상을 검정색으로 지정
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0, // 그림자 제거
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Text(
                "전체 거래 내역",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            // 거래 내역 리스트를 Card 안에 넣어 깔끔하게 만듭니다.
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    itemCount: transactions.length,
                    // 리스트 아이템 간 구분선
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
                    ),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _buildTransactionTile(tx);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 거래 내역 타일 위젯 (변경 없음)
  // ----------------------------------------------------
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = tx['amount'] as int;
    final isExpense = amount < 0;

    // 금액 포맷팅 (예: 1,200,000)
    final formattedAmount = NumberFormat('#,###').format(amount.abs());

    // 아이콘 배경색 지정
    final iconBackgroundColor = isExpense ? _expenseColor.withOpacity(0.1) : _incomeColor.withOpacity(0.1);

    return ListTile(
      // 카테고리 아이콘
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(tx['icon'], color: isExpense ? _expenseColor : _incomeColor, size: 24),
      ),

      // 거래 제목
      title: Text(
        tx['title'],
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87
        ),
      ),

      // 거래 날짜 (좀 더 흐리게)
      subtitle: Text(
        tx['date'],
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),

      // 금액
      trailing: Text(
        "${isExpense ? '-' : '+'}$formattedAmount원",
        style: TextStyle(
          color: isExpense ? _expenseColor : _incomeColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}