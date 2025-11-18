import 'package:flutter/material.dart';
import 'package:smartmoney/domain/usecases/stat_user.dart';
import 'package:smartmoney/screens/viewmodels/StatViewModel.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';
import 'package:smartmoney/screens/viewmodels/CommunityViewModel.dart';
import 'package:smartmoney/service/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login/LoginScreen.dart';
import 'package:intl/date_symbol_data_local.dart';

// GetIt 및 Provider 관련 import
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'service/di_setup.dart';

// DI 인스턴스
final locator = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String supabaseUrl = 'https://hlaszktpxqzzknxjyabb.supabase.co';
  String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsYXN6a3RweHF6emtueGp5YWJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1ODkyMjQsImV4cCI6MjA3NjE2NTIyNH0.0x7SwkmdAypsSTtakOId9h7HDknoDiPmEYa2iYC7mZY';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  //GetIt 초기화 호출
  setupLocator();

  // 알림 서비스 초기화
  await NotificationService.init();

  // 한국어 날짜 포맷
  await initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        // ViewModel
        ChangeNotifierProvider(create: (_) => locator<UserViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<StatViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<CommunityViewModel>()),

        // UseCase (일반 Provider)
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
      home: LoginScreen(),
    );
  }
}
