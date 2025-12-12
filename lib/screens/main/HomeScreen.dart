import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/transaction_entity.dart';
import '../viewmodels/TransactionViewModel.dart';
import '../widgets/TransactionDetailScreen.dart';
import '../../service/income_budget_list.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 가계부에 어울리는 녹색 계열
const Color _secondaryColor = Color(0xFFF0F4F8); // 밝은 배경색

// -------------------------
// 🔹 Home 요약 데이터 모델
// -------------------------
class _HomeSummaryData {
  final int totalIncomeWon; // 총 수입 (예산)
  final int monthlyPlanBudgetWon; // 소비 계획에서 계산된 이번 달 생활비(예상 예산)

  _HomeSummaryData({
    required this.totalIncomeWon,
    required this.monthlyPlanBudgetWon,
  });
}

SupabaseClient get _client => Supabase.instance.client;

// -------------------------
// 🔹 이번 달 소비 계획 기반 예산 불러오기
//    (ExpensePlanScreen 과 동일한 로직)
// -------------------------
Future<int?> _fetchPlanLivingBudgetWon() async {
  final session = _client.auth.currentSession;
  if (session == null) return null;

  final userId = session.user.id;
  final now = DateTime.now();

  // 1) 월급 정보 가져오기 (userInfo_table)
  final userInfo = await _client
      .from('userInfo_table')
      .select()
      .eq('uid', userId)
      .maybeSingle();

  if (userInfo == null) return null;

  final salaryAmount10k = (userInfo['salaryAmount10k'] as int?) ?? 0;
  final salaryWon = salaryAmount10k * 100000;

  // 2) 이번 달 소비 계획 행 조회 (expense_plan_table)
  final plan = await _client
      .from('expense_plan_table')
      .select()
      .eq('uid', userId)
      .eq('year', now.year)
      .eq('month', now.month)
      .maybeSingle();

  if (plan == null) {
    // 계획이 아직 없음
    return null;
  }

  final rent = (plan['rent'] as num?)?.toDouble() ?? 0;
  final saving = (plan['saving'] as num?)?.toDouble() ?? 0;
  final loan = (plan['loan'] as num?)?.toDouble() ?? 0;
  final planId = plan['id'] as String;

  // 3) 기타 고정비들 조회 (expense_fixed_item_table)
  final fixedItems = await _client
      .from('expense_fixed_item_table')
      .select()
      .eq('plan_id', planId);

  double etcTotal = 0;
  if (fixedItems is List) {
    for (final item in fixedItems) {
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
      etcTotal += amount;
    }
  }

  // 4) 총 고정비 + 예상 생활비 계산
  final totalFixed = rent + saving + loan + etcTotal;
  final living = salaryWon - totalFixed;

  return living.round();
}

// -------------------------
// 🔹 Home 화면에서 쓸 요약 데이터 한 번에 가져오기
//    - 총 수입: fetchIncomeBudgetSummary()
//    - 예상 예산(이번 달 생활비): _fetchPlanLivingBudgetWon()
// -------------------------
Future<_HomeSummaryData> _fetchHomeSummary() async {
  // 총 수입 (월급 + 기타 수입 등)
  final incomeSummary = await fetchIncomeBudgetSummary();
  final totalIncomeWon = incomeSummary?.totalBudgetWon ?? 0;

  // 소비 계획에서 계산된 이번 달 생활비
  final livingBudgetWon = await _fetchPlanLivingBudgetWon();

  // 소비 계획이 없으면 fallback 으로 총 수입 사용
  final monthlyPlanBudgetWon = livingBudgetWon ?? totalIncomeWon;

  return _HomeSummaryData(
    totalIncomeWon: totalIncomeWon,
    monthlyPlanBudgetWon: monthlyPlanBudgetWon,
  );
}

