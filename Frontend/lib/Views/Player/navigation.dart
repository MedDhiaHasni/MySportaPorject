// Views/Player/Navigation.dart

// e5er 7ajet zedthom
// Passes playerToken + playerFirebaseUid into all screens that need them.
// firebaseUid is fetched once from the player profile on init.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Views/Player/ai_assistant.dart';
import 'package:sporta/Views/Player/chat.dart';
import 'package:sporta/Views/Player/explore.dart';
import 'package:sporta/Views/Player/home.dart';
import 'package:sporta/Views/Player/matches_page.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Widgets/navigation_components.dart';

final navigationKey = GlobalKey<_NavigationState>();

class Navigation extends StatefulWidget {
  final String? playerToken;
  const Navigation({super.key, this.playerToken});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation>
    with SingleTickerProviderStateMixin {
  void switchToHome() => _onTap(0);
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final _icons = const [
    Icons.home_rounded,
    Icons.explore_rounded,
    Icons.sports_soccer_rounded,
    Icons.chat_bubble_rounded,
    Icons.auto_awesome_rounded,
  ];
  final _labels = const ['Home', 'Explore', 'Matches', 'Chat', 'AI'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      Home(playerToken: widget.playerToken),
      Explore(playerToken: widget.playerToken),
      Matches(playerToken: widget.playerToken),
      Chat(playerToken: widget.playerToken),
      AiAssistant(playerToken: widget.playerToken),
    ];

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

    _initFirebaseForUser();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      // Initialize notification service
      await NotificationService().initialize();

      // Set callback for notification taps
      NotificationService().onNotificationTap = (data) {
        _handleNotificationTap(data);
      };
    } catch (e) {
      AppLogger.error('[Navigation] Notification init error: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final screen = data['screen'];

    // Navigate based on notification type
    if (screen == 'bookings' || type == 'booking_status_update') {
      // kif t7el direct mel notifications
      _onTap(0);

      // Show a snackbar to indicate the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['notification']?['body'] ?? 'Your booking has been updated',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (screen == 'chat') {
      _onTap(3); // Navigate to Chat tab
    }
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.playerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      await FirebaseIdentityService.instance.signInWithStrapiToken(token);
    } catch (e) {
      AppLogger.error('[Navigation] Firebase init failed: $e');
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    final goingRight = index > _selectedIndex;
    HapticFeedback.selectionClick();
    _slideAnim =
        CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(
          Tween<Offset>(
            begin: Offset(goingRight ? 0.06 : -0.06, 0),
            end: Offset.zero,
          ),
        );
    setState(() => _selectedIndex = index);
    if (MediaQuery.disableAnimationsOf(context)) {
          _pageController!.value = 1;
    } else {
      _pageController!.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: _buildBody(),
    bottomNavigationBar: FloatingBottomNav(
          destinations: List.generate(
            _icons.length,
            (index) => PlayerNavDestination(
              label: _labels[index],
              icon: _icons[index],
            ),
          ),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTap,
    ),
  );

  Widget _buildBody() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null)
      return _screens[_selectedIndex];
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, _) => FadeTransition(
        opacity: _fadeAnim!,
        child: SlideTransition(
          position: _slideAnim!,
          child: _screens[_selectedIndex],
        ),
      ),
    );
  }
}
