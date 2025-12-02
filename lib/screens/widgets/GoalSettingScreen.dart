// 파일 이름: goal_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartmoney/screens/viewmodels/StatViewModel.dart'; // 경로 확인 필요

// StatsScreen에서 가져온 상수 (실제 앱에서는 별도의 테마 파일에 정의하는 것이 좋습니다)
const Color _primaryColor = Color(0xFF4CAF50); // 긍정/강조 (녹색 계열)
const Color _secondaryColor = Color(0xFFF0F4F8); // 배경색

// StatsScreen에서 확장된 11가지 카테고리 정보
const Map<int, String> categoryNames = {
  0: "식비", 1: "교통", 2: "문화생활", 3: "마트/편의점", 4: "패션/미용",
  5: "생활용품", 6: "주거/통신", 7: "병원비/약값", 8: "교육", 9: "경조사/회비",
  10: "기타",
};

const Map<int, Color> categoryColors = {
  0: Color(0xFFFFA726), 1: Color(0xFF42A5F5), 2: Color(0xFF8D6E63),
  3: Color(0xFFEF5350), 4: Color(0xFFEC407A), 5: Color(0xFF66BB6A),
  6: Color(0xFFAB47BC), 7: Color(0xFF78909C), 8: Color(0xFF26A69A),
  9: Color(0xFFFFCA28), 10: Color(0xFFBDBDBD),
};


// 콤마 포맷터 클래스 (기존 StatsScreen에서 가져옴)
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
    final double? number = double.tryParse(cleanText);

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


class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // 전체 목표 금액 컨트롤러
  late TextEditingController _overallGoalController;
  // 카테고리별 목표 금액 컨트롤러 Map
  late Map<int, TextEditingController> _categoryGoalControllers;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<StatViewModel>(context, listen: false);

    // 1. 전체 목표 금액 초기화
    _overallGoalController = TextEditingController(
        text: vm.overallGoal > 0 ? NumberFormat('#,###').format(vm.overallGoal) : ''
    );

    // 2. 카테고리별 목표 금액 초기화
    _categoryGoalControllers = {};
    for (var key in categoryNames.keys) {
      final goal = vm.categoryGoals[key] ?? 0.0;
      _categoryGoalControllers[key] = TextEditingController(
          text: goal > 0 ? NumberFormat('#,###').format(goal) : ''
      );
    }
  }

  @override
  void dispose() {
    _overallGoalController.dispose();
    _categoryGoalControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // 입력된 텍스트에서 콤마를 제거하고 double로 파싱하는 헬퍼 함수
  double _parseInput(String text) {
    final rawText = text.replaceAll(RegExp(r','), '');
    return double.tryParse(rawText) ?? 0.0;
  }

  // 모든 목표 금액을 저장하는 함수
  void _saveGoals() {
    final vm = Provider.of<StatViewModel>(context, listen: false);

    // 1. 전체 목표 금액 파싱 및 저장
    final newOverallGoal = _parseInput(_overallGoalController.text);

    // 2. 카테고리별 목표 금액 파싱
    final Map<int, double> newCategoryGoals = {};
    _categoryGoalControllers.forEach((key, controller) {
      newCategoryGoals[key] = _parseInput(controller.text);
    });

    // 3. 유효성 검사 (카테고리 목표 합계 < 전체 목표)
    // 기타(키 10)를 제외한 카테고리 합계만 검사
    final sumOfCategoryGoals = newCategoryGoals.entries
        .where((e) => e.key != 10) // '기타' 제외
        .fold(0.0, (sum, e) => sum + e.value);

    if (sumOfCategoryGoals > newOverallGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카테고리 목표 합계(기타 제외)는 총 목표 금액을 초과할 수 없습니다.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 4. StatViewModel에 모든 목표 업데이트
    vm.updateGoals(newOverallGoal, newCategoryGoals);

    // 5. 이전 화면으로 돌아가기
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text("목표 금액 설정"),
        backgroundColor: _secondaryColor,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: const Text("저장", style: TextStyle(color: _primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 전체 목표 설정 카드
            _buildGoalInputCard("총 목표 금액", _overallGoalController, Icons.monetization_on),
            const SizedBox(height: 30),

            // 2. 카테고리별 목표 설정
            const Text(
              "카테고리별 목표 금액 (선택 사항)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 20, thickness: 0.5, color: Colors.black12),

            // 카테고리별 입력 필드 리스트
            ...categoryNames.entries.map((entry) {
              final key = entry.key;
              final name = entry.value;
              final color = categoryColors[key];
              final isEtc = (key == 10); // '기타' 카테고리는 유효성 검사에서 제외되므로 별도 표시

              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: _buildCategoryGoalInput(key, name, _categoryGoalControllers[key]!, color!, isEtc),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // 목표 금액 입력 필드 위젯 빌더 (전체 목표용)
  Widget _buildGoalInputCard(String title, TextEditingController controller, IconData icon) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: "0",
                suffixText: "원",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리별 목표 금액 입력 필드 위젯 빌더
  Widget _buildCategoryGoalInput(int key, String name, TextEditingController controller, Color color, bool isEtc) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsFormatter(),
            ],
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "0",
              suffixText: "원",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}