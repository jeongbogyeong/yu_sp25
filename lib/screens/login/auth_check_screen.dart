import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/stat_user.dart';
import '../viewmodels/TransactionViewModel.dart';
import '../viewmodels/UserViewModel.dart';
import 'LoginScreen.dart';
import 'package:smartmoney/screens/ParentPage.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  Future<bool> _initialize(BuildContext context) async {
    final session = Supabase.instance.client.auth.currentSession;

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final statUserCase = Provider.of<StatUser>(context, listen: false);

    if (session == null) {
      return false; // 로그인 안됨
    }

    await userViewModel.loadCurrentUser();
    statUserCase.setID(userViewModel.user!.id);
    await transactionViewModel.getTransactions(userViewModel.user!.id);

    return true; // 로그인 유지됨
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialize(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == false) {
          return const LoginScreen();
        } else {
          return const ParentPage();
        }
      },
    );
  }
}