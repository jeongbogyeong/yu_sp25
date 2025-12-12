import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/CommonDialog.dart';
import '../../screens/ParentPage.dart';
import 'package:provider/provider.dart';

final supabase = Supabase.instance.client;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  bool _isObscureText = true;

  // ✅ 추가: 주 수입원 선택 값
  String? _selectedIncomeType; // PART_TIME / SALARY / ALLOWANCE

  // ✅ 추가: 주 수입원 옵션 리스트
  final List<Map<String, String>> _incomeTypeOptions = const [
    {'code': 'PART_TIME', 'label': '아르바이트 월급'},
    {'code': 'SALARY', 'label': '회사원(월급)'},
    {'code': 'ALLOWANCE', 'label': '용돈'},
  ];

  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFF0F4F8);

  Future<void> _signUp() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ 드롭다운 값 필수 체크
    if (_selectedIncomeType == null || _selectedIncomeType!.isEmpty) {
      CommonDialog.show(
        context,
        title: "회원가입 실패 🚨",
        content: "주 수입원을 선택해주세요.",
        isSuccess: false,
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final accountNumberString = accountNumberController.text.trim();
    final bankName = bankNameController.text.trim();
    final incomeType = _selectedIncomeType!; // PART_TIME / SALARY / ALLOWANCE

    if (password != confirmPassword) {
      CommonDialog.show(
        context,
        title: "회원가입 실패 🚨",
        content: "비밀번호와 비밀번호 확인 값이 일치하지 않습니다.",
        isSuccess: false,
      );
      return;
    }

    // 계좌번호 필수 아님
    final accountNumberInt = accountNumberString.isEmpty
        ? 0
        : (int.tryParse(accountNumberString) ?? 0);

    if (accountNumberString.isNotEmpty && accountNumberInt == 0 && accountNumberString != '0') {
      CommonDialog.show(
        context,
        title: "회원가입 실패 🚨",
        content: "계좌번호는 숫자만 입력해야 합니다.",
        isSuccess: false,
      );
      return;
    }


    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    try {
      // ✅ incomeType 추가
      final userEntity = await userViewModel.signup(
        email,
        password,
        name,
        accountNumberInt,
        bankName,
        incomeType,
      );

      if (userEntity != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentPage()),
        );

        Future.microtask(() {
          if (!mounted) return;

          CommonDialog.show(
            context,
            title: "회원가입 성공 🎉",
            content: "회원가입이 완료되었습니다. 이제 SmartMoney와 함께하세요!",
            isSuccess: true,
            onConfirmed: () {},
          );
        });

      } else {
        throw Exception("Authentication failed, user data not returned.");
      }
    } catch (e) {
      String message = "알 수 없는 오류가 발생했습니다.";
      if (e.toString().contains("email-already-in-use")) {
        message = "이미 사용 중인 이메일입니다. 다른 이메일로 시도해 주세요.";
      } else if (e.toString().contains("account-number-already-in-use")) {
        message = "이미 등록된 계좌번호입니다. 다른 계좌번호를 사용하세요.";
      } else if (e.toString().contains("MySQL registration failed:")) {
        message = e.toString().split("MySQL registration failed:").last.trim();
      } else if (e.toString().contains("Server connection error:")) {
        message = "서버 연결에 문제가 발생했습니다. (${e.toString().split(":").last.trim()})";
      } else {
        print("Raw Error: $e");
      }

      CommonDialog.show(
        context,
        title: "회원가입 실패 🚨",
        content: message,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text("회원가입"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이름
              _buildTextFormField(
                controller: nameController,
                labelText: "이름",
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 이메일
              _buildTextFormField(
                controller: emailController,
                labelText: "이메일",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return '유효하지 않은 이메일 형식입니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 이메일 밑에 ↓ 이 블록 통째로 붙여넣기

              // 🔹 주 수입원 섹션 타이틀
              const Text(
                "나의 주 수입원",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // 🔹 주 수입원 설명 텍스트
              const Text(
                "SmartMoney가 월급·용돈 등 돈이 주로 들어오는 경로를 이해하기 위해 사용하는 정보예요.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),

              // ✅ 주 수입원 선택 드롭다운
              DropdownButtonFormField<String>(
                value: _selectedIncomeType,
                isExpanded: true, // 🔥 이 줄 추가
                items: _incomeTypeOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option['code'],
                        child: Text(option['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIncomeType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주 수입원을 선택해주세요.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "주 수입원 선택",
                  hintText: "월급·아르바이트·용돈 중 하나를 선택하세요",
                  prefixIcon: const Icon(
                    Icons.work_outline,
                    color: primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 10.0,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  errorStyle: const TextStyle(height: 0.5),
                ),
              ),
              const SizedBox(height: 16),

              // 계좌번호
              _buildTextFormField(
                controller: accountNumberController,
                labelText: "주 계좌번호 (선택, 숫자 20자리 이하)",
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return '계좌번호는 숫자만 입력해야 합니다.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 은행 이름
              _buildTextFormField(
                controller: bankNameController,
                labelText: "은행 이름 (선택)",
                icon: Icons.account_balance_outlined,
                keyboardType: TextInputType.text,
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 비밀번호
              _buildPasswordFormField(
                controller: passwordController,
                labelText: "비밀번호 (6자 이상)",
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인
              _buildPasswordFormField(
                controller: confirmPasswordController,
                labelText: "비밀번호 확인",
                isConfirm: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호 확인을 입력해주세요.';
                  }
                  if (value != passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "SmartMoney 시작하기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        errorStyle: const TextStyle(height: 0.5),
      ),
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String labelText,
    bool isConfirm = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? true : _isObscureText,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$labelText를 입력해주세요.';
            }
            if (value.length < 6) {
              return '비밀번호는 6자 이상이어야 합니다.';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 10.0,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        errorStyle: const TextStyle(height: 0.5),
        suffixIcon: isConfirm
            ? null
            : IconButton(
                icon: Icon(
                  _isObscureText ? Icons.visibility_off : Icons.visibility,
                  color: primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureText = !_isObscureText;
                  });
                },
              ),
      ),
    );
  }
}
