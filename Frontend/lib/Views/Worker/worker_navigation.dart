// lib/Views/Worker/worker_navigation.dart
// After the worker token is available, syncs the Firebase UID to Strapi.
// This ensures worker.firebaseUid in MySQL = the real anonymous Firebase UID,
// so the backend writes the correct uid into Firestore conversation.participants.

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Worker/worker_home_page.dart';
import 'package:sporta/Views/Worker/worker_courts_page.dart';
import 'package:sporta/Views/Worker/worker_reservations_page.dart';
import 'package:sporta/Views/Worker/worker_upcoming_page.dart';
import 'package:sporta/Views/Worker/worker_chat_page.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final workerNavigationKey = GlobalKey<_WorkerNavigationState>();

class WorkerNavigation extends StatefulWidget {
  final String? workerToken;
  const WorkerNavigation({super.key, this.workerToken});

  @override
  State<WorkerNavigation> createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation>
    with SingleTickerProviderStateMixin {
  void switchToHome() => _onTap(0);
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final _icons = const [
    Icons.dashboard_rounded,
    Icons.sports_tennis_rounded,
    Icons.calendar_month_rounded,
    Icons.today_rounded,
    Icons.chat_bubble_outline_rounded,
  ];

  final _labels = const ['Dashboard', 'Courts', 'Reservations', 'Upcoming', 'Messages'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      WorkerHomePage(workerToken: widget.workerToken),
      WorkerCourtsPage(workerToken: widget.workerToken),
      WorkerReservationsPage(workerToken: widget.workerToken),
      WorkerUpcomingPage(workerToken: widget.workerToken),
      WorkerChatPage(workerToken: widget.workerToken),
    ];

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;

    _initFirebaseForUser();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService().initialize();
      NotificationService().onNotificationTap = (data) {
        _handleNotificationTap(data);
      };
      debugPrint('[WorkerNavigation] Notifications initialized');
    } catch (e) {
      debugPrint('[WorkerNavigation] Notification init error: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('[WorkerNavigation] Notification tapped: $data');
    final screen = data['screen'];
    if (screen == 'chat') {
      _onTap(4); // Messages tab
    } else if (screen == 'reservations') {
      _onTap(2); // Reservations tab
    }
  }

  Future<void> _syncFcmToken(String token, String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await PlayerManagerAuthService.updateFirebaseUid(
          token: token,
          firebaseUid: 'sporta_worker_$userId',
          fcmToken: fcmToken,
        );
        debugPrint('[WorkerNavigation] FCM token synced for worker $userId');
      }
    } catch (e) {
      debugPrint('[WorkerNavigation] FCM token sync error: $e');
    }
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.workerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      // Get Strapi user ID to build deterministic uid
      final profile = await PlayerManagerAuthService.getMe(token);
      final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_worker_{userId}" — unique per worker account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken: token,
        strapiUserId: userId,
        role: 'worker',
      );

      // ✅ Sync FCM token to backend
      await _syncFcmToken(token, userId);

      debugPrint('[WorkerNavigation] Firebase identity ready for worker $userId');
    } catch (e) {
      debugPrint('[WorkerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
              if (!sel) ...[
                const SizedBox(height: 2),
                Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildBody() {
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



















/*// lib/Views/Worker/worker_navigation.dart
// After the worker token is available, syncs the Firebase UID to Strapi.
// This ensures worker.firebaseUid in MySQL = the real anonymous Firebase UID,
// so the backend writes the correct uid into Firestore conversation.participants.

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Worker/worker_home_page.dart';
import 'package:sporta/Views/Worker/worker_courts_page.dart';
import 'package:sporta/Views/Worker/worker_reservations_page.dart';
import 'package:sporta/Views/Worker/worker_upcoming_page.dart';
import 'package:sporta/Views/Worker/worker_chat_page.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final workerNavigationKey = GlobalKey<_WorkerNavigationState>();

class WorkerNavigation extends StatefulWidget {
  final String? workerToken;
  const WorkerNavigation({super.key, this.workerToken});

  @override
  State<WorkerNavigation> createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation>
    with SingleTickerProviderStateMixin {
  void switchToHome() => _onTap(0);
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final _icons = const [
    Icons.dashboard_rounded,
    Icons.sports_tennis_rounded,
    Icons.calendar_month_rounded,
    Icons.today_rounded,
    Icons.chat_bubble_outline_rounded,
  ];

  final _labels = const ['Dashboard', 'Courts', 'Reservations', 'Upcoming', 'Messages'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      WorkerHomePage(workerToken: widget.workerToken),
      WorkerCourtsPage(workerToken: widget.workerToken),
      WorkerReservationsPage(workerToken: widget.workerToken),
      WorkerUpcomingPage(workerToken: widget.workerToken),
      const WorkerChatPage(),
    ];

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;

    _initFirebaseForUser();
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.workerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      // Get Strapi user ID to build deterministic uid
      final profile = await PlayerManagerAuthService.getMe(token);
      final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_worker_{userId}" — unique per worker account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken: token,
        strapiUserId: userId,
        role: 'worker',
      );

      debugPrint('[WorkerNavigation] Firebase identity ready for worker $userId');
    } catch (e) {
      debugPrint('[WorkerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
              if (!sel) ...[
                const SizedBox(height: 2),
                Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildBody() {
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
}*/






//******************************************** 












/*// lib/Views/Worker/worker_navigation.dart
// After the worker token is available, syncs the Firebase UID to Strapi.
// This ensures worker.firebaseUid in MySQL = the real anonymous Firebase UID,
// so the backend writes the correct uid into Firestore conversation.participants.

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Worker/worker_home_page.dart';
import 'package:sporta/Views/Worker/worker_courts_page.dart';
import 'package:sporta/Views/Worker/worker_reservations_page.dart';
import 'package:sporta/Views/Worker/worker_upcoming_page.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final workerNavigationKey = GlobalKey<_WorkerNavigationState>();

class WorkerNavigation extends StatefulWidget {
  final String? workerToken;
  const WorkerNavigation({super.key, this.workerToken});

  @override
  State<WorkerNavigation> createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation>
    with SingleTickerProviderStateMixin {
  void switchToHome() => _onTap(0);
  int _selectedIndex = 0;

  AnimationController? _pageController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final _icons = const [
    Icons.dashboard_rounded,
    Icons.sports_tennis_rounded,
    Icons.calendar_month_rounded,
    Icons.today_rounded,
  ];

  final _labels = const ['Dashboard', 'Courts', 'Reservations', 'Upcoming'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      WorkerHomePage(workerToken: widget.workerToken),
      WorkerCourtsPage(workerToken: widget.workerToken),
      WorkerReservationsPage(workerToken: widget.workerToken),
      WorkerUpcomingPage(workerToken: widget.workerToken),
    ];

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;

    _initFirebaseForUser();
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.workerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      // Get Strapi user ID to build deterministic uid
      final profile = await PlayerManagerAuthService.getMe(token);
      final user = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_worker_{userId}" — unique per worker account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken: token,
        strapiUserId: userId,
        role: 'worker',
      );

      debugPrint('[WorkerNavigation] Firebase identity ready for worker $userId');
    } catch (e) {
      debugPrint('[WorkerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
              if (!sel) ...[
                const SizedBox(height: 2),
                Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildBody() {
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
}*/