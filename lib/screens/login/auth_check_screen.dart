import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../viewmodels/UserViewModel.dart';
import 'LoginScreen.dart';
import 'package:smartmoney/screens/ParentPage.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    if (session == null) {
      // 로그인 안 된 상태
      return const LoginScreen();
    }
    userViewModel.loadCurrentUser();
    // 로그인 유지된 상태 (자동 로그인)
    return const ParentPage();
  }
}
