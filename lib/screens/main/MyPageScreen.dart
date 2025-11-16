import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/login/LoginScreen.dart';

//ViewModel
import '../../service/notification/notification_service.dart';
import '../viewmodels/UserViewModel.dart';
import '../widgets/NotificationSettingsScreen.dart';


// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // 이번 달 요약 (가정)
  final int _income = 2000000;
  final int _expense = 1200000;
  final int _balance = 800000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // ✨ 배경색 통일
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("마이페이지"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
        centerTitle: false, // ✨ 제목 왼쪽 정렬
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileArea(), // ✅ 프로필 영역
            const SizedBox(height: 20),

            _buildSummaryCard(), // ✅ 이번 달 요약 카드
            const SizedBox(height: 24),

            _buildMenuSection("계정 및 설정"),
            _buildMenuDivider(),

            _buildMenuList(context), // ✅ 메뉴 리스트
            const SizedBox(height: 24),

            _buildMenuSection("로그아웃"),
            _buildMenuDivider(),

            _buildLogoutTile(context), // ✅ 로그아웃 버튼
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 1. 프로필 영역 (Profile Area) - 디자인 개선
  // ----------------------------------------------------
  Widget _buildProfileArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      // 배경색 제거, 깔끔하게 흰색 위에 위치
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: _primaryColor,
            ), // ✨ 기본 아이콘 사용
            // backgroundImage: AssetImage("assets/images/profile.png"),
          ),
          const SizedBox(width: 16),
          Consumer<UserViewModel>(
            builder: (context, vm, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.user!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vm.user!.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          // 프로필 수정 버튼
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.grey),
            onPressed: () {
              // 프로필 수정 기능
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 이번 달 요약 카드 (Summary Card) - 디자인 개선
  // ----------------------------------------------------
  Widget _buildSummaryCard() {
    return Card(
      margin: EdgeInsets.zero,
      // 바깥 여백은 Column Padding에서 처리
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // ✨ 모서리 둥글게
      ),
      elevation: 4,
      // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "이번 달 자산 현황",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem("수입", _income, _primaryColor),
                _summaryItem("지출", _expense, _expenseColor),
                _summaryItem("잔액", _balance, Colors.blueAccent), // 잔액은 파란색 계열
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, int amount, Color color) {
    final formattedAmount = NumberFormat('#,###').format(amount);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "₩ $formattedAmount",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // ✅ 3. 메뉴 리스트 (Menu List) - 디자인 개선
  // ----------------------------------------------------
  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 4.0, right: 4.0),
      child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(context, Icons.category_rounded, "카테고리 관리",() {}),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.account_balance_wallet_rounded,
            "자산 계좌 관리",
            () {},
          ),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.bar_chart_rounded, "통계 보기", () {}),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.notifications, "알림 설정",
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())
              )),

          // 텍스트 수정
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color iconColor = _primaryColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 24,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // ----------------------------------------------------
  // ✅ 4. 로그아웃 버튼
  // ----------------------------------------------------
  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: _buildMenuTile(
        context,
        Icons.logout_rounded,
        "로그아웃",
        () async {
          try {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              await Future.microtask(() {
                // 3.  UserViewModel 상태 정리
              });
            }
          } catch (e) {
            print("로그아웃 오류: $e");
          }
        },
        iconColor: _expenseColor, // 로그아웃은 빨간색 계열
      ),
    );
  }
}
