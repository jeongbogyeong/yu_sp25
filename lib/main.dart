import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔥 SMS 관련
import 'package:telephony/telephony.dart';
import 'screens/widgets/sms_to_transaction.dart'; // createTransactionFromSms

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

// 🔥 navigatorKey: SMS 콜백에서 BuildContext 대신 쓰려고 전역으로 둠
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화 (네가 쓰던 거 그대로)
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
        // =========== 🔥 ViewModel Providers ============ //
        ChangeNotifierProvider(create: (_) => locator<UserViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<StatViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<TransactionViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<CommunityViewModel>()),

        // =========== UseCase Provider ============ //
        Provider<StatUser>(create: (_) => locator<StatUser>()),
      ],
      child: const MyApp(),
    ),
  );
}

// 🔥 이제 MyApp을 StatefulWidget로 바꿔서 SMS 리스너 붙이기
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Telephony _telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ MyApp.initState 호출됨 - SMS 리스너 초기화 시작');
    _initSmsListener();
  }

  Future<void> _initSmsListener() async {
    // 1) 권한 요청
    final bool? granted = await _telephony.requestPhoneAndSmsPermissions;
    debugPrint('✅ SMS 권한 요청 결과: $granted');

    if (!(granted ?? false)) {
      debugPrint('❌ SMS 권한 거부됨 - listenIncomingSms 시작 안 함');
      return;
    }

    // 2) 문자 수신 리스너 등록
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? "";
        if (body.isEmpty) return;

        debugPrint('📩 SMS 수신: $body');

        // navigatorKey로 최상위 context 얻어서 트랜잭션 생성
        final ctx = navigatorKey.currentContext;
        if (ctx == null) {
          debugPrint(
            '⚠️ navigatorKey.currentContext 가 null이라 Transaction 생성 못 함',
          );
          return;
        }

        await createTransactionFromSms(body, ctx);
      },
      listenInBackground: false,
    );

    debugPrint('✅ listenIncomingSms 등록 완료');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUDGE GAP',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 🔥 여기 연결
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const AuthCheckScreen(),
    );
  }
}
