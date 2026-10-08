// Views/Manager/manager_navigation.dart

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Manager/dashboard.dart';
import 'package:sporta/Views/Manager/venue_page.dart';
import 'package:sporta/Views/Manager/bookings.dart';
import 'package:sporta/Views/Manager/messages.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ManagerNavigation extends StatefulWidget {
  final String? managerToken;
  const ManagerNavigation({super.key, this.managerToken});

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

  final List<IconData> _icons  = [Icons.dashboard_rounded, Icons.stadium_rounded, Icons.calendar_month_rounded, Icons.chat_bubble_rounded];
  final List<String>   _labels = ['Dashboard', 'Venue', 'Bookings', 'Messages'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      Dashboard(managerToken: widget.managerToken),
      VenuePage(managerToken: widget.managerToken),
      Bookings(managerToken: widget.managerToken),
      Messages(managerToken: widget.managerToken, managerName: 'Manager'),
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
      await NotificationService().initialize();
      NotificationService().onNotificationTap = (data) {
        _handleNotificationTap(data);
      };
      debugPrint('[ManagerNavigation] Notifications initialized');
    } catch (e) {
      debugPrint('[ManagerNavigation] Notification init error: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('[ManagerNavigation] Notification tapped: $data');
    final screen = data['screen'];
    if (screen == 'chat') {
      _onTap(3); // Messages tab
    } else if (screen == 'bookings') {
      _onTap(2); // Bookings tab
    }
  }

  Future<void> _syncFcmToken(String token, String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await PlayerManagerAuthService.updateFirebaseUid(
          token: token,
          firebaseUid: 'sporta_manager_$userId',
          fcmToken: fcmToken,
        );
        debugPrint('[ManagerNavigation] FCM token synced for manager $userId');
      }
    } catch (e) {
      debugPrint('[ManagerNavigation] FCM token sync error: $e');
    }
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.managerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      final profile = await PlayerManagerAuthService.getMe(token);
      final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId  = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_manager_{userId}" — unique per manager account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken:   token,
        strapiUserId:  userId,
        role:          'manager',
      );

      // ✅ Sync FCM token to backend
      await _syncFcmToken(token, userId);

      debugPrint('[ManagerNavigation] Firebase identity ready for manager $userId');
    } catch (e) {
      debugPrint('[ManagerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
          if (!sel) ...[const SizedBox(height: 2),
            Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70))],
        ]));
      }),
    ),
  );

  Widget _body() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) return _screens[_selectedIndex];
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, __) => FadeTransition(opacity: _fadeAnim!,
          child: SlideTransition(position: _slideAnim!, child: _screens[_selectedIndex])),
    );
  }
}
















/*// Views/Manager/manager_navigation.dart

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Manager/dashboard.dart';
import 'package:sporta/Views/Manager/venue_page.dart';
import 'package:sporta/Views/Manager/bookings.dart';
import 'package:sporta/Views/Manager/messages.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManagerNavigation extends StatefulWidget {
  final String? managerToken;
  const ManagerNavigation({super.key, this.managerToken});

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

  final List<IconData> _icons  = [Icons.dashboard_rounded, Icons.stadium_rounded, Icons.calendar_month_rounded, Icons.chat_bubble_rounded];
  final List<String>   _labels = ['Dashboard', 'Venue', 'Bookings', 'Messages'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      Dashboard(managerToken: widget.managerToken),
      VenuePage(managerToken: widget.managerToken),
      Bookings(managerToken: widget.managerToken),
      Messages(managerToken: widget.managerToken),
    ];

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim  = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;

    _initFirebaseForUser();
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.managerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      final profile = await PlayerManagerAuthService.getMe(token);
      final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId  = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_manager_{userId}" — unique per manager account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken:   token,
        strapiUserId:  userId,
        role:          'manager',
      );

      debugPrint('[ManagerNavigation] Firebase identity ready for manager $userId');
    } catch (e) {
      debugPrint('[ManagerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
          if (!sel) ...[const SizedBox(height: 2),
            Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70))],
        ]));
      }),
    ),
  );

  Widget _body() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) return _screens[_selectedIndex];
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, __) => FadeTransition(opacity: _fadeAnim!,
          child: SlideTransition(position: _slideAnim!, child: _screens[_selectedIndex])),
    );
  }
}*/




//********************************** 




