import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Player/ai_assistant.dart';
import 'package:sporta/Views/Player/chat.dart';
import 'package:sporta/Views/Player/explore.dart';
import 'package:sporta/Views/Player/home.dart';
import 'package:sporta/Views/Player/matches_page.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// Global key — lets any route switch the bottom nav to Home
final navigationKey = GlobalKey<_NavigationState>();

class Navigation extends StatefulWidget {
  Navigation() : super(key: navigationKey);

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation>
    with SingleTickerProviderStateMixin {
  /// Call from anywhere to jump to the Home tab
  void switchToHome() => _onTap(0);
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final List<Widget> _screens = [
    Home(),
    Explore(),
    Matches(),
    Chat(),
    AiAssistant(),
  ];

  // Icons for each tab — used to color them based on selection
  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.explore_rounded,
    Icons.sports_soccer_rounded,
    Icons.chat_bubble_rounded,
    Icons.auto_awesome_rounded,
  ];

  final List<String> _labels = ['Home', 'Explore', 'Matches', 'Chat', 'AI'];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _pageController!,
      curve: Curves.easeOut,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(
      parent: _pageController!,
      curve: Curves.easeOut,
    ).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;

    final bool goingRight = index > _selectedIndex;
    _slideAnim =
        CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(
          Tween<Offset>(
            begin: Offset(goingRight ? 0.06 : -0.06, 0),
            end: Offset.zero,
          ),
        );

    setState(() => _selectedIndex = index);
    _pageController!.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Key is attached so external callers can reach _NavigationState
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF2F4F7),
      body: _buildAnimatedBody(),
      bottomNavigationBar: CurvedNavigationBar(
        key: _navKey,
        index: _selectedIndex,
        height: 65,
        color: const Color(0xFF005D5E), // bar color = teal
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Colors.white, // selected bubble = white
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 320),
        onTap: _onTap,
        items: List.generate(_icons.length, (i) {
          final bool selected = _selectedIndex == i;
          return IgnorePointer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icons[i],
                  size: 24,
                  // selected icon on white bubble = teal, others on teal bar = white
                  color: selected ? const Color(0xFF005D5E) : Colors.white,
                ),
                if (!selected) ...[
                  const SizedBox(height: 2),
                  Text(
                    _labels[i],
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedBody() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) {
      return _screens[_selectedIndex];
    }
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, _) => FadeTransition(
        opacity: _fadeAnim!,
        child: SlideTransition(
          position: _slideAnim!,
          child: _screens[_selectedIndex],
        ),
      ),
    );
  }
}
