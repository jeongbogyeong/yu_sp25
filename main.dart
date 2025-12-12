import 'package:telephony/telephony.dart';
import 'package:smartmoney/screens/widgets/sms_to_transaction.dart'; // createTransactionFromSms

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'entry_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fgqreknznpqdecmpmjsc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZncXJla256bnBxZGVjbXBtanNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzOTI1ODQsImV4cCI6MjA3ODk2ODU4NH0.71c8aRhJWxept9ipH5ckhpOAAYxUXSJtqzznTqlvZpU',
  );

  runApp(const AccountBookApp());
}

final suoabase = Supabase.instance.client;

// 🔥 Stateless → Stateful 로 변경 (유일한 구조 변경)
class AccountBookApp extends StatefulWidget {
  const AccountBookApp({super.key});

  @override
  State<AccountBookApp> createState() => _AccountBookAppState();
}

class _AccountBookAppState extends State<AccountBookApp> {
  final Telephony _telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  Future<void> _initSmsListener() async {
    // 1) 권한 요청
    final bool? granted = await _telephony.requestPhoneAndSmsPermissions;
    if (!(granted ?? false)) {
      debugPrint("SMS 권한 거부됨");
      return;
    }

    // 2) 문자 수신 리스너 활성화
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? "";
        if (body.isEmpty) return;

        debugPrint("📩 SMS 수신: $body");

        // 3) 문자 → 가계부 트랜잭션 자동 등록
        await createTransactionFromSms(body, navigatorKey.currentContext!);
      },
      listenInBackground: false,
    );
  }

  // 🔥 navigatorKey 추가 (context가 main 레벨에서 필요해서)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ⭐ 추가
      title: 'Account Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const EntryPage(),
    );
  }
}
