import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartmoney/screens/widgets/CommonDialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isObscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AlertDialog 표시 함수
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
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: "이메일과 비밀번호를 입력해주세요.",
        isSuccess: false,
      );
      return;
    }

    if (password != confirmPassword) {
      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: "비밀번호가 일치하지 않습니다.",
        isSuccess: false,
      );
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      CommonDialog.show(
        context,
        title: "회원가입 성공",
        content: "회원가입이 완료되었습니다.",
        isSuccess: true,
        onConfirmed: () {
          Navigator.pop(context); // 로그인 화면으로 돌아가기
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
          message = "비밀번호가 너무 약합니다.";
          break;
        default:
          message = "회원가입 실패: ${e.message}";
      }

      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: message,
        isSuccess: false,
      );
    } catch (e) {
      CommonDialog.show(
        context,
        title: "회원가입 실패",
        content: "알 수 없는 오류가 발생했습니다.",
        isSuccess: false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "이메일",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: _isObscureText,
              decoration: InputDecoration(
                labelText: "비밀번호",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscureText = !_isObscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "비밀번호 확인",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}
