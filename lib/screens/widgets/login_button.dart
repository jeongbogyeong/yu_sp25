import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {

  LoginButton({required this.image,required this.text,required this.color,required this.radius,required this.onPressed});

  final Widget image;
  final Widget text;
  final Color color;
  final double radius;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // 네이버 녹색
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: () {
          // 네이버 로그인 로직
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            image,
            text,
            Opacity(
              opacity: 0.0,
              child:  Image.asset(
                "assets/images/naver.png",
                width: 30,
                height: 30,
              ),
            )
          ],
        ),
      ),
    );
  }
}
