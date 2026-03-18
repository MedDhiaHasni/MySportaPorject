import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:sporta/Views/Manager/dashboard.dart';
import 'package:sporta/Views/Manager/venue_page.dart';
import 'package:sporta/Views/Manager/tournaments.dart';
import 'package:sporta/Views/Manager/bookings.dart';
import 'package:sporta/Views/Manager/messages.dart';

class ManagerNavigation extends StatefulWidget {
  const ManagerNavigation({super.key});
  @override
  State<ManagerNavigation> createState() => _ManagerNavigationState();
}

class _ManagerNavigationState extends State<ManagerNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final List<Widget> _screens = const [
    Dashboard(),
    VenuePage(),
    Tournaments(),
    Bookings(),
    Messages(),
  ];

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.stadium_rounded, // ← Venue
    Icons.emoji_events_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_rounded,
  ];

  final List<String> _labels = [
    'Dashboard',
    'Venue', // ← Venue
    'Tournaments',
    'Bookings',
    'Messages',
  ];

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
    ).drive(Tween(begin: 0.0, end: 1.0));
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
    final goingRight = index > _selectedIndex;
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
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    backgroundColor: kBg,
    body: _body(),
    bottomNavigationBar: CurvedNavigationBar(
      key: _navKey,
      index: _selectedIndex,
      height: 65,
      color: kPrimary,
      backgroundColor: Colors.transparent,
      buttonBackgroundColor: Colors.white,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 320),
      onTap: _onTap,
      items: List.generate(_icons.length, (i) {
        final sel = _selectedIndex == i;
        return IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
              if (!sel) ...[
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

  Widget _body() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) {
      return _screens[_selectedIndex];
    }
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, __) => FadeTransition(
        opacity: _fadeAnim!,
        child: SlideTransition(
          position: _slideAnim!,
          child: _screens[_selectedIndex],
        ),
      ),
    );
  }
}
