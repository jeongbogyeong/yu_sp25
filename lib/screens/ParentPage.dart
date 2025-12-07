import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartmoney/screens/viewmodels/StatViewModel.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';

import 'main/HomeScreen.dart';
import 'main/CalendarScreen.dart';
import 'main/StatsScreen.dart';
import 'main/CommunityScreen.dart';
import 'main/MyPageScreen.dart';

const int _pageCnt = 5;

// ✨ 테마 색상 정의
const Color _primaryColor = Color(0xFF4CAF50);
const Color _secondaryColor = Color(0xFFF0F4F8);

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  late final StatViewModel statVM;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(),
    const StatsScreen(),
    const CommunityScreen(),
    MyPageScreen(), // 👈 여기 절대 const 붙이면 안 됨
  ];

  void _onItemTapped(int index) {
    const duration = Duration(milliseconds: 300);

    _pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeInOut,
    );

    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = Provider.of<UserViewModel>(
        context,
        listen: false,
      ).user?.id;

      if (userId != null) {
        statVM = Provider.of<StatViewModel>(context, listen: false);
        await statVM.loadSpendingData(userId);
      } else {
        debugPrint("User ID가 없어 StatViewModel 데이터 로드를 건너뜁니다.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ----------------------------------------------------
// Custom Bottom Navigation Bar
// ----------------------------------------------------
class _CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({required this.selectedIndex, required this.onTap});

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

    _controllers = List.generate(
      _pageCnt,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _scaleAnimations = _controllers
        .map(
          (c) => TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
          ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();

    _rotationAnimations = _controllers
        .map(
          (c) => TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 25),
            TweenSequenceItem(
              tween: Tween(begin: 0.08, end: -0.08),
              weight: 50,
            ),
            TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 25),
          ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();

    _highlightAnimations = _controllers
        .map(
          (c) => Tween(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
  }

  @override
  void didUpdateWidget(covariant _CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controllers[widget.selectedIndex].forward(from: 0);
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: List.generate(_pageCnt, (index) {
              final isSelected = widget.selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => widget.onTap(index),
                  child: AnimatedBuilder(
                    animation: _controllers[index],
                    builder: (context, _) {
                      final scale = _scaleAnimations[index].value;
                      final rotation = _rotationAnimations[index].value;
                      final highlightValue = _highlightAnimations[index].value;

                      return Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_controllers[index].isAnimating)
                              Opacity(
                                opacity: 1 - highlightValue,
                                child: Container(
                                  width: 50 + 20 * highlightValue,
                                  height: 50 + 20 * highlightValue,
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            if (isSelected && !_controllers[index].isAnimating)
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
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
                                      color: isSelected
                                          ? _primaryColor
                                          : Colors.grey[600],
                                      size: isSelected ? 26 : 24,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getLabel(index),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors.grey[600],
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
        ),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.calendar_month_outlined;
      case 2:
        return Icons.bar_chart_rounded;
      case 3:
        return Icons.people_alt_outlined;
      case 4:
        return Icons.person_rounded;
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
        return "마이페이지";
      default:
        return "";
    }
  }
}
