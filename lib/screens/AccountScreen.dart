import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("가계부 화면1"),
      ),
      body: const Center(child: Text("여기는 가계부 화면")),
    );
  }
}
