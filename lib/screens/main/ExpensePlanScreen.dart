import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/notification/notification_service.dart';
import '../../service/notification/notification_definitions.dart';

import 'MyIncomeScreen.dart';

// ✨ 테마 색상 (앱 공통)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경
const Color _expenseColor = Color(0xFFEF5350); // 지출/경고

class ExpensePlanScreen extends StatefulWidget {
  const ExpensePlanScreen({super.key});

  @override
  State<ExpensePlanScreen> createState() => _ExpensePlanScreenState();
}

class _ExpensePlanScreenState extends State<ExpensePlanScreen> {
  final _rentController = TextEditingController(); // 월세
  final _savingController = TextEditingController(); // 적금/저축
  final _loanController = TextEditingController(); // 대출 이자

  // ✅ 기본 기타 고정비 1개 + 동적으로 추가되는 기타 고정비들
  final _etcFixedController = TextEditingController(); // 기타 고정비 (기본)
  final List<TextEditingController> _extraFixedControllers = []; // 추가 기타 고정비

  bool _isLoading = false;

  int? _salaryDay; // 월급 날짜 (1~31)
  int _salaryAmount10k = 0; // 10만 원 단위 (userInfo_table 과 동일)
  double? _livingBudget; // 이번 달 예상 생활비 (원 단위)

