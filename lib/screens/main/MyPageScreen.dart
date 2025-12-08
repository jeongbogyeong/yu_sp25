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
import '../viewmodels/TransactionViewModel.dart';
import '../widgets/NotificationSettingsScreen.dart';
import '../login/PasswordReset.dart';
import 'ExpensePlanScreen.dart';

// 수입 설정 / 조회 화면
import 'MyIncomeScreen.dart';
import 'IncomeListScreen.dart';

// 거래 엔티티
import '../../domain/entities/transaction_entity.dart';

// ✨ 테마 색상 정의
const Color _primaryColor = Color(0xFF4CAF50);
const Color _secondaryColor = Color(0xFFF0F4F8);
const Color _expenseColor = Color(0xFFEF5350);

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  /// 🔥 DB에서
  /// 1) 월급 + 추가 수입 (수입 설정 화면 기준)
  /// 2) 모든 소비 계획의 고정 지출 합계
  /// 를 한 번에 가져온다.
  Future<Map<String, int>> _fetchIncomeAndFixedExpense() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      return {'income': 0, 'fixedExpense': 0};
    }

    final uid = session.user.id;

    int income10kTotal = 0; // 월급 + 추가 수입 (10만 원 단위 합)
    int fixedExpenseTotal = 0; // 모든 계획의 고정 지출 합 (원 단위)

    // ---------- 1) userInfo_table 에서 월급 ----------
    final userInfo = await client
        .from('userInfo_table')
        .select('salaryAmount10k')
        .eq('uid', uid)
        .maybeSingle();

    if (userInfo != null) {
      final salary10k = (userInfo['salaryAmount10k'] as num?)?.toInt() ?? 0;
      income10kTotal += salary10k;
    }

    // ---------- 2) user_extra_income_table 에서 추가 수입 ----------
    final extraRows = await client
        .from('user_extra_income_table')
        .select('amount10k')
        .eq('uid', uid);

    if (extraRows is List) {
      for (final row in extraRows) {
        final amount10k = (row['amount10k'] as num?)?.toInt() ?? 0;
        income10kTotal += amount10k;
      }
    }

    // 10만 원 단위 → 원 단위
    final incomeWon = income10kTotal * 100000;

    // ---------- 3) expense_plan_table + expense_fixed_item_table ----------
    final plans = await client
        .from('expense_plan_table')
        .select('id, rent, saving, loan')
        .eq('uid', uid);

    if (plans is List) {
      for (final p in plans) {
        final planId = p['id'];

        final rent = (p['rent'] as num?)?.toInt() ?? 0;
        final saving = (p['saving'] as num?)?.toInt() ?? 0;
        final loan = (p['loan'] as num?)?.toInt() ?? 0;

        fixedExpenseTotal += rent + saving + loan;

        // 각 plan 의 기타 고정비
        final fixedItems = await client
            .from('expense_fixed_item_table')
            .select('amount')
            .eq('plan_id', planId);

        if (fixedItems is List) {
          for (final item in fixedItems) {
            final amt = (item['amount'] as num?)?.toInt() ?? 0;
            fixedExpenseTotal += amt;
          }
        }
      }
    }

    return {'income': incomeWon, 'fixedExpense': fixedExpenseTotal};
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, txViewModel, child) {
        final List<TransactionEntity> transactions =
            txViewModel.transactions ?? [];

        // 🔹 거래 내역 기반 수입/지출
        //   - amount > 0  : 수입 카테고리로 들어온 돈
        //   - amount < 0  : 지출
        int incomeFromTx = 0;
        int expenseFromTx = 0;

        for (final tx in transactions) {
          final amount = tx.amount;
          if (amount > 0) {
            incomeFromTx += amount;
          } else if (amount < 0) {
            expenseFromTx += amount.abs();
          }
        }

        return FutureBuilder<Map<String, int>>(
          future: _fetchIncomeAndFixedExpense(),
          builder: (context, snapshot) {
            final dbIncome = snapshot.data?['income'] ?? 0; // 월급 + 추가 수입
            final fixedExpenseTotal =
                snapshot.data?['fixedExpense'] ?? 0; // 모든 고정지출 합계

            final isLoadingDb =
                snapshot.connectionState == ConnectionState.waiting;

            // 🔥 최종 수입 = (설정 기반 수입) + (거래 내역 수입 카테고리)
            final int totalIncome = dbIncome + incomeFromTx;

            // 🔥 최종 지출 = (거래 지출) + (고정 지출)
            final int totalExpense = expenseFromTx + fixedExpenseTotal;

            final int balance = totalIncome - totalExpense;

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
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileArea(),
                    const SizedBox(height: 20),

                    // 🔥 "수입 = 월급+추가수입+수입카테고리" / "지출 = 거래지출+고정지출"
                    _buildSummaryCard(
                      income: totalIncome,
                      expense: totalExpense,
                      balance: balance,
                      fixedExpenseIncluded: fixedExpenseTotal,
                      isLoadingFixed: isLoadingDb,
                    ),
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
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // 1. 프로필 영역
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
            // 프로필 사진 바꾸기 (나중에 Storage 연동 가능)
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked == null) return;
            // TODO: Supabase Storage 업로드 후 URL 저장
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
  // 2. 요약 카드
  // ----------------------------------------------------
  Widget _buildSummaryCard({
    required int income,
    required int expense,
    required int balance,
    required int fixedExpenseIncluded,
    required bool isLoadingFixed,
  }) {
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
              "전체 자산 현황",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoadingFixed
                  ? "고정 지출 불러오는 중..."
                  : "고정 지출(월세/적금/기타 포함)까지 반영된 지출입니다.",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem("수입", income, _primaryColor),
                _summaryItem("지출", expense, _expenseColor),
                _summaryItem("잔액", balance, Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 12),
            if (fixedExpenseIncluded > 0) ...[
              const Divider(height: 20, thickness: 0.5),
              Text(
                "※ 이 중 고정 지출: ${NumberFormat('#,###').format(fixedExpenseIncluded)}원",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
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
          _buildMenuTile(context, Icons.category_rounded, "소비 계획 세우기", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensePlanScreen()),
            );
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
