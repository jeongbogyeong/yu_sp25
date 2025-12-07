import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _primaryColor = Color(0xFF4CAF50);
const Color _secondaryColor = Color(0xFFF0F4F8);

// ✅ 추가 수입원 하나를 구성하는 내부 모델 (이름 + 금액 + 지급일)
class _ExtraIncomeInput {
  final TextEditingController nameController;
  final TextEditingController amountController; // 십만 원 단위
  int? payDay; // 1~28일

  _ExtraIncomeInput({
    required this.nameController,
    required this.amountController,
    this.payDay,
  });

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class MyIncomeScreen extends StatefulWidget {
  const MyIncomeScreen({super.key});

  @override
  State<MyIncomeScreen> createState() => _MyIncomeScreenState();
}

class _MyIncomeScreenState extends State<MyIncomeScreen> {
  // 주 수입원 (회원가입 때 선택한 값과 동일한 ENUM 코드 사용)
  String _mainIncomeType = 'SALARY'; // 기본값: 회사원(월급)

  // ✅ 추가 수입원 리스트 (이름 + 금액 + 지급일)
  final List<_ExtraIncomeInput> _extraIncomes = [];

  // 월급날 (1~31 중 선택, 아직 설정 안 했으면 null)
  int? _salaryDay;

  // 월급 금액 (십만 원 단위, 예: 200 → 2,000,000원)
  int _salaryAmount10k = 0;

  bool _isLoading = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadIncomeSettings();
  }

  @override
  void dispose() {
    for (final e in _extraIncomes) {
      e.dispose();
    }
    super.dispose();
  }

  // ----------------------------------------------------
  // 🔹 DB에서 내 수입/월급 설정 불러오기
  // ----------------------------------------------------
  Future<void> _loadIncomeSettings() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      // 로그인 안 된 상태면 그냥 리턴
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = session.user.id;

      // 1) userInfo_table 에서 기본 설정 가져오기
      final userInfo = await _client
          .from('userInfo_table')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (userInfo != null) {
        _mainIncomeType =
            (userInfo['incomeType'] as String?) ?? _mainIncomeType;

        // 숫자 컬럼은 num? 로 받은 뒤 toInt()로 변환 (double 대비)
        _salaryDay = (userInfo['salaryDay'] as num?)?.toInt();
        _salaryAmount10k = (userInfo['salaryAmount10k'] as num?)?.toInt() ?? 0;
      }

      // 2) user_extra_income_table 에서 추가 수입원 리스트 가져오기
      final extraRows = await _client
          .from('user_extra_income_table')
          .select()
          .eq('uid', uid);

      // 기존 데이터/컨트롤러 정리
      for (final e in _extraIncomes) {
        e.dispose();
      }
      _extraIncomes.clear();

