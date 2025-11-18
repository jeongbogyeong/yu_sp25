import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum EntryType { income, expense }
enum AssetType { cash, bank, card }

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  EntryType _entryType = EntryType.expense;
  AssetType _assetType = AssetType.cash;

  int? _selectedCategoryIndex;
  bool _showCustomCategoryField = false;
  bool _saving = false;

  // 🔹 지출 카테고리
  final List<String> expenseCategories = [
    '식비',
    '교통/차량',
    '문화생활',
    '마트/편의점',
    '패션/미용',
    '생활용품',
    '주거/통신',
    '병원비/약값',
    '교육',
    '경조사/회비',
    '기타',
    '추가',
  ];

  // 🔹 수입 카테고리
  final List<String> incomeCategories = [
    '월급',
    '부수입',
    '용돈',
    '상여',
    '금융소득',
    '기타',
    '추가',
  ];

  List<String> get _currentCategories =>
      _entryType == EntryType.expense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택하세요.')),
      );
      return;
    }

    final categories = _currentCategories;
    String category = '';

    // "추가" 선택 시
    if (categories[_selectedCategoryIndex!] == '추가') {
      if (_customCategoryCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 카테고리 이름을 입력하세요.')),
        );
        return;
      }
      category = _customCategoryCtrl.text.trim();

      // 리스트에 새 카테고리 추가 (추가 앞에)
      setState(() {
        categories.insert(categories.length - 1, category);
      });
    } else {
      category = categories[_selectedCategoryIndex!];
    }

    setState(() => _saving = true);

    final payload = {
      'entry_type': _entryType == EntryType.income ? 'INCOME' : 'EXPENSE',
      'amount': double.parse(_amountCtrl.text),
      'category_name': category,
      'asset': _assetType.name.toUpperCase(), // CASH / BANK / CARD
      'memo': _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      'occurred_at': DateTime.now().toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('entries').insert(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 완료!')),
      );

      _amountCtrl.clear();
      _memoCtrl.clear();
      _customCategoryCtrl.clear();
      setState(() {
        _selectedCategoryIndex = null;
        _showCustomCategoryField = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _currentCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('입금 / 출금 기록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🔹 출금 / 입금 토글
              SegmentedButton<EntryType>(
                segments: const [
                  ButtonSegment(
                    value: EntryType.expense,
                    label: Text('출금'),
                  ),
                  ButtonSegment(
                    value: EntryType.income,
                    label: Text('입금'),
                  ),
                ],
                selected: {_entryType},
                onSelectionChanged: (s) {
                  setState(() {
                    _entryType = s.first;
                    _selectedCategoryIndex = null;
                    _showCustomCategoryField = false;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 🔹 금액
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: '금액',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                (v == null || v.isEmpty) ? '금액을 입력하세요.' : null,
              ),
              const SizedBox(height: 16),

              // 🔹 카테고리 드롭다운
              DropdownButtonFormField<int>(
                value: _selectedCategoryIndex,
                items: List.generate(
                  categories.length,
                      (i) => DropdownMenuItem<int>(
                    value: i,
                    child: Text(categories[i]),
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _selectedCategoryIndex = v;
                    _showCustomCategoryField =
                        v != null && categories[v] == '추가';
                  });
                },
                decoration: const InputDecoration(
                  labelText: '카테고리 선택',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_showCustomCategoryField)
                TextFormField(
                  controller: _customCategoryCtrl,
                  decoration: const InputDecoration(
                    labelText: '새 카테고리 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),

              // 🔹 자산 선택
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('현금'),
                    selected: _assetType == AssetType.cash,
                    onSelected: (_) =>
                        setState(() => _assetType = AssetType.cash),
                  ),
                  ChoiceChip(
                    label: const Text('은행'),
                    selected: _assetType == AssetType.bank,
                    onSelected: (_) =>
                        setState(() => _assetType = AssetType.bank),
                  ),
                  ChoiceChip(
                    label: const Text('카드'),
                    selected: _assetType == AssetType.card,
                    onSelected: (_) =>
                        setState(() => _assetType = AssetType.card),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 메모
              TextField(
                controller: _memoCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 저장 버튼
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


