import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // _ThousandsFormatter를 위해 필요
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/transaction_entity.dart';
import '../viewmodels/TransactionViewModel.dart';
import '../viewmodels/UserViewModel.dart';

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

const Map<int, String> paymentMethods = {
  0: '현금',
  1: '카드',
  2: '계좌이체',
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
  bool _isEditing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId = Provider.of<UserViewModel>(context, listen: false).user!.id;
      Provider.of<TransactionViewModel>(context, listen: false).getTransactions(currentUserId);
    });
  }

  // ✅ dispose에서 컨트롤러 해제
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ✅ 2. 삭제 함수 (ViewModel 연결)
  // ----------------------------------------------------
  void _deleteTransaction(TransactionEntity transaction) async {
    final viewModel = Provider.of<TransactionViewModel>(context, listen: false);

    final bool success = await viewModel.deleteTransaction(transaction.id);

    if (success) {
      //final String currentUserId = Provider.of<UserViewModel>(context, listen: false).user!.id;
      //await viewModel.getTransactions(currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래 내역이 삭제되었습니다.'), duration: Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래 내역 삭제에 실패했습니다.')),
      );
    }
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
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing; // 상태 토글
              });
            },
            child: Text(
              _isEditing ? '완료' : '편집',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TransactionViewModel>( // ✅ Consumer로 ViewModel 구독
        builder: (context, viewModel, child) {
          final transactions = viewModel.transactions;

          if (transactions == null) {
            // 로딩 중이거나 아직 데이터를 가져오지 못했을 때
            return const Center(child: CircularProgressIndicator(color: _primaryColor));
          }

          if (transactions.isEmpty) {
            return const Center(
              child: Text("아직 등록된 거래 내역이 없습니다.", style: TextStyle(color: Colors.grey)),
            );
          }

          return Padding(
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
                        controller: _scrollController,
                        itemCount: transactions.length, // ✅ ViewModel 데이터 사용
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
                        ),
                        itemBuilder: (context, index) {
                          final tx = transactions[index]; // ✅ TransactionEntity 사용
                          return _buildTransactionTile(tx);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      // FAB (Floating Action Button) 추가
      floatingActionButton: Visibility(
        visible: !_isEditing,
        child: FloatingActionButton(
          onPressed: () => _showAddTransactionForm(context),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          tooltip: '거래 내역 추가',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // ## 2. 거래 내역 타일 위젯
  // ----------------------------------------------------
  Widget _buildTransactionTile(TransactionEntity tx) { // ✅ Map 대신 TransactionEntity 받음
    final amount = tx.amount;
    final typeKey = tx.categoryId;
    final isExpense = transactionTypes[typeKey]?['isExpense'] ?? amount < 0;

    final formattedAmount = NumberFormat('#,###').format(amount.abs());

    // 거래 타입 정보 조회
    final typeInfo = transactionTypes[typeKey];
    final title = typeInfo?['name'] ?? '알 수 없는 카테고리';
    final icon = typeInfo?['icon'] ?? Icons.category;
    final color = isExpense ? _expenseColor : _incomeColor;

    final iconBackgroundColor = color.withOpacity(0.1);

    // ✅ 결제 수단 정보 추가 (paymentMethod는 TransactionEntity에 있어야 함)
    final paymentKey = tx.assetId;
    final paymentName = paymentMethods[paymentKey] ?? '알 수 없음';

    IconData paymentIcon;
    if (paymentKey == 0) {
      paymentIcon = Icons.money_off; // 현금
    } else if (paymentKey == 1) {
      paymentIcon = Icons.credit_card; // 카드
    } else {
      paymentIcon = Icons.compare_arrows; // 계좌이체
    }

    return ListTile(
      // ✅ leading: 편집 모드에 따라 아이콘 또는 삭제 버튼 표시
      leading: _isEditing
          ? IconButton(
        icon: const Icon(
          Icons.remove_circle, // 삭제 버튼 아이콘
          color: _expenseColor, // 빨간색
          size: 28,
        ),
        onPressed: () => _deleteTransaction(tx), // 삭제 함수 호출
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      )
          : Container(
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

      // 메모 및 결제 수단
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx.memo ?? '메모 없음', // ✅ TransactionEntity 필드 사용
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                paymentIcon,
                size: 14,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
              Text(
                paymentName,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
            tx.createdAt, // ✅ TransactionEntity 필드 사용
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
    // ViewModel 인스턴스를 미리 가져옵니다.
    final viewModel = Provider.of<TransactionViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          child: SingleChildScrollView(
            child: AddTransactionForm(
              onSave: (newTransaction) async { // ✅ 비동기 처리

                final success = await viewModel.insertTranaction(newTransaction);

                // 2. 팝업 닫기
                Navigator.pop(ctx);

                if (success) {
                  // 3. 성공 시 리스트 최상단으로 스크롤 (ViewModel에서 notifyListeners가 호출되면
                  //    Consumer가 리빌드되므로 스크롤 이동만 처리)
                  // List가 비어있지 않다면 (성공적으로 추가되었다면)
                  if (viewModel.transactions != null && viewModel.transactions!.isNotEmpty) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                } else {
                  // TODO: 실패 시 사용자에게 알림 (예: Snackbar 또는 CommonDialog)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('거래 내역 저장에 실패했습니다.')),
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
  final Function(TransactionEntity) onSave;

  const AddTransactionForm({super.key, required this.onSave});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedTypeKey;
  int? _selectedPaymentMethod;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedTypeKey = 0; // 초기 선택은 '식비' (키 0)
    _selectedPaymentMethod = 1; // 초기 선택은 '카드' (키 1)
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

      // TODO: 사용자 ID는 실제 앱에서는 Auth ViewModel 등에서 가져와야 합니다.
      final int accountNum = Provider.of<UserViewModel>(context, listen: false).user!.account_number;

      // ✅ TransactionEntity 객체 생성 (Map 대신)
      final newTransaction = TransactionEntity(
        id: 0, // DB에서 할당되므로 0으로 설정
        accountNumber: accountNum,
        categoryId: _selectedTypeKey!,
        amount: finalAmount,
        memo: _memoController.text.trim(),
        createdAt: DateFormat('yyyy-MM-dd').format(_selectedDate).toString(),
        assetId: _selectedPaymentMethod!,
      );

      widget.onSave(newTransaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build 메서드 내용 유지) ...
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

            // ✅ 1-2. 결제 수단 선택 (새로 추가)
            _buildPaymentDropdown(),
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

  //결제 수단 드롭다운 위젯
  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedPaymentMethod,
      decoration: const InputDecoration(
        labelText: '결제 수단',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: paymentMethods.entries.map((entry) {
        final key = entry.key;
        final name = entry.value;

        IconData icon;
        if (key == 0) {
          icon = Icons.money_off; // 현금
        } else if (key == 1) {
          icon = Icons.credit_card; // 카드
        } else {
          icon = Icons.compare_arrows; // 계좌이체
        }

        return DropdownMenuItem<int>(
          value: key,
          child: Row(
            children: [
              Icon(icon, color: _primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedPaymentMethod = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return '결제 수단을 선택해주세요.';
        }
        return null;
      },
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

