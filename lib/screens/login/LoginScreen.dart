import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartmoney/screens/ParentPage.dart';
import 'SignUpScreen.dart';
import 'package:smartmoney/screens/widgets/login_button.dart';
import 'package:smartmoney/screens/widgets/CommonDialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscureText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CommonDialog.show(
        context,
        title: "로그인 실패",
        content: "이메일과 비밀번호를 입력해주세요.",
        isSuccess: false,
      );
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      //로그인 성공시
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "";
      switch (e.code) {
        case "user-not-found":
          message = "가입되지 않은 이메일입니다.";
          break;
        case "wrong-password":
          message = "비밀번호가 틀렸습니다.";
          break;
        case "invalid-email":
          message = "유효하지 않은 이메일 형식입니다.";
          break;
        default:
          message = "로그인 실패: ${e.message}";
      }

      CommonDialog.show(
        context,
        title: "로그인 실패",
        content: message,
        isSuccess: false,
      );
    } catch (e) {
      CommonDialog.show(
        context,
        title: "로그인 실패",
        content: "알 수 없는 오류가 발생했습니다.",
        isSuccess: false,
      );
    }
  }


  void _showDialog(String title, String content,
      {bool isSuccess = false, VoidCallback? onConfirmed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        content: Text(content),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirmed != null) onConfirmed();
            },
            style: TextButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "확인",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 150),
              const Text(
                "로그인",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 이메일 입력
              Container(
                width: 350,
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                    hintText: "Email",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 비밀번호 입력
              Container(
                width: 350,
                child: TextField(
                  controller: passwordController,
                  obscureText: _isObscureText,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureText = !_isObscureText;
                        });
                      },
                    ),
                    hintText: "Password",
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 로그인 버튼
              Container(
                width: 350,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("로그인"),
                ),
              ),

              // 신규 회원가입
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text("신규 회원가입"),
              ),

              const Divider(height: 32, thickness: 1),
              const Text("다른 계정으로 로그인"),
              const SizedBox(height: 12),

              // 소셜 로그인 버튼들 (네이버, 카카오, 구글)
              Column(
                children: [
                  LoginButton(
                    image: Image.asset('assets/images/naver.png', width: 30, height: 30),
                    text: const Text("네이버 로그인", style: TextStyle(color: Colors.black87, fontSize: 16)),
                    color: const Color(0xFF00BF18),
                    radius: 6.0,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  LoginButton(
                    image: Image.asset('assets/images/kakao.png', width: 30, height: 30),
                    text: const Text("카카오 로그인", style: TextStyle(color: Colors.black87, fontSize: 16)),
                    color: const Color(0xFFFDDC3F),
                    radius: 6.0,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  LoginButton(
                    image: Image.asset('assets/images/google.png', width: 30, height: 30),
                    text: const Text("Google 로그인", style: TextStyle(color: Colors.black87, fontSize: 16)),
                    color: const Color(0xFFFFFFFF),
                    radius: 6.0,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
