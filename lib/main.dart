import 'package:flutter/material.dart';
import 'screens/login/LoginScreen.dart';
import 'package:intl/date_symbol_data_local.dart';

// ✅ Firebase 관련 import
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ Hive 관련 import
import 'package:hive_flutter/hive_flutter.dart';
import 'models/author.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'models/UserInfo.dart';

//provier 관련 import
import 'package:provider/provider.dart';
import 'providers/UserProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 어댑터 등록
  Hive.registerAdapter(AuthorAdapter());
  Hive.registerAdapter(PostAdapter());
  Hive.registerAdapter(CommentAdapter());
  Hive.registerAdapter(UserInfoAdapter());

  // 박스 열기
  await Hive.openBox<Post>('community_posts');
  await Hive.openBox<Comment>('community_comments');
  await Hive.openBox<UserInfo>('UserInfos');

  // 한국어 날짜 포맷
  await initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
