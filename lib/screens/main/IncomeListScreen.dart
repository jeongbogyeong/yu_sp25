import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartmoney/screens/main/MyIncomeScreen.dart';

const Color _primaryColor = Color(0xFF4CAF50);
const Color _secondaryColor = Color(0xFFF0F4F8);

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

// 🔹 추가 수입원 1개를 표현하는 뷰 모델
class _ExtraIncomeView {
  final String name;
  final int? payDay; // 1~28일
  final int? amount10k; // 십만 원 단위

  const _ExtraIncomeView({required this.name, this.payDay, this.amount10k});
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  bool _isLoading = false;

  // 기본 수입/월급 정보
  String _mainIncomeType = 'SALARY';
  int? _salaryDay;
  int _salaryAmount10k = 0;

  // 추가 수입원 리스트 (이름 + 금액 + 지급일)
  final List<_ExtraIncomeView> _extraIncomes = [];

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = session.user.id;

      // 1) userInfo_table 에서 기본 수입 정보 가져오기
      final userInfo = await _client
          .from('userInfo_table')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (userInfo != null) {
        _mainIncomeType =
            (userInfo['incomeType'] as String?) ?? _mainIncomeType;

        // 숫자 컬럼은 num? 로 받은 뒤 toInt() 해주는 게 안전함
        _salaryDay = (userInfo['salaryDay'] as num?)?.toInt();
        _salaryAmount10k = (userInfo['salaryAmount10k'] as num?)?.toInt() ?? 0;
      }

      // 2) user_extra_income_table 에서 추가 수입원 가져오기
      final extraRows = await _client
          .from('user_extra_income_table')
          .select()
          .eq('uid', uid);

      _extraIncomes.clear();
      if (extraRows is List) {
        for (final row in extraRows) {
          final name = (row['incomeName'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;

          // amount10k(새 필드) 우선, 없으면 예전 incomeAmount10k 사용
          final num? rawAmount =
              (row['amount10k'] ?? row['incomeAmount10k']) as num?;
          final num? rawPayDay = row['payDay'] as num?;

          _extraIncomes.add(
            _ExtraIncomeView(
              name: name,
              amount10k: rawAmount?.toInt(),
              payDay: rawPayDay?.toInt(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수입 정보를 불러오는 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapIncomeTypeToLabel(String code) {
    switch (code) {
      case 'PART_TIME':
        return '아르바이트 월급';
      case 'SALARY':
        return '회사원(월급)';
      case 'ALLOWANCE':
        return '용돈';
      default:
        return '기타';
    }
  }

  String _formatAmountFrom10k(int? amount10k) {
    if (amount10k == null || amount10k <= 0) {
      return '금액 미설정';
    }
    final amount = amount10k * 100000; // 십만 원 → 원
    final f = NumberFormat('#,###');
    return '₩ ${f.format(amount)}';
  }

  String _formatSalaryAmount() => _formatAmountFrom10k(_salaryAmount10k);

  String _formatPayDay(int? day) {
    if (day == null) return '지급일 미설정';
    return '매월 $day일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("내 모든 수입원"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncomeData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGoToSettingsCard(context),
                  const SizedBox(height: 16),
                  _buildMainIncomeCard(),
                  const SizedBox(height: 16),
                  _buildSalaryInfoCard(),
                  const SizedBox(height: 16),
                  _buildExtraIncomeCard(), // ✅ 여기서 쿠팡이츠 밑에 날짜+금액 뜸
                ],
              ),
            ),
    );
  }

  // 🔹 수입원 설정 화면으로 이동하는 카드
  Widget _buildGoToSettingsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.tune_rounded, color: _primaryColor),
        title: const Text(
          "수입원 · 월급 설정",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "주 수입원, 월급날, 추가 수입원을 수정할 수 있어요.",
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyIncomeScreen()),
          );
        },
      ),
    );
  }

  // 🔹 주 수입원 카드
  Widget _buildMainIncomeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.work_outline, color: _primaryColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "주 수입원",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mapIncomeTypeToLabel(_mainIncomeType),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "월급, 아르바이트, 용돈 등 중에서 가장 큰 비중을 차지하는 수입원입니다.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 월급 날짜 + 금액 카드
  Widget _buildSalaryInfoCard() {
    final salaryDayLabel = _salaryDay == null ? '미설정' : '매월 $_salaryDay일';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "월급 정보",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  "월급날",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  salaryDayLabel,
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
                  "월급 (실수령, 추정)",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  _formatSalaryAmount(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 추가 수입원 리스트 카드
  Widget _buildExtraIncomeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "추가 수입원",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "아르바이트를 여러 개 하거나 투잡을 뛰는 경우, 여기에서 한눈에 볼 수 있어요.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (_extraIncomes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "등록된 추가 수입원이 없습니다.",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              )
            else
              Column(
                children: _extraIncomes.map((item) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.add_card_rounded,
                      color: _primaryColor,
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    // ✅ 여기서 쿠팡이츠 밑에 "매월 00일 · ₩ xxx,xxx" 표시
                    subtitle: Text(
                      '${_formatPayDay(item.payDay)} · ${_formatAmountFrom10k(item.amount10k)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
