// lib/Views/Player/home.dart
// e5er 7aja salla7t el cancel flow 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Views/Player/HomeSettings.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Explore.dart';
import 'matches_page.dart';
import 'package:sporta/Widgets/star_rating.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';

// 
// VENUE MODEL
// 
class PlayerVenue {
  final String id, name, location, imageUrl, openUntil;
  final List<String> sports, amenities;
  final double minPrice, maxPrice, rating;
  final int totalRatings;
  final bool isActive;
  final String distance;
  final double? lat, lng;

  PlayerVenue({
    required this.id, required this.name, required this.location,
    required this.imageUrl, required this.openUntil,
    required this.sports, required this.amenities,
    required this.minPrice, required this.maxPrice,
    required this.isActive,
    this.rating = 0.0, this.totalRatings = 0,
    this.distance = '1.5 km', this.lat, this.lng,
  });

  factory PlayerVenue.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return [v];
      return [];
    }

    final base = ApiConstants.mediaBaseUrl;
    String imageUrl = '';
    if (json['photo'] is Map && json['photo']['url'] != null) {
      final p = json['photo']['url'].toString();
      imageUrl = p.startsWith('http') ? p : '$base$p';
    }

    double minPrice = 0, maxPrice = 0;
    if (json['courts'] is List) {
      final prices = (json['courts'] as List).map((c) {
        if (c is Map && c['pricePerHour'] != null) return (c['pricePerHour'] as num).toDouble();
        return 0.0;
      }).where((p) => p > 0).toList();
      if (prices.isNotEmpty) {
        minPrice = prices.reduce((a, b) => a < b ? a : b);
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
    }

    return PlayerVenue(
      id:           json['id'].toString(),
      name:         json['name'] ?? '',
      location:     json['location'] ?? '',
      imageUrl:     imageUrl,
      sports:       parseList(json['sports']),
      amenities:    parseList(json['amenities']),
      minPrice:     minPrice,
      maxPrice:     maxPrice,
      isActive:     json['isActive'] ?? true,
      openUntil:    json['closeTime'] ?? '23:00',
      rating:       (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['total_rating'] as num?)?.toInt() ?? 0,
      lat:          json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng:          json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

// 
// ANNOUNCEMENT MODEL
// 
class PlayerAnnouncement {
  final String id;
  final String courtName;
  final String venueName;
  final String date;
  final String startTime;
  final String endTime;
  final String description;
  final int playersNeeded;
  final int acceptedCount;
  final int spotsLeft;
  final String status;
  final String? courtImageUrl;
  final DateTime bookingDate;

  PlayerAnnouncement({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.playersNeeded,
    required this.acceptedCount,
    required this.spotsLeft,
    required this.status,
    this.courtImageUrl,
    required this.bookingDate,
  });

  bool get isActive {
    final today = DateTime.now();
    final bookingDateObj = DateTime.parse(date);
    return bookingDateObj.isAfter(today.subtract(const Duration(days: 1)));
  }

  factory PlayerAnnouncement.fromJson(Map<String, dynamic> json) {
    final court = json['court'] ?? {};
    final venue = court['venue'] ?? {};
    
    String? courtImageUrl;
    if (court['court_img_url'] != null) {
      courtImageUrl = _getFullImageUrlStatic(court['court_img_url'].toString());
    } else if (court['court_img'] != null && court['court_img']['url'] != null) {
      courtImageUrl = _getFullImageUrlStatic(court['court_img']['url'].toString());
    } else if (court['photos_urls'] != null && court['photos_urls'] is List && court['photos_urls'].isNotEmpty) {
      courtImageUrl = _getFullImageUrlStatic(court['photos_urls'][0].toString());
    }
    
    final playersNeeded = json['players_needed'] ?? 0;
    final acceptedCount = json['join_requests']?.where((jr) => jr['status'] == 'accepted').length ?? 0;
    final spotsLeft = playersNeeded - acceptedCount;
    
    DateTime bookingDate = DateTime.now();
    final bookingDateStr = json['booking_date_play']?.toString().split('T')[0];
    if (bookingDateStr != null) {
      try {
        bookingDate = DateTime.parse(bookingDateStr);
      } catch (e) {}
    }
    
    return PlayerAnnouncement(
      id: json['id'].toString(),
      courtName: court['name'] ?? 'Unknown Court',
      venueName: venue['name'] ?? 'Unknown Venue',
      date: bookingDateStr ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      description: json['description'] ?? '',
      playersNeeded: playersNeeded,
      acceptedCount: acceptedCount,
      spotsLeft: spotsLeft,
      status: json['status'] ?? 'open',
      courtImageUrl: courtImageUrl,
      bookingDate: bookingDate,
    );
  }
  
  static String _getFullImageUrlStatic(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }
}

// 
// HOME
// 
class Home extends StatefulWidget {
  final String? playerToken;
  const Home({super.key, this.playerToken});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedSport = 0;
  final _searchCtrl  = TextEditingController();
  String _searchQuery = '';

  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser  = true;
  String? _playerPhotoUrl;

  List<PlayerVenue> _venues    = [];
  bool _isLoadingVenues        = true;
  String? _venuesError;

  List<PlayerAnnouncement> _myAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  final _sports = const [
    {'label': 'All',        'icon': Icons.sports_rounded},
    {'label': 'Football',   'icon': Icons.sports_soccer_rounded},
    {'label': 'Padel',      'icon': Icons.sports_tennis_rounded},
    {'label': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'label': 'Tennis',     'icon': Icons.sports_tennis},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVenues();
    _initBookingStore();
    _loadMyAnnouncements();
    BookingStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onStoreUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBookingStore() async {
    final token = await _getToken();
    if (token != null) {
      await BookingStore.instance.initialize(token);
      if (mounted) setState(() {});
    }
  }

  void _onStoreUpdate() { if (mounted) setState(() {}); }

  Future<String?> _getToken() async {
    if (widget.playerToken?.isNotEmpty == true) return widget.playerToken;
    return const FlutterSecureStorage().read(key: 'jwt_token');
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final token = await _getToken();
      if (token == null) { setState(() => _isLoadingUser = false); return; }
      final response = await PlayerManagerAuthService.getMe(token);
      setState(() {
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          if (response['photoUrl'] != null && response['photoUrl'].toString().isNotEmpty) {
            _playerPhotoUrl = response['photoUrl'];
          } else if (response['profile'] is Map) {
            final profile = response['profile'] as Map<String, dynamic>;
            if (profile['photo'] is Map && profile['photo']['url'] != null) {
              _playerPhotoUrl = ApiConstants.getFullImageUrl(profile['photo']['url'].toString());
            }
          }
        } else {
          _currentUser = response;
          if (response['photoUrl'] != null) _playerPhotoUrl = response['photoUrl'];
        }
        _isLoadingUser = false;
      });
    } catch (_) { setState(() => _isLoadingUser = false); }
  }

  Future<void> _loadVenues() async {
    setState(() { _isLoadingVenues = true; _venuesError = null; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/public/venues?populate[photo]=*&populate[courts]=*'),
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _venues          = list.map((j) => PlayerVenue.fromJson(j as Map<String, dynamic>)).toList();
          _isLoadingVenues = false;
        });
      } else {
        throw Exception('Failed to load venues');
      }
    } catch (e) {
      setState(() { _venuesError = e.toString().replaceAll('Exception:', '').trim(); _isLoadingVenues = false; });
    }
  }

  Future<void> _loadMyAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingAnnouncements = false);
        return;
      }
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/announcements/mine'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> announcements = data['data'] ?? [];
        final allAnnouncements = announcements.map((a) => PlayerAnnouncement.fromJson(a)).toList();
        final activeAnnouncements = allAnnouncements.where((a) => a.isActive).toList();
        setState(() {
          _myAnnouncements = activeAnnouncements;
          _isLoadingAnnouncements = false;
        });
      } else {
        setState(() => _isLoadingAnnouncements = false);
      }
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: kRed), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/announcements/$announcementId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        await _loadMyAnnouncements();
        _showSnackBar('Announcement deleted successfully', kGreen);
      } else {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      _showSnackBar('Error: $e', kRed);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL FLOW — shows reason dialog then calls requestCancel
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _requestCancelReservation(LocalBooking booking) async {
    if (booking.status == 'cancel_requested') {
      _showSnackBar('Cancellation already requested. Waiting for worker approval.', kAmber);
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CancelReasonDialog(courtName: booking.courtName),
    );

    if (reason == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final svc = ReservationService(token: token);
      await svc.requestCancel(booking.id, reason: reason);

      await BookingStore.instance.initialize(token);
      if (mounted) {
        _showSnackBar(
          'Cancellation request sent. The worker will review it shortly.',
          kPrimary,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString().replaceAll('Exception:', '').trim()}', kRed);
    }
  }

  Future<void> _postAnnouncementFromBooking(LocalBooking booking) async {
    final token = await _getToken();
    if (token == null) {
      _showSnackBar('Please login to post an announcement', kRed);
      return;
    }
    
    if (BookingStore.instance.hasAnnouncementForReservation(booking.id)) {
      _showSnackBar('You already have an announcement for this booking', kAmber);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PostAnnouncementSheet(
        booking: booking,
        playerToken: token,
        onPosted: () {
          _loadMyAnnouncements();
          BookingStore.instance.refresh();
        },
      ),
    );
  }

  void _showAnnouncementDetail(PlayerAnnouncement announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementDetailSheet(
        announcement: announcement,
        onDelete: () {
          Navigator.pop(ctx);
          _deleteAnnouncement(announcement.id);
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── User helpers ──────────────────────────────────────────────────────────
  String get _userName {
    if (_currentUser == null) return 'Player';
    return _currentUser!['username']?.toString() ?? _currentUser!['name']?.toString() ?? 'Player';
  }
  String get _userInitials {
    final name = _userName;
    if (name.isEmpty || name == 'Player') return 'P';
    final parts = name.trim().split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : name[0].toUpperCase();
  }
  String get _userEmail => _currentUser?['email']?.toString() ?? '';
  String get _userPhone => _currentUser?['phone']?.toString() ?? '';
  String _getTimeOfDay() { final h = DateTime.now().hour; if (h < 12) return 'morning'; if (h < 17) return 'afternoon'; return 'evening'; }

  List<PlayerVenue> get _filteredVenues {
    final lbl = _sports[_selectedSport]['label'] as String;
    return _venues.where((v) {
      final matchSport  = lbl == 'All' || v.sports.any((s) => s.toLowerCase() == lbl.toLowerCase());
      final q           = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty || v.name.toLowerCase().contains(q) || v.location.toLowerCase().contains(q);
      return matchSport && matchSearch && v.isActive;
    }).toList();
  }

  List<LocalBooking> get _upcomingBookings => BookingStore.instance.upcomingBookings;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F4F7),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildSearchBar(),
            const SizedBox(height: 28),
            _buildSectionTitle('Nearby Venues'),
            const SizedBox(height: 12),
            _buildSportFilter(),
            const SizedBox(height: 12),
            _buildVenueCards(),
            const SizedBox(height: 28),
            if (_upcomingBookings.isNotEmpty) ...[
              _buildSectionTitle('Upcoming Bookings'),
              const SizedBox(height: 12),
              _buildUpcomingBookings(),
              const SizedBox(height: 8),
            ],
            if (_myAnnouncements.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildSectionTitle('My Announcements'),
              const SizedBox(height: 12),
              _buildMyAnnouncements(),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 100),
          ])),
        ),
      ],
    ),
  );

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    color: Colors.white,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            pageBuilder: (_, anim, __) => HomeSettings(
              username: _userName, email: _userEmail, phone: _userPhone,
              playerToken: widget.playerToken,
              currentPhotoUrl: _playerPhotoUrl,
            ),
            transitionsBuilder: (_, anim, __, child) {
              final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
              return FadeTransition(opacity: curved,
                child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(curved), child: child));
            },
          )),
          child: Hero(tag: 'profile_avatar',
            child: Container(width: 46, height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [kPrimary, Color(0xFF007B7D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 4))]),
              child: ClipOval(child: _isLoadingUser
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : (_playerPhotoUrl != null && _playerPhotoUrl!.isNotEmpty
                      ? Image.network(_playerPhotoUrl!, fit: BoxFit.cover, width: 46, height: 46,
                          errorBuilder: (_, __, ___) => Center(child: Text(_userInitials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))))
                      : Center(child: Text(_userInitials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))))))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good ${_getTimeOfDay()} 👋', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 1),
          Text(_isLoadingUser ? 'Loading...' : _userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D), letterSpacing: -0.3)),
        ])),
        Stack(clipBehavior: Clip.none, children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.notifications_outlined, color: kPrimary, size: 21)),
          Positioned(right: 10, top: 10,
            child: Container(width: 9, height: 9,
              decoration: BoxDecoration(color: const Color(0xFF4ADE80), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
        ]),
      ]),
    )),
  );

  Widget _buildSearchBar() => Container(
    height: 50,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Row(children: [
      const SizedBox(width: 14),
      Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
      const SizedBox(width: 10),
      Expanded(child: TextField(
        controller: _searchCtrl, onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D0D0D)),
        decoration: InputDecoration(hintText: 'Search venues, locations...', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), border: InputBorder.none, isDense: true))),
      if (_searchQuery.isNotEmpty)
        GestureDetector(onTap: () => setState(() { _searchQuery = ''; _searchCtrl.clear(); }),
          child: Padding(padding: const EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400])))
      else
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Explore(playerToken: widget.playerToken))),
          child: Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [Icon(Icons.tune_rounded, color: Colors.white, size: 14), SizedBox(width: 4), Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))]))),
    ]),
  );

  Widget _buildSectionTitle(String title) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D))),
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Explore(playerToken: widget.playerToken))),
      child: const Text('See all', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600))),
  ]);

  Widget _buildSportFilter() => SizedBox(height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: _sports.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final sel = _selectedSport == i;
        return GestureDetector(onTap: () => setState(() => _selectedSport = i),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: sel ? kPrimary : Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Row(children: [
              Icon(_sports[i]['icon'] as IconData, size: 14, color: sel ? Colors.white : Colors.grey[500]),
              const SizedBox(width: 5),
              Text(_sports[i]['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[600])),
            ])));
      },
    ),
  );

  Widget _buildVenueCards() {
    if (_isLoadingVenues) return SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: kPrimary)));
    if (_venuesError != null) return SizedBox(height: 220,
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 32, color: kRed), const SizedBox(height: 8),
        Text(_venuesError!, style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _loadVenues, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Retry')),
      ])));
    final venues = _filteredVenues;
    if (venues.isEmpty) return SizedBox(height: 220,
      child: Center(child: Text(_searchQuery.isNotEmpty ? 'No venues found' : 'No venues available',
          style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500))));

    return SizedBox(height: 240,
      child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: venues.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final v = venues[i];
          return Container(width: 190,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(height: 90, width: double.infinity,
                  child: v.imageUrl.isNotEmpty
                      ? Image.network(v.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.1), child: Icon(Icons.stadium_rounded, size: 30, color: kPrimary.withOpacity(0.3))))
                      : Container(color: kPrimary.withOpacity(0.1), child: Icon(Icons.stadium_rounded, size: 30, color: kPrimary.withOpacity(0.3))))),
              Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D))),
                const SizedBox(height: 3),
                Row(children: [const Icon(Icons.location_on_rounded, size: 11, color: Colors.grey), const SizedBox(width: 2),
                  Expanded(child: Text(v.location, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                  Text(v.distance, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary))]),
                if (v.totalRatings > 0) ...[
                  const SizedBox(height: 4),
                  Row(children: [StarRating(rating: v.rating, size: 10, interactive: false), const SizedBox(width: 3),
                    Text(v.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
                    const SizedBox(width: 2), Text('(${v.totalRatings})', style: TextStyle(fontSize: 9, color: Colors.grey[500]))]),
                ],
                const SizedBox(height: 6),
                Text(v.minPrice != v.maxPrice ? '${v.minPrice.toInt()}–${v.maxPrice.toInt()} DT' : '${v.minPrice.toInt()} DT',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
              ])),
            ]));
        }));
  }

  // ── My Announcements Section ──────────────────────────────────────────────
  Widget _buildMyAnnouncements() {
    return Column(
      children: _myAnnouncements.map((announcement) {
        final spotsLeft = announcement.spotsLeft;
        final statusColor = spotsLeft > 0 ? kGreen : kRed;
        final statusText = spotsLeft > 0 ? '$spotsLeft spots left' : 'Full';
        
        return GestureDetector(
          onTap: () => _showAnnouncementDetail(announcement),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: announcement.courtImageUrl != null && announcement.courtImageUrl!.isNotEmpty
                        ? Image.network(
                            announcement.courtImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: kPrimary.withOpacity(0.08),
                              child: const Icon(Icons.stadium_rounded, size: 40, color: kPrimary),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: kPrimary.withOpacity(0.08),
                                child: const Center(
                                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: kPrimary.withOpacity(0.08),
                            child: const Icon(Icons.stadium_rounded, size: 40, color: kPrimary),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.courtName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              announcement.venueName,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.date} · ${announcement.startTime} - ${announcement.endTime}',
                            style: const TextStyle(fontSize: 11, color: kTextMid),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _AnnouncementStat(
                            icon: Icons.people_rounded,
                            value: '${announcement.playersNeeded}',
                            label: 'Needed',
                            color: kPrimary,
                          ),
                          const SizedBox(width: 8),
                          _AnnouncementStat(
                            icon: Icons.check_circle_outline_rounded,
                            value: '${announcement.acceptedCount}',
                            label: 'Joined',
                            color: kGreen,
                          ),
                          const SizedBox(width: 8),
                          _AnnouncementStat(
                            icon: Icons.hourglass_top_rounded,
                            value: '$spotsLeft',
                            label: 'Left',
                            color: kAmber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Upcoming Bookings with status-aware cancel button ─────────────────────
  Widget _buildUpcomingBookings() {
    final bookings = _upcomingBookings;
    return Column(
      children: bookings.map((b) {
        final status      = b.status;
        final isConfirmed = status == 'confirmed';
        final isCancelReq = status == 'cancel_requested';
        final isPending   = status == 'pending';

        final Color statusColor;
        final String statusLabel;
        final IconData statusIcon;

        if (isCancelReq) {
          statusColor = const Color(0xFFF97316);
          statusLabel = 'Cancel Requested';
          statusIcon  = Icons.hourglass_top_rounded;
        } else if (isConfirmed) {
          statusColor = kGreen;
          statusLabel = 'Confirmed';
          statusIcon  = Icons.check_circle_rounded;
        } else if (status == 'rejected') {
          statusColor = kRed;
          statusLabel = 'Rejected';
          statusIcon  = Icons.cancel_rounded;
        } else {
          statusColor = kAmber;
          statusLabel = 'Pending';
          statusIcon  = Icons.pending_rounded;
        }

        String courtImageUrl = b.courtImageUrl;
        if (courtImageUrl.isNotEmpty && !courtImageUrl.startsWith('http')) {
          courtImageUrl = ApiConstants.getFullImageUrl(courtImageUrl);
        }

        return GestureDetector(
          onTap: () => _showBookingDetailDialog(b),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(children: [
              Row(children: [
                ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(width: 70, height: 84,
                    child: courtImageUrl.isNotEmpty
                        ? Image.network(courtImageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.07), child: const Icon(Icons.stadium_rounded, color: kPrimary, size: 24)))
                        : Container(color: kPrimary.withOpacity(0.07), child: const Icon(Icons.stadium_rounded, color: kPrimary, size: 24)))),
                Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D))),
                    const SizedBox(height: 2),
                    Text(b.venueName, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${b.date} · ${b.time}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${b.price} DT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b.reference, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ]),
                  ]))),
                Padding(padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 10, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ]))),
              ]),
              if (isCancelReq)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: Colors.orange.withOpacity(0.2)))),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 13, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Cancellation requested — waiting for worker approval',
                        style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600))),
                  ])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  void _showBookingDetailDialog(LocalBooking booking) {
    final status      = booking.status;
    final isCancelReq = status == 'cancel_requested';
    final canCancel   = ['pending', 'confirmed'].contains(status);
    final isConfirmed = status == 'confirmed';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(booking.courtName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoRow(Icons.location_on_rounded, 'Venue', booking.venueName),
          const SizedBox(height: 8),
          _InfoRow(Icons.calendar_today_rounded, 'Date', booking.date),
          const SizedBox(height: 8),
          _InfoRow(Icons.access_time_rounded, 'Time', booking.time),
          const SizedBox(height: 8),
          _InfoRow(Icons.attach_money_rounded, 'Price', '${booking.price} DT'),
          const SizedBox(height: 8),
          _InfoRow(Icons.receipt_long_rounded, 'Reference', booking.reference),
          const SizedBox(height: 8),
          _InfoRow(Icons.info_outline_rounded, 'Status', _statusLabel(status),
              valueColor: _statusColor(status)),
          if (isCancelReq) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
              child: const Text('Cancellation is pending worker/manager approval. You will be notified.',
                  style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.4))),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (isConfirmed)
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _postAnnouncementFromBooking(booking); },
              icon: const Icon(Icons.campaign_rounded, size: 16),
              label: const Text('Post Announcement'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          if (canCancel)
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _requestCancelReservation(booking); },
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Request Cancellation'),
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':        return 'Confirmed';
      case 'cancel_requested': return 'Cancel Requested';
      case 'cancelled':        return 'Cancelled';
      case 'completed':        return 'Completed';
      case 'rejected':         return 'Rejected';
      default:                 return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':        return kGreen;
      case 'cancel_requested': return Colors.orange;
      case 'cancelled':        return kRed;
      case 'completed':        return Colors.blue;
      case 'rejected':         return kRed;
      default:                 return kAmber;
    }
  }
}

