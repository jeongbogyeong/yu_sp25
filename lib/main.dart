import 'package:flutter/material.dart';
import 'package:smartmoney/domain/usecases/fetch_spending.dart';
import 'package:smartmoney/domain/usecases/fetch_user.dart';
import 'package:smartmoney/domain/usecases/get_spending.dart';
import 'package:smartmoney/domain/usecases/login_user.dart';
import 'package:smartmoney/screens/viewmodels/SpendingViewModel.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';

import 'screens/login/LoginScreen.dart';
import 'package:intl/date_symbol_data_local.dart';

// GetIt 및 Provider 관련 import
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart'; // GetIt 임포트
import 'di_setup.dart'; // DI 설정 파일 임포트

// 뷰모델 import (Provider에 넘겨주기 위함)
import 'screens/viewmodels/SignupViewModel.dart';

// DI 인스턴스
final locator = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //GetIt 초기화 호출
  setupLocator();


  // 한국어 날짜 포맷
  await initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        // 1. Signup ViewModel
        ChangeNotifierProvider(create: (_) => locator<SignupViewModel>()),

        // 🚀 2. User State ViewModel (ChangeNotifierProvider)
        ChangeNotifierProvider(create: (_) => locator<UserViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<SpendingViewModel>()),

        // 🚀 3. FetchUser UseCase (일반 Provider)
        Provider<FetchUser>(create: (_) => locator<FetchUser>()),
        Provider<LoginUser>(create: (_) => locator<LoginUser>()),
        Provider<GetSpending>(create: (_) => locator<GetSpending>()),
        Provider<FetchSpending>(create: (_) => locator<FetchSpending>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가계부 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: LoginScreen(),
    );
  }
}