import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartmoney/screens/viewmodels/StatViewModel.dart';
import 'package:smartmoney/screens/viewmodels/UserViewModel.dart';
import 'main/HomeScreen.dart';
import 'main/CalendarScreen.dart';
import 'main/StatsScreen.dart';
import 'main/MyPageScreen.dart';
import 'main/CommunityScreen.dart';

const int _pageCnt = 5;

// ✨ 테마 색상 정의 (로그인/회원가입 화면과 통일)
const Color _primaryColor = Color(0xFF4CAF50); // 가계부에 어울리는 녹색 계열
const Color _secondaryColor = Color(0xFFF0F4F8); // 밝은 배경색

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});
  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  late final StatViewModel statVM;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    StatsScreen(),
    CommunityScreen(),
    MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    const duration = Duration(milliseconds: 300);

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      statVM = Provider.of<StatViewModel>(context, listen: false);
      await statVM.loadSpendingData(
        Provider.of<UserViewModel>(context, listen: false).user!.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor, // Scaffold 배경색 통일
      body: PageView(
        // SafeArea 제거: PageView는 일반적으로 전체 화면을 사용
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
    _controllers = List.generate(_pageCnt, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15),
          weight: 50,
        ), // 스케일 축소
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
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
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
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
    return Container(
      // SafeArea는 보통 Scaffold body에 적용하지만, BottomNavigationBar 영역이 명확하므로 Container에서 관리
      decoration: const BoxDecoration(
        color: Colors.white, // 배경색 흰색 고정
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // 은은한 그림자 추가
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        // 하단 노치 영역으로부터 보호
        top: false,
        child: SizedBox(
          height: 65, // 높이 고정
          child: Row(
            children: List.generate(_pageCnt, (index) {
              final isSelected = widget.selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => widget.onTap(index),
                  child: AnimatedBuilder(
                    animation: _controllers[index],
                    builder: (context, child) {
                      final scale = _scaleAnimations[index].value;
                      final rotation = _rotationAnimations[index].value;
                      final highlightValue = _highlightAnimations[index].value;

                      // 애니메이션 색상 (녹색 계열)
                      final Color highlightColor = _primaryColor.withOpacity(
                        0.1,
                      );

                      return Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // ✨ 하이라이트 박스 (녹색으로 변경)
                            if (_controllers[index].isAnimating)
                              Opacity(
                                opacity:
                                    1 - highlightValue, // 애니메이션이 진행될수록 투명해짐
                                child: Container(
                                  width: 50 + 20 * highlightValue,
                                  height: 50 + 20 * highlightValue,
                                  decoration: BoxDecoration(
                                    color: highlightColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                            // 선택된 항목 배경 (항상 표시, 탭 애니메이션과 별개)
                            if (isSelected && !_controllers[index].isAnimating)
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: highlightColor,
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
                                          : Colors
                                                .grey[600], // ✨ 선택 시 primaryColor 적용
                                      size: isSelected
                                          ? 26
                                          : 24, // 선택 시 아이콘 크기 약간 키우기
                                    ),
                                    const SizedBox(height: 2), // 간격 줄임
                                    Text(
                                      _getLabel(index),
                                      style: TextStyle(
                                        fontSize: 11, // 폰트 크기 고정
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors
                                                  .grey[600], // ✨ 선택 시 primaryColor 적용
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
        return Icons.home_rounded; // 둥근 모양 아이콘으로 변경
      case 1:
        return Icons.calendar_month_outlined; // 달력 아이콘 변경
      case 2:
        return Icons.bar_chart_rounded;
      case 3:
        return Icons.people_alt_outlined; // 커뮤니티 아이콘 변경
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
        return "마이페이지"; // 라벨 오타 수정 (마미페이지 -> 마이페이지)
      default:
        return "";
    }
  }
}
