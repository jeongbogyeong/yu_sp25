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

// 🔥 (옵션) 백그라운드에서 SMS 받을 때 로그 찍을 핸들러
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  final body = message.body ?? '';
  final addr = message.address ?? 'unknown';
  debugPrint('✅ [BG] SMS 수신 - from:$addr / body:$body');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔵 [main] 시작');

  // Supabase 초기화 (네가 쓰던 거 그대로)
  String supabaseUrl = 'https://hlaszktpxqzzknxjyabb.supabase.co';
  String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsYXN6a3RweHF6emtueGp5YWJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1ODkyMjQsImV4cCI6MjA3NjE2NTIyNH0.0x7SwkmdAypsSTtakOId9h7HDknoDiPmEYa2iYC7mZY';

  debugPrint('🔵 [main] Supabase.initialize 호출');
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  debugPrint('✅ [main] Supabase 초기화 완료');

  // DI 초기화
  debugPrint('🔵 [main] setupLocator 호출');
  setupLocator();
  debugPrint('✅ [main] DI(locator) 초기화 완료');

  // 알림 초기화
  debugPrint('🔵 [main] NotificationService.init 호출');
  await NotificationService.init();
  debugPrint('✅ [main] NotificationService.init 완료');

  // 한국어 날짜 포맷
  debugPrint('🔵 [main] initializeDateFormatting 호출');
  await initializeDateFormatting('ko_KR');
  debugPrint('✅ [main] initializeDateFormatting 완료');

  debugPrint('🔵 [main] runApp 직전');

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
    debugPrint('✅ [MyApp.initState] 호출됨 - SMS 리스너 초기화 시작');
    _initSmsListener();
  }

  Future<void> _initSmsListener() async {
    debugPrint('🔵 [_initSmsListener] 시작');

    try {
      // 1) 권한 요청
      final bool? granted = await _telephony.requestPhoneAndSmsPermissions;
      debugPrint('✅ [_initSmsListener] SMS 권한 요청 결과: $granted');

      if (!(granted ?? false)) {
        debugPrint(
          '❌ [_initSmsListener] SMS 권한 거부됨 - listenIncomingSms 등록 안 함',
        );
        return;
      }

      // 2) 문자 수신 리스너 등록
      debugPrint('🔵 [_initSmsListener] listenIncomingSms 등록 시도');
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          final body = message.body ?? "";
          final addr = message.address ?? 'unknown';
          final date = message.date;

          debugPrint(
            '📩 [FG onNewMessage] SMS 수신 - from:$addr / date:$date / body:$body',
          );

          if (body.isEmpty) {
            debugPrint('⚠️ [FG onNewMessage] body가 비어 있어서 무시');
            return;
          }

          // navigatorKey로 최상위 context 얻어서 트랜잭션 생성
          final ctx = navigatorKey.currentContext;
          if (ctx == null) {
            debugPrint(
              '⚠️ [FG onNewMessage] navigatorKey.currentContext == null -> createTransactionFromSms 호출 못함',
            );
            return;
          }

          debugPrint('🔵 [FG onNewMessage] createTransactionFromSms 호출 시작');
          try {
            await createTransactionFromSms(body, ctx);
            debugPrint('✅ [FG onNewMessage] createTransactionFromSms 정상 완료');
          } catch (e, st) {
            debugPrint('❌ [FG onNewMessage] createTransactionFromSms 중 에러: $e');
            debugPrint(st.toString());
          }
        },
        onBackgroundMessage: backgroundMessageHandler, // 🔥 BG 로그도 찍자
        listenInBackground: true, // 백그라운드도 수신 시도
      );

      debugPrint('✅ [_initSmsListener] listenIncomingSms 등록 완료');
    } catch (e, st) {
      debugPrint('❌ [_initSmsListener] 에러 발생: $e');
      debugPrint(st.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [MyApp.build] MaterialApp 빌드');
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
