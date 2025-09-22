import 'package:flutter/material.dart';
import 'package:smartmoney/screens/main/MyHomePage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isObscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 200),
              const Text("로그인",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Container(
                width: 350,
                child: TextField(
                  controller: emailController,
                  decoration:  InputDecoration(
                    prefixIcon: Icon(Icons.email,color: Colors.grey[400],),
                    hintText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: 350,
                child: TextField(
                  controller: passwordController,
                  obscureText: _isObscureText,
                  decoration:  InputDecoration(
                    prefixIcon: Icon(Icons.lock,color: Colors.grey[400],),
                    suffixIcon: _isObscureText?
                        IconButton(
                          icon: Icon(Icons.visibility_off_outlined),
                          onPressed: (){
                            setState(() {
                              _isObscureText=!_isObscureText;
                            });
                          },
                        )
                    : IconButton(
                      icon: Icon(Icons.visibility_outlined),
                      onPressed: (){
                        setState(() {
                          _isObscureText=!_isObscureText;
                        });
                      },
                    ),
                    hintText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: 350,
                child: ElevatedButton(
                  onPressed: () {
                    // Firebase Email 로그인 함수 호출
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("로그인"),
                ),
              ),

              TextButton(
                onPressed: () {
                  // 회원가입 화면 이동
                },
                child: const Text("신규 회원가입"),
              ),

              const Divider(height: 32, thickness: 1),
              const Text("다른 계정으로 로그인"),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      // Google 로그인
                    },
                    icon: Image.asset("assets/images/google.png", width: 40),
                  ),
                  IconButton(
                    onPressed: () {
                      // Naver 로그인
                    },
                    icon: Image.asset("assets/images/naver.png", width: 40),
                  ),
                  IconButton(
                    onPressed: () {
                      // Kakao 로그인
                    },
                    icon: Image.asset("assets/images/kakao.png", width: 40),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
