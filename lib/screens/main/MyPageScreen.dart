// lib/screens/main/MyPageScreen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartmoney/screens/login/LoginScreen.dart';

// ViewModel & Screens
import '../../service/notification/notification_service.dart';
import '../MyCommunity/MyCommentListScreen.dart';
import '../MyCommunity/MyLikedPostListScreen.dart';
import '../MyCommunity/MyPostListScreen.dart';
import '../viewmodels/UserViewModel.dart';
import '../widgets/NotificationSettingsScreen.dart';
import '../login/PasswordReset.dart';

// 수입 설정 / 조회 화면
import 'MyIncomeScreen.dart';
import 'IncomeListScreen.dart';

// ✨ 테마 색상 정의
const Color _primaryColor = Color(0xFF4CAF50);
const Color _secondaryColor = Color(0xFFF0F4F8);
const Color _expenseColor = Color(0xFFEF5350);

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // 이번 달 요약 (임시 하드코딩)
  final int _income = 2000000;
  final int _expense = 1200000;
  final int _balance = 800000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
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
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileArea(),
            const SizedBox(height: 20),

            _buildSummaryCard(),
            const SizedBox(height: 24),

            // ===== My 수입 · 월급 설정 =====
            _buildMenuSection("My 수입 · 월급 설정"),
            _buildMenuDivider(),
            _buildIncomeSettingCard(context),
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
  // 1. 프로필 영역 + (추후 프로필 이미지 업로드용 InkWell)
  // ----------------------------------------------------
  Widget _buildProfileArea() {
    return Consumer<UserViewModel>(
      builder: (context, vm, child) {
        final session = Supabase.instance.client.auth.currentSession;

        // 이름 우선순위
        String? name = vm.user?.name;
        name ??= session?.user.userMetadata?['name'] as String?;
        name ??= session?.user.email?.split('@').first;
        name ??= 'User';

        // 이메일 우선순위
        String? email = vm.user?.email ?? session?.user.email ?? '';

        final photoUrl = vm.user?.photoUrl;

        return InkWell(
          onTap: () async {
            // 프로필 사진 바꾸기 (원하면 나중에 진짜 업로드 로직 연결)
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked == null) return;

            // TODO: Supabase Storage에 업로드 후 URL 얻기
            // 최종적으로는 아래처럼 쓰면 됨:
            // final imageUrl = await uploadToSupabase(picked);
            // await vm.updateProfileImage(imageUrl);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: _primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.edit_rounded, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // 2. 이번 달 요약 카드
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
  // 공통: 섹션 제목 / Divider / Tile
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
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
  // My 수입 · 월급 설정 카드
  // ----------------------------------------------------
  Widget _buildIncomeSettingCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(
            context,
            Icons.account_balance_wallet_outlined,
            "주 수입원 · 월급 설정",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyIncomeScreen()),
              );
            },
            subtitle: "월급날과 주 수입원을 설정해요.",
          ),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.list_alt_outlined,
            "내 모든 수입원 보기",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeListScreen()),
              );
            },
            subtitle: "월급과 추가 수입원을 한눈에 확인해요.",
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 정보 변경 카드
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
  // My 게시판 활동 카드
  // ----------------------------------------------------
  Widget _buildBoardActivityCard(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const Text("로그인이 필요합니다.");
    }
    final String userId = session.user.id;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuTile(context, Icons.comment_rounded, "내가 쓴 댓글", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyCommentListScreen(userId: userId),
              ),
            );
          }),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.thumb_up_alt_outlined,
            "내가 달았던 좋아요",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyLikedPostListScreen(userId: userId),
                ),
              );
            },
          ),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.post_add_rounded, "내가 쓴 게시물", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyPostListScreen(userId: userId),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // My 지출 카드
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
            // TODO
          }),
          _buildMenuDivider(),
          _buildMenuTile(
            context,
            Icons.account_balance_wallet_rounded,
            "자산 계좌 관리",
            () {
              // TODO
            },
          ),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.bar_chart_rounded, "통계 보기", () {
            // TODO
          }),
          _buildMenuDivider(),
          _buildMenuTile(context, Icons.flag_rounded, "목표 금액 변경", () {
            // TODO
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 로그아웃
  // ----------------------------------------------------
  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: _buildMenuTile(context, Icons.logout_rounded, "로그아웃", () async {
        try {
          await Supabase.instance.client.auth.signOut();
          await context.read<UserViewModel>().logout();

          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint("로그아웃 오류: $e");
        }
      }, iconColor: _expenseColor),
    );
  }
}
