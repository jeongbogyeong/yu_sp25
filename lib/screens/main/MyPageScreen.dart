import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/login/LoginScreen.dart';

// ViewModel
import '../../service/notification/notification_service.dart';
import '../viewmodels/UserViewModel.dart';
import '../widgets/NotificationSettingsScreen.dart';
import '../login/PasswordReset.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출/위험 계열 (빨간색)

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

            // ===== 정보 변경 =====
            _buildMenuSection("정보 변경"),
            _buildMenuDivider(),
            _buildInfoChangeCard(context),
            const SizedBox(height: 24),

            // ===== My 게시판 활동 =====
            _buildMenuSection("My 게시판 활동"),
            _buildMenuDivider(),
            _buildBoardActivityCard(context),
            const SizedBox(height: 24),

            // ===== My 지출 =====
            _buildMenuSection("My 지출"),
            _buildMenuDivider(),
            _buildSpendingCard(context),
            const SizedBox(height: 24),

            // ===== 로그아웃 =====
            _buildMenuSection("로그아웃"),
            _buildMenuDivider(),
            _buildLogoutTile(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 1. 프로필 영역 (Profile Area)
  // ----------------------------------------------------
  Widget _buildProfileArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _primaryColor.withOpacity(0.1),
            child: Icon(Icons.person_rounded, size: 40, color: _primaryColor),
          ),
          const SizedBox(width: 16),
          Consumer<UserViewModel>(
            builder: (context, vm, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vm.user?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          // 프로필 수정은 아래 메뉴(정보 변경 섹션)로 빼서 관리
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 이번 달 요약 카드 (Summary Card)
  // ----------------------------------------------------
  Widget _buildSummaryCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
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
                _summaryItem("잔액", _balance, Colors.blueAccent),
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
  // ✅ 공통: 섹션 제목 / Divider
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
  // ✅ 정보 변경 카드
  //   - 비밀번호 재설정
  //   - 프로필 수정
  //   - 알림 설정 (기존 기능 유지)
  // ----------------------------------------------------
  Widget _buildInfoChangeCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(context, Icons.lock_reset_rounded, "비밀번호 재설정", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
            );
          }),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.person_outline_rounded, "프로필 수정", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("프로필 수정 화면은 아직 준비 중입니다.")),
            );
          }),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.notifications,
            "알림 설정",
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ My 게시판 활동 카드
  //   - 내가 쓴 댓글
  //   - 내가 달았던 좋아요
  //   - 내가 쓴 게시물
  // ----------------------------------------------------
  Widget _buildBoardActivityCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(context, Icons.comment_rounded, "내가 쓴 댓글", () {
            // TODO: 내가 쓴 댓글 목록 화면 이동
          }),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.thumb_up_alt_outlined,
            "내가 달았던 좋아요",
            () {
              // TODO: 내가 좋아요한 게시글 목록
            },
          ),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.post_add_rounded, "내가 쓴 게시물", () {
            // TODO: 내가 쓴 게시글 목록
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ My 지출 카드
  //   - 카테고리 관리
  //   - 자산 계좌 관리
  //   - 통계 보기
  //   - 목표 금액 변경
  // ----------------------------------------------------
  Widget _buildSpendingCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(context, Icons.category_rounded, "카테고리 관리", () {
            // TODO: 카테고리 관리 화면
          }),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.account_balance_wallet_rounded,
            "자산 계좌 관리",
            () {
              // TODO: 자산 계좌 관리 화면
            },
          ),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.bar_chart_rounded, "통계 보기", () {
            // TODO: 통계 화면
          }),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.flag_rounded, "목표 금액 변경", () {
            // TODO: 목표 금액 변경 화면
          }),
        ],
      ),
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
                // TODO: UserViewModel 상태 정리 (토큰/유저 정보 초기화 등)
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