// 
// CANCEL REASON DIALOG
// 
class _CancelReasonDialog extends StatefulWidget {
  final String courtName;
  const _CancelReasonDialog({required this.courtName});
  @override State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _ctrl       = TextEditingController();
  String _selected  = '';
  bool   _otherMode = false;

  static const _quickReasons = [
    'Change of plans',
    'Bad weather',
    'Injury / health issue',
    'Found another venue',
    'Work / schedule conflict',
    'Other…',
  ];

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _pickReason(String r) {
    setState(() {
      if (r == 'Other…') {
        _otherMode = true;
        _selected  = '';
      } else {
        _otherMode = false;
        _selected  = r;
      }
    });
  }

  bool get _canConfirm => _otherMode ? _ctrl.text.trim().isNotEmpty : _selected.isNotEmpty;

  String get _finalReason => _otherMode ? _ctrl.text.trim() : _selected;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.cancel_outlined, color: kRed, size: 18)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Request Cancellation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 6),
      Text('${widget.courtName}', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
    ]),
    content: SizedBox(width: double.maxFinite,
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 4),
        const Text('Why do you want to cancel?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _quickReasons.map((r) {
          final isOtherSel = r == 'Other…' && _otherMode;
          final isSel      = _selected == r || isOtherSel;
          return GestureDetector(
            onTap: () => _pickReason(r),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSel ? kRed : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? kRed : Colors.grey.shade300)),
              child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? Colors.white : Colors.grey[700]))));
        }).toList()),
        if (_otherMode) ...[
          const SizedBox(height: 12),
          StatefulBuilder(builder: (_, setInner) => TextField(
            controller: _ctrl,
            maxLines: 3, minLines: 2,
            onChanged: (_) { setInner(() {}); setState(() {}); },
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describe your reason…',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kRed, width: 1.5)),
              contentPadding: const EdgeInsets.all(12)),
          )),
        ],
        const SizedBox(height: 4),
      ]))),
    actions: [
      Row(children: [
        Expanded(child: TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
          child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(
          onPressed: _canConfirm ? () => Navigator.pop(context, _finalReason) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: kRed, foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.w700)))),
      ]),
    ],
  );
}

