
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/author.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'screens/HomeScreen.dart';
import 'screens/AccountScreen.dart';
import 'screens/StatsScreen.dart';
import 'screens/SettingsScreen.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AuthorTypeAdapter());
  Hive.registerAdapter(AuthorAdapter());
  Hive.registerAdapter(PostAdapter());
  Hive.registerAdapter(CommentAdapter());
  await Hive.openBox<Post>('community_posts');
  await Hive.openBox<Comment>('community_comments');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);//상태바 없애기
    return MaterialApp(
      title: '가계부 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AccountScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    final distance = (index - _selectedIndex).abs();

    // 멀리 이동할수록 duration 짧게 → "빠르게 건너뛰는 느낌"
    final duration = Duration(milliseconds: (300 ~/ (distance > 0 ? distance : 1)));

    _pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeInOut,
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 스와이프로 넘기지 못하게 막음
        children: _pages,
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(
              -1.0 + (2 * selectedIndex) / 3, // 4개 버튼 기준
              0,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              height: 65,
              color: Colors.blue.shade100,
            ),
          ),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: index < 3
                            ? const BorderSide(color: Colors.grey, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIcon(index),
                          color: selectedIndex == index ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLabel(index),
                          style: TextStyle(
                            color: selectedIndex == index ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.account_balance;
      case 2:
        return Icons.bar_chart;
      case 3:
        return Icons.settings;
      default:
        return Icons.help;
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return "홈";
      case 1:
        return "가계부";
      case 2:
        return "통계";
      case 3:
        return "설정";
      default:
        return "";
    }
  }
}