  // ✅ 현재 로그인한 유저 & 이번 달 계획 id 저장용
  String? _userId;
  String? _planId;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadInitData();
  }

  @override
  void dispose() {
    _rentController.dispose();
    _savingController.dispose();
    _loanController.dispose();
    _etcFixedController.dispose();
    for (final c in _extraFixedControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 최초 로딩: 유저/월급/기존 소비 계획 불러오기
  Future<void> _loadInitData() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    _userId = session.user.id;

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadIncomeInfo();
      await _loadExpensePlan(); // 🔥 DB에 저장된 이번 달 계획 있으면 불러오기
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// userInfo_table 에서 월급 정보 가져오기
  Future<void> _loadIncomeInfo() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final userInfo = await _client
          .from('userInfo_table')
          .select()
          .eq('uid', userId)
          .maybeSingle();

      if (userInfo != null) {
        _salaryDay = userInfo['salaryDay'] as int?;
        _salaryAmount10k = (userInfo['salaryAmount10k'] as int?) ?? 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('월급 정보를 불러오지 못했습니다: $e')));
      }
    }
  }

  /// expense_plan_table + expense_fixed_item_table 에서 이번 달 계획 불러오기
  Future<void> _loadExpensePlan() async {
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now();

    try {
      // 1) 이번 달 계획 row 조회
      final plan = await _client
          .from('expense_plan_table')
          .select()
          .eq('uid', userId)
          .eq('year', now.year)
          .eq('month', now.month)
          .maybeSingle();

      if (plan == null) return;

      _planId = plan['id'] as String;

      // 텍스트필드에 값 채우기 (int4 -> String)
      _rentController.text = (plan['rent'] ?? 0).toString();
      _savingController.text = (plan['saving'] ?? 0).toString();
      _loanController.text = (plan['loan'] ?? 0).toString();

      // 2) 기타 고정비들 조회
      final planId = _planId; // 🔹 로컬 변수로 복사
      if (planId == null) return;

      final fixedItems = await _client
          .from('expense_fixed_item_table')
          .select()
          .eq('plan_id', planId)
          .order('created_at');

      // 먼저 모두 비우기
      _etcFixedController.clear();
      for (final c in _extraFixedControllers) {
        c.dispose();
      }
      _extraFixedControllers.clear();

      if (fixedItems is List && fixedItems.isNotEmpty) {
        // 첫 번째 항목은 기본 필드에
        final first = fixedItems.first;
        _etcFixedController.text = (first['amount'] ?? 0).toString();

        // 나머지는 추가 필드로
        for (int i = 1; i < fixedItems.length; i++) {
          final item = fixedItems[i];
          final c = TextEditingController(
            text: (item['amount'] ?? 0).toString(),
          );
          _extraFixedControllers.add(c);
        }
      }

      // 불러온 값으로 다시 계산
      _recalculateLivingBudget();
      setState(() {}); // 화면 갱신
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장된 소비 계획을 불러오지 못했습니다: $e')));
      }
    }
  }

  // 월급(10만 원 단위)을 원 단위로 변환
  int get _salaryAmountWon => _salaryAmount10k * 100000;

  // 컨트롤러 값에서 숫자 파싱
  double _parseController(TextEditingController c) {
    if (c.text.trim().isEmpty) return 0;
    return double.tryParse(c.text.replaceAll(',', '')) ?? 0;
  }

  /// 버튼 눌렀을 때: 계산 + DB 저장
  Future<void> _calculatePlan() async {
    if (_salaryAmountWon <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 수입/월급 정보를 설정해 주세요.')));
      return;
    }

    final double rent = _parseController(_rentController);
    final double saving = _parseController(_savingController);
    final double loan = _parseController(_loanController);

    // ✅ 기타 고정비 = 기본 1개 + 추가로 만든 것들
    final double baseEtc = _parseController(_etcFixedController);
    final List<double> extraEtcList = _extraFixedControllers
        .map((c) => _parseController(c))
        .toList();
    final double etcTotal =
        baseEtc + extraEtcList.fold<double>(0, (sum, v) => sum + v);

    final double totalFixed = rent + saving + loan + etcTotal;
    // int - double → double로 명시
    final double living = _salaryAmountWon.toDouble() - totalFixed;

    setState(() {
      _livingBudget = living;
    });

    // 🔥 DB 저장
    try {
      await _savePlanToDb(
        rent: rent,
        saving: saving,
        loan: loan,
        etcList: [baseEtc, ...extraEtcList],
      );

      // ✅ 여기서 하루 예산 계산해서 알림(type 3)에 반영
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final remainingDays = daysInMonth - now.day + 1; // 오늘 포함
      final double daily = remainingDays > 0
          ? living / remainingDays
          : 0.0; // 오늘 쓸 수 있는 예산

      // NotificationDefinition 중 type == 3(오늘의 예산 확인) 찾기
      final def = notificationDefinitions.firstWhere(
        (d) => d.type == 3,
        orElse: () => notificationDefinitions[0],
      );

      // 🔔 하루 예산을 body에 반영해서 매일 8시에 울리도록 재등록
      NotificationService.scheduleNotificationByType(def, dailyBudget: daily);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이번 달 소비 계획이 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    }
  }

  /// livingBudget 재계산 (DB에서 불러왔을 때 사용)
  void _recalculateLivingBudget() {
    if (_salaryAmountWon <= 0) return;

    final rent = _parseController(_rentController);
    final saving = _parseController(_savingController);
    final loan = _parseController(_loanController);
    final baseEtc = _parseController(_etcFixedController);
    final extraEtcList = _extraFixedControllers
        .map((c) => _parseController(c))
        .toList();
    final etcTotal =
        baseEtc + extraEtcList.fold<double>(0, (sum, v) => sum + v);

    final totalFixed = rent + saving + loan + etcTotal;
    _livingBudget = _salaryAmountWon - totalFixed;
  }

  /// 🔥 expense_plan_table + expense_fixed_item_table 에 저장
  Future<void> _savePlanToDb({
    required double rent,
    required double saving,
    required double loan,
    required List<double> etcList, // [기타1, 기타2, ...]
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now();

    // 1) expense_plan_table 에 계획 저장 (insert or update)
    if (_planId == null) {
      // 새로 생성
      final inserted = await _client
          .from('expense_plan_table')
          .insert({
            'uid': userId,
            'year': now.year,
            'month': now.month,
            'rent': rent.round(),
            'saving': saving.round(),
            'loan': loan.round(),
          })
          .select()
          .single();

      _planId = inserted['id'] as String;
    } else {
      final planId = _planId!;
      // 기존 row 업데이트
      await _client
          .from('expense_plan_table')
          .update({
            'rent': rent.round(),
            'saving': saving.round(),
            'loan': loan.round(),
          })
          .eq('id', planId)
          .select()
          .single();
    }

    // 2) expense_fixed_item_table 에 기타 고정비들 저장
    final planId = _planId;
    if (planId == null) return;

    // 기존 기타 고정비 전부 삭제 후 다시 insert
    await _client
        .from('expense_fixed_item_table')
        .delete()
        .eq('plan_id', planId);

    int idx = 1;
    for (final amount in etcList) {
      if (amount <= 0) continue; // 0원/빈 값은 저장 안 함

      await _client.from('expense_fixed_item_table').insert({
        'plan_id': planId,
        'label': '기타 고정비 $idx',
        'amount': amount.round(),
      });

      idx++;
    }
  }

  String _formatWon(num value) {
    final f = NumberFormat('#,###');
    return '${f.format(value.round())}원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("이번달 소비 계획"),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSalarySummaryCard(),
                  const SizedBox(height: 20),
                  _buildFixedExpenseCard(),
                  const SizedBox(height: 20),
                  _buildResultCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // 1) 월급 요약 카드 + “월급날 알림” 컨셉
  Widget _buildSalarySummaryCard() {
    final salarySet = _salaryAmountWon > 0 && _salaryDay != null;
    final monthLabel = DateFormat('yyyy년 MM월').format(DateTime.now());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$monthLabel 월급 정보",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (!salarySet) ...[
              const Text(
                "아직 월급날 또는 월급 금액이 설정되지 않았어요.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyIncomeScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("수입 · 월급 정보 설정하러 가기"),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "월급날",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    "매월 $_salaryDay일",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "월급 (실수령 / 추정)",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    _formatWon(_salaryAmountWon),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "월급 들어오는 날에 \"이번달 소비 계획 세우기\" 알림을 보내도록\n"
                      "알림 설정 화면에서 스케줄링할 수 있어요.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 2) 고정 지출 입력 카드 (월세, 적금, 대출이자, 기타 고정비)
  Widget _buildFixedExpenseCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "고정 지출 입력",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "적금, 월세, 대출 이자 등 매달 거의 동일하게 빠져나가는 금액만 입력해 주세요.\n"
              "세금, 계절별 생활비 등 변동이 큰 항목은 제외합니다.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildMoneyField("월세", _rentController, hint: "예: 500000"),
            const SizedBox(height: 10),
            _buildMoneyField("적금 · 저축", _savingController, hint: "예: 300000"),
            const SizedBox(height: 10),
            _buildMoneyField("대출 이자", _loanController, hint: "예: 200000"),
            const SizedBox(height: 10),

            // ✅ 기본 기타 고정비 1개
            _buildMoneyField(
              "기타 고정비",
              _etcFixedController,
              hint: "통신비, 구독 서비스 등",
            ),
            const SizedBox(height: 10),

            // ✅ 추가된 기타 고정비들 (n개)
            Column(
              children: [
                for (int i = 0; i < _extraFixedControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMoneyField(
                            "기타 고정비 ${i + 2}",
                            _extraFixedControllers[i],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _extraFixedControllers[i].dispose();
                              _extraFixedControllers.removeAt(i);
                            });
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: _expenseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _extraFixedControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: _primaryColor,
                    ),
                    label: const Text(
                      "기타 고정비 추가",
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculatePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "이번달 소비 계획 계산·저장하기",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? "원 단위로 입력",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixText: "₩ ",
      ),
    );
  }

  // 3) 결과 카드 – 예상 생활비, 하루 평균 등
  Widget _buildResultCard() {
    if (_livingBudget == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: Colors.transparent,
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Text(
            "고정 지출을 입력한 뒤, \"이번달 소비 계획 계산하기\" 버튼을 눌러주세요.",
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = daysInMonth - now.day + 1; // 오늘 포함
    final double daily = remainingDays > 0
        ? _livingBudget! / remainingDays
        : 0.0;

    final isOver = _livingBudget! < 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "이번달 예상 생활비",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  isOver ? "부족 금액" : "남은 생활비",
                  style: TextStyle(
                    fontSize: 14,
                    color: isOver ? _expenseColor : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatWon(_livingBudget!.abs()),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isOver ? _expenseColor : _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 20),
            Row(
              children: [
                const Text(
                  "남은 기간 하루당 쓸 수 있는 금액",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  _formatWon(daily.isNaN ? 0 : daily),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "오늘 포함 ${remainingDays}일 기준",
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