// 
// POST ANNOUNCEMENT SHEET
// 
class _PostAnnouncementSheet extends StatefulWidget {
  final LocalBooking booking;
  final String playerToken;
  final VoidCallback onPosted;

  const _PostAnnouncementSheet({
    required this.booking,
    required this.playerToken,
    required this.onPosted,
  });

  @override
  State<_PostAnnouncementSheet> createState() => _PostAnnouncementSheetState();
}

class _PostAnnouncementSheetState extends State<_PostAnnouncementSheet> {
  int _playersNeeded = 2;
  final TextEditingController _descCtrl = TextEditingController();
  bool _posting = false;
  late AnnouncementService _announcementService;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService(token: widget.playerToken);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _posting = true);

    try {
      final announcement = await _announcementService.create(
        reservationId: widget.booking.id,
        description: _descCtrl.text.trim(),
        playersNeeded: _playersNeeded,
      );

      print('Announcement created successfully: ${announcement.id}');

      if (!mounted) return;
      
      widget.onPosted();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Announcement posted!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error posting announcement: $e');
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post announcement: $e'),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC5C9D4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: kPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Make an Announcement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.3)),
                        Text('Find teammates for your session', style: TextStyle(fontSize: 12, color: kTextMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: const Color(0xFFE8EDF3)),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(20, 18, 20, bot + 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kPrimary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer_rounded, size: 16, color: kPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.booking.courtName}  ·  ${widget.booking.date}  ·  ${widget.booking.time}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Players needed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
                            SizedBox(height: 2),
                            Text('How many more players to join?', style: TextStyle(fontSize: 11, color: kTextMid)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8EDF3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded > 1) setState(() => _playersNeeded--);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                child: Icon(Icons.remove_rounded, size: 16, color: _playersNeeded > 1 ? kPrimary : kTextLight),
                              ),
                            ),
                            Text('$_playersNeeded', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded < 20) setState(() => _playersNeeded++);
                              },
                              child: Container(width: 40, height: 40, child: const Icon(Icons.add_rounded, size: 16, color: kPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EDF3)),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(fontSize: 14, color: kTextDark, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Friendly match, intermediate level. All welcome!',
                        hintStyle: TextStyle(color: kTextLight, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _posting ? null : _post,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: Center(
                        child: _posting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.campaign_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Post Announcement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 
// ANNOUNCEMENT DETAIL SHEET
// 
class _AnnouncementDetailSheet extends StatelessWidget {
  final PlayerAnnouncement announcement;
  final VoidCallback onDelete;

  const _AnnouncementDetailSheet({
    required this.announcement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final spotsLeft = announcement.spotsLeft;
    final statusColor = spotsLeft > 0 ? kGreen : kRed;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFC5C9D4),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),
          if (announcement.courtImageUrl != null && announcement.courtImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Image.network(
                announcement.courtImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: kPrimary.withOpacity(0.08),
                  child: const Icon(Icons.stadium_rounded, size: 60, color: kPrimary),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: kPrimary.withOpacity(0.08),
                    child: const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        announcement.courtName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      announcement.venueName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      announcement.date,
                      style: const TextStyle(fontSize: 13, color: kTextMid),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${announcement.startTime} - ${announcement.endTime}',
                      style: const TextStyle(fontSize: 13, color: kTextMid),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.people_rounded,
                        value: '${announcement.playersNeeded}',
                        label: 'Players Needed',
                        color: kPrimary,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.check_circle_outline_rounded,
                        value: '${announcement.acceptedCount}',
                        label: 'Joined',
                        color: kGreen,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.hourglass_top_rounded,
                        value: '$spotsLeft',
                        label: 'Spots Left',
                        color: kAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kRed.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: kRed),
                        SizedBox(width: 8),
                        Text(
                          'Delete Announcement',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 
// ANNOUNCEMENT STAT
// 
class _AnnouncementStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _AnnouncementStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: kTextMid),
          ),
        ],
      ),
    );
  }
}

// 
// DETAIL STAT
// 
class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: kTextMid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 
// INFO ROW
// 
class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: Colors.grey[500]),
    const SizedBox(width: 8),
    SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMid))),
    Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueColor ?? kTextDark))),
  ]);
}
