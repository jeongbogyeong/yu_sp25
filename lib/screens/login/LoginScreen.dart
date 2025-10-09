import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:smartmoney/screens/ParentPage.dart';
import 'SignUpScreen.dart';
import '../../models/UserInfo.dart';
//ui위젯
import 'package:smartmoney/screens/widgets/login_button.dart';
import 'package:smartmoney/screens/widgets/CommonDialog.dart';

//provider
import 'package:provider/provider.dart';
import '../../providers/UserProvider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscureText = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //  폼 유효성 검사를 위한 키

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✨ UI 개선을 위한 색상 정의 (회원가입 화면과 동일)
  static const Color primaryColor = Color(0xFF4CAF50); // 가계부에 어울리는 녹색 계열
  static const Color secondaryColor = Color(0xFFF0F4F8); // 밝은 배경색

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // 폼 유효성 검사 실패 시 종료
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final box = Hive.box<UserInfo>("UserInfos");
      final UserInfo? _userInfo = box.get(userCredential.user!.uid);
      final user = Provider.of<UserProvider>(context,listen: false);
      if(_userInfo!=null){
        user.SetAll(_userInfo.uid, _userInfo.name, _userInfo.email, _userInfo.account_number);
      }

      // 로그인 성공시
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "";
      switch (e.code) {
        case "user-not-found":
          message = "가입되지 않은 이메일이거나 비밀번호가 틀렸습니다."; // 보안을 위해 통합 메시지 사용 권장
          break;
        case "wrong-password":
          message = "가입되지 않은 이메일이거나 비밀번호가 틀렸습니다.";
          break;
        case "invalid-email":
          message = "유효하지 않은 이메일 형식입니다.";
          break;
        default:
          message = "로그인 실패: ${e.message}";
      }

      CommonDialog.show(
        context,
        title: "로그인 실패 🚨",
        content: message,
        isSuccess: false,
      );
    } catch (e) {
      CommonDialog.show(
        context,
        title: "로그인 실패 🚫",
        content: "알 수 없는 오류가 발생했습니다.",
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드 노출 시 스크롤 허용
      backgroundColor: secondaryColor,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form( // ✨ Form 위젯으로 감싸서 유효성 검사 사용
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  // ✨ 앱 로고 및 타이틀
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "SmartMoney",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: primaryColor
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ----------------------------------------------------
                  // 이메일 입력 필드
                  // ----------------------------------------------------
                  _buildTextFormField(
                    controller: emailController,
                    labelText: "이메일 주소",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ----------------------------------------------------
                  // 비밀번호 입력 필드
                  // ----------------------------------------------------
                  _buildPasswordFormField(
                    controller: passwordController,
                    labelText: "비밀번호",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ----------------------------------------------------
                  // 로그인 버튼
                  // ----------------------------------------------------
                  SizedBox(
                    width: 350,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "로그인",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 신규 회원가입 및 비밀번호 찾기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "신규 회원가입",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(" | ", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () {
                          // 비밀번호 찾기 기능 구현
                        },
                        child: const Text(
                          "비밀번호 찾기",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ----------------------------------------------------
                  // 소셜 로그인 섹션
                  // ----------------------------------------------------
                  const Divider(height: 0, thickness: 1, indent: 20, endIndent: 20, color: Colors.grey),
                  const SizedBox(height: 24),

                  const Text("간편 로그인", style: TextStyle(color: Colors.black54, fontSize: 16)),
                  const SizedBox(height: 16),

                  // 소셜 로그인 버튼들 (네이버, 카카오, 구글)
                  // LoginButton 위젯은 기존 디자인을 최대한 살리면서 너비만 통일
                  Column(
                    children: [
                      // Image.asset 경로는 실제 프로젝트에 맞게 수정 필요
                      LoginButton(
                        image: Image.asset('assets/images/naver.png', width: 20, height: 20),
                        text: const Text("네이버 로그인", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        color: const Color(0xFF00BF18), // 네이버 색상
                        radius: 12.0,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      LoginButton(
                        image: Image.asset('assets/images/kakao.png', width: 20, height: 20),
                        text: const Text("카카오 로그인", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        color: const Color(0xFFFDDC3F), // 카카오 색상
                        radius: 12.0,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      LoginButton(
                        image: Image.asset('assets/images/google.png', width: 20, height: 20),
                        text: const Text("Google 로그인", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        color: const Color(0xFFFFFFFF), // 구글은 흰색 배경
                        radius: 12.0,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 공통 TextFormField 위젯 (회원가입 화면과 동일)
  // ----------------------------------------------------
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 350,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          errorStyle: const TextStyle(height: 0.5),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 비밀번호 TextFormField 위젯 (회원가입 화면과 동일)
  // ----------------------------------------------------
  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 350,
      child: TextFormField(
        controller: controller,
        obscureText: _isObscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          errorStyle: const TextStyle(height: 0.5),
          suffixIcon: IconButton(
            icon: Icon(
              _isObscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: primaryColor,
            ),
            onPressed: () {
              setState(() {
                _isObscureText = !_isObscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}