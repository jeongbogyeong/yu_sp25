import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartmoney/domain/usecases/get_spending.dart';
import 'package:smartmoney/domain/usecases/login_user.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';

import '../widgets/CommonDialog.dart';
import '../../screens/ParentPage.dart';

// ViewModel import
import 'package:provider/provider.dart';
import '../viewmodels/SignupViewModel.dart'; // ✅ 새로 만든 ViewModel import

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

  bool _isObscureText = true;

  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFF0F4F8);

  Future<void> _signUp() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final accountNumberString = accountNumberController.text.trim();

    if (password != confirmPassword) {
      // ... (비밀번호 불일치 처리)
      return;
    }

    if (accountNumberString.isNotEmpty && int.tryParse(accountNumberString) == null) {
      // ... (계좌번호 숫자 검사 처리)
      return;
    }

    final signupViewModel = Provider.of<SignupViewModel>(context, listen: false);
    final loginUserUseCase = Provider.of<LoginUser>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final getSpending = Provider.of<GetSpending>(context, listen: false);
    // 로딩 상태 표시 (필요시)

    try {

      //  '0'으로 전달하고 DB에서 auto_increment를 사용
      final String mysqlId = '0';

      // ✅ MySQL DATE 형식에 맞게 'YYYY-MM-DD'로 명확하게 포맷
      final DateTime now = DateTime.now();
      final String regdate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 4. 🚀 클린 아키텍처를 통한 MySQL 데이터베이스 저장 (ID를 0으로 전달)
      await signupViewModel.registerUser(
        id: mysqlId,
        email: email,
        password: password,
        name: name,
        regdate: regdate,
      );

      final userEntity = await loginUserUseCase.call(email, password);

      if (userEntity != null) {
        userViewModel.setUser(userEntity);
        getSpending.setID(userEntity.id);
        // 5. ✅ MySQL 저장 성공
        CommonDialog.show(
          context,
          title: "회원가입 성공 🎉",
          content: "회원가입이 완료되었습니다. 이제 SmartMoney와 함께하세요!",
          isSuccess: true,
          onConfirmed: () {
            // 성공 시 로그인 화면으로 이동하는 것이 일반적이지만,
            // 기존 코드와 같이 ParentPage로 이동하도록 유지합니다.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ParentPage()),
            );
          },
        );
      }else {
        // UseCase에서 null을 반환했지만 Exception이 발생하지 않은 경우
        throw Exception("Authentication failed, user data not returned.");
      }
    } catch (e) {
      // ⚠️ MySQL 저장 실패 (DataSource에서 던진 Exception 처리)
      String message = "알 수 없는 오류가 발생했습니다.";

      // Exception 메시지에서 구체적인 서버 에러를 추출 (예: 'Exception: MySQL registration failed: 이미 등록된 이메일입니다.')
      if (e.toString().contains("MySQL registration failed:")) {
        message = e.toString().split("MySQL registration failed:").last.trim();
      } else if (e.toString().contains("Server connection error:")) {
        message = "서버 연결에 문제가 발생했습니다. (${e.toString().split(":").last.trim()})";
      } else {
        print("Raw Error: $e"); // 알 수 없는 오류는 로그로 출력
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
    // build 메서드 내용은 변경 없음 (UI 로직)
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
              // ... 이름 입력 필드
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

              // ... 이메일 입력 필드
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

              // ... 계좌번호 입력 필드
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

              // ... 비밀번호 입력 필드
              _buildPasswordFormField(
                controller: passwordController,
                labelText: "비밀번호 (6자 이상)",
              ),
              const SizedBox(height: 16),

              // ... 비밀번호 확인 입력 필드
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

              // ... 회원가입 버튼
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
      validator: validator ?? (value) {
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