// 이번 달 지출 합계 계산
int _calcThisMonthExpense(List<TransactionEntity> transactions) {
  final now = DateTime.now();

  int total = 0;
  for (final tx in transactions) {
    final dt = DateTime.tryParse(tx.createdAt); // createdAt 이 String 이라고 가정
    if (dt == null) continue;

    if (dt.year == now.year && dt.month == now.month) {
      // amount < 0 을 지출로 가정
      if (tx.amount < 0) {
        total += tx.amount.abs();
      }
    }
  }
  return total; // 원 단위
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, transactionViewModel, child) {
        final transactions = transactionViewModel.transactions ?? [];

        return FutureBuilder<_HomeSummaryData>(
          future: _fetchHomeSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: _secondaryColor,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data;
            final totalIncomeWon = data?.totalIncomeWon ?? 0;
            final monthlyBudgetWon = data?.monthlyPlanBudgetWon ?? 0;

            // 이번 달 실제 지출 합계
            final thisMonthExpenseWon = _calcThisMonthExpense(transactions);

            return Scaffold(
              backgroundColor: _secondaryColor, // ✨ 배경색 통일
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text("Nudge_gap"),
                // ✨ 앱 이름으로 변경
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: _secondaryColor,
                elevation: 0.0,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      // 알림 기능
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingCard(), // ✅ 인사말 카드
                    const SizedBox(height: 16),

                    // ✅ Supabase 에서 계산한 값으로 채움
                    _SummationCard(
                      totalIncomeWon: totalIncomeWon,
                      totalExpenseWon: thisMonthExpenseWon,
                    ),
                    const SizedBox(height: 16),

                    // 🔥 여기서 이번 달 예산으로 "소비 계획에서 계산된 생활비" 사용
                    _GoalCard(
                      monthlyBudgetWon: monthlyBudgetWon,
                      usedExpenseWon: thisMonthExpenseWon,
                    ),
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionDetailScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: _primaryColor,
                            ),
                            label: const Text(
                              "전체 내역",
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RecentTransactionCard(transactions: transactions),
                    const SizedBox(height: 20),
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
  // ✅ 1. 인사말 카드 (Greeting Card)
  // ----------------------------------------------------
  Widget _GreetingCard() {
    final now = DateTime.now();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // ✨ 모서리 둥글게 (16)
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "이번 달 예산을 확인해 볼까요? 💰",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: _primaryColor,
              size: 30,
            ), // ✨ 아이콘 변경 및 색상 통일
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 2. 요약 카드 (Summation Card)
  // ----------------------------------------------------
  Widget _SummationCard({
    required int totalIncomeWon,
    required int totalExpenseWon,
  }) {
    final balanceWon = totalIncomeWon - totalExpenseWon;
    final f = NumberFormat('#,###');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem(
              "총 수입",
              "${f.format(totalIncomeWon)}원",
              _primaryColor,
              Icons.add_circle_outline,
            ),
            _summaryItem(
              "총 지출",
              "${f.format(totalExpenseWon)}원",
              Colors.redAccent,
              Icons.remove_circle_outline,
            ),
            _summaryItem(
              "잔액",
              "${f.format(balanceWon)}원",
              Colors.blueAccent,
              Icons.account_balance_wallet_outlined,
            ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
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

  Widget _GoalCard({
    required int monthlyBudgetWon,
    required int usedExpenseWon,
  }) {
    final f = NumberFormat('#,###');

    final usedRatio = monthlyBudgetWon > 0
        ? usedExpenseWon / monthlyBudgetWon
        : 0.0;
    final clampedRatio = usedRatio.clamp(0.0, 1.0).toDouble(); // 0~1 사이
    final leftWon = monthlyBudgetWon > usedExpenseWon
        ? (monthlyBudgetWon - usedExpenseWon)
        : 0;
    final percent = (usedRatio * 100).toStringAsFixed(0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: const Icon(
          Icons.track_changes_rounded,
          color: _primaryColor,
          size: 36,
        ),
        title: Text(
          "이번 달 예산: ${f.format(monthlyBudgetWon)}원",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              "$percent% 사용 (남은 예산 ${f.format(leftWon)}원)",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: clampedRatio,
                minHeight: 10,
                color: _primaryColor,
                backgroundColor: _secondaryColor,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
        onTap: () {
          // 예산 상세 화면 이동 등
        },
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 4. 카테고리 요약 카드 (Category Summary Card)
  // ----------------------------------------------------
  Widget _CategorySummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // ✨ 모서리 둥글게
      elevation: 4, // ✨ 그림자 강화
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "가장 많은 지출 (Top 4)", // 문구 수정
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _categoryItem(
                  Icons.local_dining_rounded,
                  "식비",
                  "600,000원",
                  Colors.orange,
                ),
                _categoryItem(
                  Icons.shopping_bag_rounded,
                  "쇼핑",
                  "400,000원",
                  Colors.purple,
                ),
                _categoryItem(
                  Icons.home_work_rounded,
                  "주거",
                  "300,000원",
                  Colors.blue,
                ),
                _categoryItem(
                  Icons.favorite_rounded,
                  "취미",
                  "200,000원",
                  Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _categoryItem(
    IconData icon,
    String name,
    String amount,
    Color color,
  ) {
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
          Text(
            name,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ✅ 5. 최근 거래 카드 (Recent Transaction Card)
  // ----------------------------------------------------
  Widget _RecentTransactionCard({
    required List<TransactionEntity> transactions,
  }) {
    // transactions 리스트가 비어있으면 처리
    if (transactions.isEmpty) {
      return const SizedBox.shrink(); // 아무것도 표시하지 않음
    }

    // ⭐️ TransactionDetailScreen에서 정의된 상수를 사용합니다.
    const Color _primaryColor = Color(0xFF4CAF50); // 수입 강조 (녹색 계열)
    const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        // ✅ TransactionEntity 리스트의 처음 3개 항목만 사용
        children: transactions.take(3).map((tx) {
          final amount = tx.amount;
          final typeKey = tx.categoryId; // TransactionEntity에서 categoryId 사용

          // 1. 거래 타입 정보 조회
          final typeInfo = transactionTypes[typeKey];
          final isExpense = typeInfo?['isExpense'] as bool? ?? (amount < 0);

          // 2. 색상, 아이콘, 제목 결정
          final color = isExpense ? _expenseColor : _primaryColor;
          // Map에서 아이콘을 가져오고, 없으면 기본 아이콘 사용
          final iconData =
              typeInfo?['icon'] as IconData? ??
              (isExpense
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline);
          // Map에서 이름을 가져오고, 없으면 '지출'/'수입' 기본값 사용
          final title =
              typeInfo?['name'] as String? ?? (isExpense ? '지출' : '수입');

          // 3. 금액 텍스트 포맷
          final formattedAmount = NumberFormat('#,###').format(amount.abs());
          final amountText = "${isExpense ? '-' : '+'}$formattedAmount원";

          // 4. 아이콘 배경색
          final iconBackgroundColor = color.withOpacity(0.15);

          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: color, size: 28),
                ),
                title: Text(
                  title, // 카테고리 이름 사용
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  tx.createdAt, // TransactionEntity에서 createdAt 사용
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 16,
                    color: color, // 지출/수입 색상 적용
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // TODO: 거래 상세 화면으로 이동 로직 추가
                },
              ),
              // ✅ 마지막 항목이 아닌 경우에만 Divider 표시
              if (tx != transactions.take(3).last)
                const Padding(
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
