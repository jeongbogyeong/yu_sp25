import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("커뮤니티"),
      ),
      body: const Center(child: Text("여기는 커뮤니티 화면")),
    );
  }
}