/*// Views/Manager/manager_navigation.dart

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Manager/dashboard.dart';
import 'package:sporta/Views/Manager/venue_page.dart';
import 'package:sporta/Views/Manager/bookings.dart';
import 'package:sporta/Views/Manager/messages.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManagerNavigation extends StatefulWidget {
  final String? managerToken;
  const ManagerNavigation({super.key, this.managerToken});

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

  final List<IconData> _icons  = [Icons.dashboard_rounded, Icons.stadium_rounded, Icons.calendar_month_rounded, Icons.chat_bubble_rounded];
  final List<String>   _labels = ['Dashboard', 'Venue', 'Bookings', 'Messages'];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      Dashboard(managerToken: widget.managerToken),
      VenuePage(managerToken: widget.managerToken),
      Bookings(managerToken: widget.managerToken),
      const Messages(),
    ];

    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim  = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut).drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;

    _initFirebaseForUser();
  }

  Future<void> _initFirebaseForUser() async {
    try {
      String? token = widget.managerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null || token.isEmpty) return;

      final profile = await PlayerManagerAuthService.getMe(token);
      final user    = profile.containsKey('user') ? profile['user'] as Map<String, dynamic> : profile;
      final userId  = user['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      // uid will be "sporta_manager_{userId}" — unique per manager account
      await FirebaseIdentityService.instance.initForUser(
        strapiToken:   token,
        strapiUserId:  userId,
        role:          'manager',
      );

      debugPrint('[ManagerNavigation] Firebase identity ready for manager $userId');
    } catch (e) {
      debugPrint('[ManagerNavigation] Firebase init failed: $e');
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
        return IgnorePointer(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[i], size: 24, color: sel ? kPrimary : Colors.white),
          if (!sel) ...[const SizedBox(height: 2),
            Text(_labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70))],
        ]));
      }),
    ),
  );

  Widget _body() {
    if (_pageController == null || _fadeAnim == null || _slideAnim == null) return _screens[_selectedIndex];
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (_, __) => FadeTransition(opacity: _fadeAnim!,
          child: SlideTransition(position: _slideAnim!, child: _screens[_selectedIndex])),
    );
  }
}





********************************************


// Views/Manager/manager_navigation.dart
// Same pattern as player Navigation:
// - fetches managerFirebaseUid on init from the manager profile
// - passes it into Messages so Firestore conversations load correctly

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Views/Manager/dashboard.dart';
import 'package:sporta/Views/Manager/venue_page.dart';
import 'package:sporta/Views/Manager/tournaments.dart';
import 'package:sporta/Views/Manager/bookings.dart';
import 'package:sporta/Views/Manager/messages.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManagerNavigation extends StatefulWidget {
  final String? managerToken;
  const ManagerNavigation({super.key, this.managerToken});

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

  // ── Manager identity ──────────────────────────────────────────────────────
  String? _managerFirebaseUid;
  String? _managerName;

  late List<Widget> _screens;

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.stadium_rounded,
    Icons.emoji_events_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_rounded,
  ];

  final List<String> _labels = [
    'Dashboard',
    'Venue',
    'Tournaments',
    'Bookings',
    'Messages',
  ];

  @override
  void initState() {
    super.initState();
    _buildScreens(); // initial build — Messages shows lock state until uid is fetched
    _fetchManagerUid();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slideAnim = CurvedAnimation(parent: _pageController!, curve: Curves.easeOut)
        .drive(Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero));
    _pageController!.value = 1.0;
  }

  void _buildScreens() {
    _screens = [
      Dashboard(managerToken: widget.managerToken),
      VenuePage(managerToken: widget.managerToken),
      const Tournaments(),
      const Bookings(),
      // Pass managerFirebaseUid into Messages
      Messages(
        managerFirebaseUid: _managerFirebaseUid,
        managerName: _managerName,
      ),
    ];
  }

  Future<void> _fetchManagerUid() async {
    try {
      String? token = widget.managerToken;
      if (token == null || token.isEmpty) {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'jwt_token');
      }
      if (token == null) return;

      // Fetch manager profile to get firebaseUid
      final profile = await PlayerManagerAuthService.getMe(token);
      final user = profile.containsKey('user')
          ? profile['user'] as Map<String, dynamic>
          : profile;

      String? uid = user['firebaseUid']?.toString();
      String? name = user['username']?.toString() ?? user['name']?.toString() ?? user['nom']?.toString();

      // Fallback matching backend logic: manager.firebaseUid || `manager_${manager.id}`
      if (uid == null || uid.isEmpty) {
        final userId = user['id']?.toString() ?? '';
        if (userId.isNotEmpty) uid = 'manager_$userId';
      }

      if (mounted && uid != null && uid.isNotEmpty) {
        setState(() {
          _managerFirebaseUid = uid;
          _managerName = name;
          _buildScreens(); // rebuild with real uid
        });
      }
    } catch (e) {
      debugPrint('[ManagerNavigation] Could not fetch manager uid: $e');
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
}*/