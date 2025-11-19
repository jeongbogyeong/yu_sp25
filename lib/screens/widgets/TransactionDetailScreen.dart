import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // _ThousandsFormatter를 위해 필요
import 'package:intl/intl.dart';

// ✨ 테마 색상 정의 (다른 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 수입 강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색
const Color _expenseColor = Color(0xFFEF5350); // 지출 강조 (빨간색 계열)
const Color _incomeColor = _primaryColor;

// ----------------------------------------------------
// ✅ 17가지 거래 타입 및 아이콘 정의
// ----------------------------------------------------
const Map<int, Map<String, dynamic>> transactionTypes = {
  // 지출 (Expense)
  0: {'name': '식비', 'icon': Icons.fastfood, 'isExpense': true, 'color': Color(0xFFFFA726)},
  1: {'name': '교통/차량', 'icon': Icons.directions_car, 'isExpense': true, 'color': Color(0xFF42A5F5)},
  2: {'name': '문화생활', 'icon': Icons.movie, 'isExpense': true, 'color': Color(0xFF8D6E63)},
  3: {'name': '마트/편의점', 'icon': Icons.shopping_basket, 'isExpense': true, 'color': Color(0xFFEF5350)},
  4: {'name': '패션/미용', 'icon': Icons.brush, 'isExpense': true, 'color': Color(0xFFEC407A)},
  5: {'name': '생활용품', 'icon': Icons.home, 'isExpense': true, 'color': Color(0xFF66BB6A)},
  6: {'name': '주거/통신', 'icon': Icons.phone_android, 'isExpense': true, 'color': Color(0xFFAB47BC)},
  7: {'name': '병원비/약값', 'icon': Icons.local_hospital, 'isExpense': true, 'color': Color(0xFF78909C)},
  8: {'name': '교육', 'icon': Icons.school, 'isExpense': true, 'color': Color(0xFF26A69A)},
  9: {'name': '경조사/회비', 'icon': Icons.people, 'isExpense': true, 'color': Color(0xFFFFCA28)},
  10: {'name': '기타(지출)', 'icon': Icons.more_horiz, 'isExpense': true, 'color': Color(0xFFBDBDBD)},

  // 수입 (Income)
  11: {'name': '월급', 'icon': Icons.account_balance_wallet, 'isExpense': false, 'color': _incomeColor},
  12: {'name': '부수입', 'icon': Icons.work, 'isExpense': false, 'color': Color(0xFF64B5F6)},
  13: {'name': '용돈', 'icon': Icons.card_giftcard, 'isExpense': false, 'color': Color(0xFFFF7043)},
  14: {'name': '상여', 'icon': Icons.star, 'isExpense': false, 'color': Color(0xFFD4E157)},
  15: {'name': '금융소득', 'icon': Icons.trending_up, 'isExpense': false, 'color': Color(0xFF4DB6AC)},
  16: {'name': '기타(수입)', 'icon': Icons.attach_money, 'isExpense': false, 'color': Color(0xFF9CCC65)},
};


class TransactionDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialTransactions;

  const TransactionDetailScreen({
    super.key,
    required this.initialTransactions,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {

  // ✅ 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();
  late TransactionDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TransactionDetailViewModel(widget.initialTransactions);
  }

  // ✅ dispose에서 컨트롤러 해제
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ## 1. 빌드 메서드
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("최근 거래 내역"),
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _secondaryColor,
        elevation: 0.0,
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

            // 거래 내역 리스트
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
                    // ✅ 스크롤 컨트롤러 연결
                    controller: _scrollController,
                    itemCount: _viewModel.transactions.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
                    ),
                    itemBuilder: (context, index) {
                      final tx = _viewModel.transactions[index];
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
      // FAB (Floating Action Button) 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionForm(context),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        tooltip: '거래 내역 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 2. 거래 내역 타일 위젯
  // ----------------------------------------------------
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = tx['amount'] as int;
    // typeKey가 없는 경우를 대비해 널 안전 처리 및 기본값 설정
    final typeKey = tx['typeKey'] as int? ?? (amount < 0 ? 0 : 11);
    final isExpense = transactionTypes[typeKey]?['isExpense'] ?? amount < 0;

    final formattedAmount = NumberFormat('#,###').format(amount.abs());

    // 거래 타입 정보 조회
    final typeInfo = transactionTypes[typeKey];
    final title = typeInfo?['name'] ?? '알 수 없는 카테고리';
    final icon = typeInfo?['icon'] ?? Icons.category;
    final color = isExpense ? _expenseColor : _incomeColor;

    final iconBackgroundColor = color.withOpacity(0.1);

    return ListTile(
      // 카테고리 아이콘
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon as IconData, color: color, size: 24),
      ),

      // 거래 제목 (카테고리 이름)
      title: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87
        ),
      ),

      // 메모
      subtitle: Text(
        tx['memo'] ?? '메모 없음',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),

      // 금액 및 날짜
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${isExpense ? '-' : '+'}$formattedAmount원",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tx['date'],
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ## 3. 거래 내역 추가 폼 팝업
  // ----------------------------------------------------
  void _showAddTransactionForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        // ✅ Dialog 위젯을 사용하여 폼을 화면 중앙에 표시
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          // SingleChildScrollView로 감싸 키보드가 올라와도 폼이 가려지지 않게 처리
          child: SingleChildScrollView(
            child: AddTransactionForm(
              onSave: (newTransaction) {
                // 1. 상태 업데이트 및 내역 추가 (리빌드 예약)
                setState(() {
                  _viewModel.addTransaction(newTransaction);
                });

                // 2. 팝업 닫기
                Navigator.pop(ctx);

                // 3. 새로운 거래 내역이 보이도록 리스트 최상단으로 스크롤
                if (_viewModel.transactions.isNotEmpty) {
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ****************************************************
// ✅ 거래 내역 추가 폼 (Bottom Sheet)
// ****************************************************
class AddTransactionForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddTransactionForm({super.key, required this.onSave});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedTypeKey;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedTypeKey = 0; // 초기 선택은 '식비' (키 0)
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final isExpense = transactionTypes[_selectedTypeKey]!['isExpense'] as bool;

      final rawAmount = _amountController.text.replaceAll(RegExp(r','), '');
      final amount = int.tryParse(rawAmount) ?? 0;

      final finalAmount = isExpense ? -amount.abs() : amount.abs();

      final newTransaction = {
        'typeKey': _selectedTypeKey!,
        'amount': finalAmount,
        'memo': _memoController.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      widget.onSave(newTransaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "거래 내역 추가",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 20, thickness: 1, color: Colors.black12),

            // 1. 거래 타입 선택 (Dropdown)
            _buildTypeDropdown(),
            const SizedBox(height: 15),

            // 2. 거래액 입력
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '거래액 (원)',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [_ThousandsFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty || int.tryParse(value.replaceAll(RegExp(r','), '')) == 0) {
                  return '거래액을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // 3. 메모 입력
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택 사항)',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 5),

            // 4. 거래 날짜 선택
            _buildDateSelector(context),
            const SizedBox(height: 20),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 드롭다운 위젯
  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedTypeKey,
      // ✅ 리스트 최대 높이 설정하여 스크롤 가능하게 만듦
      menuMaxHeight: 350,
      decoration: const InputDecoration(
        labelText: '거래 타입',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: transactionTypes.entries.map((entry) {
        final key = entry.key;
        final info = entry.value;
        final color = info['isExpense'] ? _expenseColor : _incomeColor;

        return DropdownMenuItem<int>(
          value: key,
          child: Row(
            children: [
              Icon(info['icon'] as IconData, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                '${info['isExpense'] ? '[지출]' : '[수입]'} ${info['name']}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedTypeKey = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return '거래 타입을 선택해주세요.';
        }
        return null;
      },
    );
  }

  // 날짜 선택 위젯
  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 15),
                Text(
                  DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}


// ****************************************************
// 콤마 포맷터 클래스 (TextField용)
// ****************************************************
class _ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r','), '');
    final int? number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final String newText = _formatter.format(number);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// ****************************************************
// 임시 데이터 처리 뷰 모델 (DB 대신 내부 메모리 사용)
// ****************************************************
class TransactionDetailViewModel {
  List<Map<String, dynamic>> _transactions;

  TransactionDetailViewModel(this._transactions);

  List<Map<String, dynamic>> get transactions => _transactions;

  void addTransaction(Map<String, dynamic> newTransaction) {
    // 가장 최근 거래가 맨 위에 오도록 리스트 맨 앞에 추가
    _transactions.insert(0, newTransaction);
  }
}