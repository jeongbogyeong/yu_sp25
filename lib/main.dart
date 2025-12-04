import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login/auth_check_screen.dart';

// ViewModels
import 'screens/viewmodels/UserViewModel.dart';
import 'screens/viewmodels/StatViewModel.dart';
import 'screens/viewmodels/TransactionViewModel.dart';
import 'screens/viewmodels/CommunityViewModel.dart';

// UseCase
import 'package:smartmoney/domain/usecases/stat_user.dart';

// Notification
import 'package:smartmoney/service/notification/notification_service.dart';

// DI 설정
import 'service/di_setup.dart';

// GetIt 인스턴스
final locator = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  String supabaseUrl = 'https://hlaszktpxqzzknxjyabb.supabase.co';
  String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsYXN6a3RweHF6emtueGp5YWJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1ODkyMjQsImV4cCI6MjA3NjE2NTIyNH0.0x7SwkmdAypsSTtakOId9h7HDknoDiPmEYa2iYC7mZY';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  // DI 초기화
  setupLocator();

  // 알림 초기화
  await NotificationService.init();

  // 한국어 날짜 포맷
  await initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        // =========== 🔥 ViewModel Providers ============
        ChangeNotifierProvider(create: (_) => locator<UserViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<StatViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<TransactionViewModel>()),

        /// -----------------------------------------------------------
        /// 🔥🔥🔥 꼭 필요했던 부분 — CommunityViewModel 추가!!!
        /// -----------------------------------------------------------
        ChangeNotifierProvider(create: (_) => locator<CommunityViewModel>()),

        // =========== UseCase Provider ============
        Provider<StatUser>(create: (_) => locator<StatUser>()),
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
      home: const AuthCheckScreen(),
    );
  }
}
