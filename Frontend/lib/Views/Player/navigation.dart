// Views/Player/Navigation.dart

// e5er 7ajet zedthom
// Passes playerToken + playerFirebaseUid into all screens that need them.
// firebaseUid is fetched once from the player profile on init.

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Player/ai_assistant.dart';
import 'package:sporta/Views/Player/chat.dart';
import 'package:sporta/Views/Player/explore.dart';
import 'package:sporta/Views/Player/home.dart';
import 'package:sporta/Views/Player/matches_page.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final _icons  = const [Icons.home_rounded, Icons.explore_rounded, Icons.sports_soccer_rounded, Icons.chat_bubble_rounded, Icons.auto_awesome_rounded];
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

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim  = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
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
      
      debugPrint('[Navigation] Notifications initialized');
    } catch (e) {
      debugPrint('[Navigation] Notification init error: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('[Navigation] Notification tapped: $data');
    
    final type = data['type'];
    final screen = data['screen'];
    
    // Navigate based on notification type
    if (screen == 'bookings' || type == 'booking_status_update') { // kif t7el direct mel notifications
      _onTap(0); 
      
      // Show a snackbar to indicate the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['notification']?['body'] ?? 'Your booking has been updated'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (screen == 'chat') {
      _onTap(3); // Navigate to Chat tab
    }
  }

  Future<void> _syncFcmToken(String token, String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await PlayerManagerAuthService.updateFirebaseUid(
          token: token,
          firebaseUid: 'sporta_player_$userId',
          fcmToken: fcmToken,
        );
        debugPrint('[Navigation] FCM token synced for player $userId');
      }
    } catch (e) {
      debugPrint('[Navigation] FCM token sync error: $e');
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

      // Get Strapi user ID to build deterministic uid
      final profile = await PlayerManagerAuthService.getMe(token);
      final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId  = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_player_{userId}" — unique per player account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken:   token,
        strapiUserId:  userId,
        role:          'player',
      );

      //  Sync FCM token to backend
      await _syncFcmToken(token, userId);

      debugPrint('[Navigation] Firebase identity ready for player $userId');
    } catch (e) {
      debugPrint('[Navigation] Firebase init failed: $e');
    }
  }

  @override
  void dispose() { _pageController?.dispose(); super.dispose(); }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    final goingRight = index > _selectedIndex;
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut)
        .drive(Tween<Offset>(begin: Offset(goingRight ? 0.06 : -0.06, 0), end: Offset.zero));
    setState(() => _selectedIndex = index);
    _pageController!.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    backgroundColor: const Color(0xFFF2F4F7),
    body: _buildBody(),
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
        return IgnorePointer(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
          if (!sel) ...[const SizedBox(height: 2),
            Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70))],
        ]));
      }),
    ),
  );

  Widget _buildBody() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) return _screens[_selectedIndex];
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, __) => FadeTransition(opacity: _fadeAnim!,
          child: SlideTransition(position: _slideAnim!, child: _screens[_selectedIndex])),
    );
  }
}

