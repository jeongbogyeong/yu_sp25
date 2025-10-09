import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import '../widgets/CommonDialog.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/UserInfo.dart';
import '../../screens/ParentPage.dart';
import 'package:flutter/services.dart'; // InputFormatters 사용을 위해 추가

//provider
import 'package:provider/provider.dart';
import '../../providers/UserProvider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // 폼 유효성 검사를 위한 키
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController(); // 이름 컨트롤러
  final TextEditingController accountNumberController = TextEditingController(); // 계좌번호 컨트롤러

  bool _isObscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✨ UI 개선을 위한 색상 정의
  static const Color primaryColor = Color(0xFF4CAF50); // 녹색
  static const Color secondaryColor = Color(0xFFF0F4F8); // 밝은 배경색

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return; // 폼 유효성 검사 실패 시 종료
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final accountNumberString = accountNumberController.text.trim(); // 문자열로 받음

    // 계좌번호를 안전하게 파싱 (선택적 입력이므로 값이 있을 때만 파싱 시도)
    int? accountNumber = accountNumberString.isEmpty ? null : int.tryParse(accountNumberString);

    if (password != confirmPassword) {
      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: "비밀번호가 일치하지 않습니다.",
        isSuccess: false,
      );
      return;
    }

    // 계좌번호가 있지만 숫자로 변환에 실패했을 경우 (다시 검사)
    if (accountNumberString.isNotEmpty && accountNumber == null) {
      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: "주 계좌번호는 숫자만 입력해야 합니다.",
        isSuccess: false,
      );
      return;
    }


    try {
      // Firebase 회원가입
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🚨 DB에 넣을 때는 int? 타입을 지원하지 않을 경우, 0이나 적절한 기본값을 사용해야 합니다.
      // UserInfo 모델과 Hive Box의 타입을 확인하고 int.parse 오류를 방지하도록 로직 수정
      // 여기서는 int로 강제 변환해야 한다고 가정하고, 변환 불가능 시 0으로 처리합니다.
      final int finalAccountNumber = accountNumber ?? 0;


      // db 넣기
      final box = Hive.box<UserInfo>("UserInfos");
      box.put(userCredential.user?.uid,UserInfo(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        account_number: finalAccountNumber, // int로 저장
      ));

      // Provider 업데이트
      final user = Provider.of<UserProvider>(context,listen : false );
      user.SetAll(userCredential.user!.uid, name, email, finalAccountNumber);

      CommonDialog.show(
        context,
        title: "회원가입 성공 🎉",
        content: "회원가입이 완료되었습니다. 이제 SmartMoney와 함께하세요!",
        isSuccess: true,
        onConfirmed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParentPage()),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = "";
      switch (e.code) {
        case "email-already-in-use":
          message = "이미 가입된 이메일입니다.";
          break;
        case "invalid-email":
          message = "유효하지 않은 이메일 형식입니다.";
          break;
        case "weak-password":
          message = "비밀번호는 최소 6자 이상이어야 합니다.";
          break;
        default:
          message = "회원가입 실패: ${e.message}";
      }
      CommonDialog.show(
        context,
        title: "회원가입 실패 🚨",
        content: message,
        isSuccess: false,
      );
    } catch (e) {
      print("에러 코드" + e.toString());
      CommonDialog.show(
        context,
        title: "회원가입 실패 🚫",
        content: "알 수 없는 오류가 발생했습니다.",
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor, // 밝은 배경색 적용
      appBar: AppBar(
        title: const Text("회원가입"),
        backgroundColor: primaryColor, // 앱바 색상 변경
        foregroundColor: Colors.white, // 앱바 텍스트 색상 변경
        elevation: 0,
      ),
      body: SingleChildScrollView( // 키보드 오버플로우 방지
        padding: const EdgeInsets.all(24.0),
        child: Form( // ✨ Form 위젯으로 감싸서 유효성 검사 사용
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------
              // 이름 입력 필드
              // ----------------------------------------------------
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

              // ----------------------------------------------------
              // 이메일 입력 필드
              // ----------------------------------------------------
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

              // ----------------------------------------------------
              // ✅ 계좌번호 입력 필드 (유효성 검사 및 포맷터 수정)
              // ----------------------------------------------------
              _buildTextFormField(
                controller: accountNumberController,
                labelText: "주 계좌번호 (선택, 숫자 20자리 이하)",
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                // ✅ 하이픈 입력을 막고, 20자리로 제한
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // 숫자만 허용 (하이픈 제외)
                  LengthLimitingTextInputFormatter(20), // 20자리 이하로 길이 제한
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // 숫자만 허용 (FilteringTextInputFormatter로 이미 처리되지만 안전을 위해 다시 검사)
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return '계좌번호는 숫자만 입력해야 합니다.';
                    }
                    // 20자리 이하 검사 (LengthLimitingTextInputFormatter로 이미 처리됨)
                  }
                  // 선택적 필드이므로 비어있는 것은 허용
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 비밀번호 입력 필드
              // ----------------------------------------------------
              _buildPasswordFormField(
                controller: passwordController,
                labelText: "비밀번호 (6자 이상)",
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------
              // 비밀번호 확인 입력 필드
              // ----------------------------------------------------
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

              // ----------------------------------------------------
              // 회원가입 버튼
              // ----------------------------------------------------
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

  // ----------------------------------------------------
  // ✨ 공통 TextFormField 위젯 (inputFormatters 매개변수 추가)
  // ----------------------------------------------------
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // ✅ 새로 추가된 매개변수
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters, // ✅ 적용
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

  // ----------------------------------------------------
  // 비밀번호 TextFormField 위젯 (변경 없음)
  // ----------------------------------------------------
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