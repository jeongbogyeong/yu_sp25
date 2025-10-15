import 'package:flutter/material.dart';
import 'screens/login/LoginScreen.dart';
import 'package:intl/date_symbol_data_local.dart';

// ✅ Firebase 관련 import
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ MySQL 관련 import
import 'database/database_helper.dart';

//ViewModel
import 'package:smartmoney/viewmodels/UserViewModel.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MySQL 데이터베이스 초기화
  await DatabaseHelper.instance.init();

  // 한국어 날짜 포맷
  await initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
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