      if (extraRows is List) {
        for (final row in extraRows) {
          final name = (row['incomeName'] as String?) ?? '';
          final amount10k = (row['amount10k'] as num?)?.toInt() ?? 0;
          final payDay = (row['payDay'] as num?)?.toInt();

          _extraIncomes.add(
            _ExtraIncomeInput(
              nameController: TextEditingController(text: name),
              amountController: TextEditingController(
                text: amount10k > 0 ? amount10k.toString() : '',
              ),
              payDay: payDay,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('설정을 불러오는 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("주 수입 · 월급 설정"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔴 월급날 미설정 경고 배너
                  if (_salaryDay == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        "아직 월급날을 설정하지 않으셨어요.\n"
                        "월급날을 설정해야 월급 기준 알림과 소비 계획 안내를 받을 수 있어요.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  _buildMainIncomeCard(),
                  const SizedBox(height: 16),
                  _buildExtraIncomeCard(),
                  const SizedBox(height: 16),
                  _buildSalaryDayCard(),
                  const SizedBox(height: 16),
                  _buildSalaryAmountCard(),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _onSavePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "설정 저장하기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------
  // 1) 주 수입원 카드
  // ----------------------------------------------------
  Widget _buildMainIncomeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "나의 주 수입원",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "월급, 아르바이트, 용돈 등 중에서 가장 큰 비중을 차지하는 수입원을 선택해 주세요.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mainIncomeType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'PART_TIME', child: Text('아르바이트 월급')),
                DropdownMenuItem(value: 'SALARY', child: Text('회사원(월급)')),
                DropdownMenuItem(value: 'ALLOWANCE', child: Text('용돈')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _mainIncomeType = v);
              },
              decoration: InputDecoration(
                labelText: "주 수입원 선택",
                prefixIcon: const Icon(
                  Icons.work_outline,
                  color: _primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 2) 추가 수입원 카드
  // ----------------------------------------------------
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
              "아르바이트를 여러 개 하거나 투잡을 뛰는 경우, 수입과 들어오는 날짜를 함께 적어둘 수 있어요.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // 기존 추가 수입 항목들
            Column(
              children: List.generate(_extraIncomes.length, (index) {
                final item = _extraIncomes[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    children: [
                      // 1) 수입원 이름
                      TextField(
                        controller: item.nameController,
                        decoration: InputDecoration(
                          labelText: "수입원 이름",
                          hintText: "예: 카페 알바, 쿠팡이츠 배달 등",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2) 월 수입 + 지급일 + 삭제 버튼
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item.amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "월 수입 (십만 원 단위)",
                                hintText: "예: 30 → 300,000원",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          DropdownButton<int>(
                            value: item.payDay,
                            hint: const Text("지급일"),
                            items: List.generate(
                              28,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text("${i + 1}일"),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                item.payDay = v;
                              });
                            },
                          ),

                          IconButton(
                            onPressed: () {
                              setState(() {
                                item.dispose();
                                _extraIncomes.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  _extraIncomes.add(
                    _ExtraIncomeInput(
                      nameController: TextEditingController(),
                      amountController: TextEditingController(),
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("추가 수입원 추가"),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 3) 월급날 설정 카드
  // ----------------------------------------------------
  Widget _buildSalaryDayCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "월급 날 설정",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "매달 정기적으로 들어오는 월급 기준 날짜를 설정해 주세요.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("매월 "),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _salaryDay,
                  hint: const Text("일 선택"),
                  items: List.generate(
                    28,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text("${index + 1}일"),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() => _salaryDay = v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 4) 월급 금액 설정 카드
  // ----------------------------------------------------
  Widget _buildSalaryAmountCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "월급 금액 (십만 원 단위)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "세금이나 다른 변수는 제외하고, 대략적인 실수령액을 십만 원 단위로 입력해 주세요.\n"
              "예: 200 → 2,000,000원",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "예: 200",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value) ?? 0;
                      setState(() {
                        _salaryAmount10k = parsed;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text("만 원"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 저장 버튼 눌렀을 때
  // ----------------------------------------------------
  Future<void> _onSavePressed() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    final uid = session.user.id;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) userInfo_table 업데이트
      await _client
          .from('userInfo_table')
          .update({
            'incomeType': _mainIncomeType,
            'salaryDay': _salaryDay,
            'salaryAmount10k': _salaryAmount10k,
          })
          .eq('uid', uid);

      // 2) 기존 추가 수입원 삭제 후 다시 저장
      await _client.from('user_extra_income_table').delete().eq('uid', uid);

      final rows = <Map<String, dynamic>>[];
      for (final item in _extraIncomes) {
        final name = item.nameController.text.trim();
        final amountStr = item.amountController.text.trim();
        final amount10k = int.tryParse(amountStr) ?? 0;

        if (name.isEmpty && amount10k == 0 && item.payDay == null) {
          // 완전 공백이면 스킵
          continue;
        }

        rows.add({
          'uid': uid,
          'incomeName': name,
          'amount10k': amount10k,
          'payDay': item.payDay,
        });
      }

      if (rows.isNotEmpty) {
        await _client.from('user_extra_income_table').insert(rows);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("수입/월급 설정이 저장되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("저장 중 오류가 발생했습니다: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
