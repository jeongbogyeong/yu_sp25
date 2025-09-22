import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'CalendarScreen.dart';
import 'StatsScreen.dart';
import 'SettingsScreen.dart';
import 'CommunityScreen.dart';

const int _pageCnt =5;

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
    CalendarScreen(),
    StatsScreen(),
    CommunityScreen(),
    SettingsScreen(),

  ];

  void _onItemTapped(int index) {

    final duration = Duration(milliseconds: (300 ));

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
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 스와이프로 넘기지 못하게 막음
          children: _pages,
        ),
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<_CustomBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _highlightAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_pageCnt, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 50),
        TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 25),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _highlightAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant _CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controllers[widget.selectedIndex].forward(from: 0); // 선택된 아이콘 애니메이션 실행
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 65,
        decoration:  BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Stack(
          children: [
            Row(
              children: List.generate(_pageCnt, (index) {
                return Expanded(
                  child: InkWell(
                    onTap: () => widget.onTap(index),
                    child: AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        final scale = _scaleAnimations[index].value;
                        final rotation = _rotationAnimations[index].value;
                        final highlightOpacity = _highlightAnimations[index].value;
      
                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 하이라이트 박스
                              Opacity(
                                opacity: _controllers[index].isAnimating ? (1 - highlightOpacity) : 0,
                                child: Container(
                                  width: 50 + 20 * highlightOpacity,
                                  height: 50 + 20 * highlightOpacity,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: scale,
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getIcon(index),
                                        color: widget.selectedIndex == index
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getLabel(index),
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          fontWeight: widget.selectedIndex == index
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: widget.selectedIndex == index
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.calendar_today;
      case 2:
        return Icons.bar_chart;
      case 3:
        return Icons.people;
      case 4:
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
        return "달력";
      case 2:
        return "통계";
      case 3:
        return "커뮤니티";
      case 4:
        return "설정";
      default:
        return "";
    }
  }
}
