// dashboard.dart — Views/Manager/dashboard.dart
// Manager home: uses CourtModel, CourtReservation
// Updated: Today's schedule now matches bookings_page.dart style fully
// — court image hero, sport/worker chips, pending call strip, confirm/decline

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/venue_service.dart';
import 'package:sporta/Services/court_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────
String _getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${ApiConstants.mediaBaseUrl}$url';
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL MODELS
// ─────────────────────────────────────────────────────────────────────────────
class DashboardVenue {
  final String id, name, location, closeTime;
  final bool isActive;
  final List<String> sports, amenities;
  final String imageUrl;

  DashboardVenue({
    required this.id, required this.name, required this.location,
    required this.closeTime, required this.isActive,
    required this.sports, required this.amenities, required this.imageUrl,
  });

  factory DashboardVenue.fromJson(Map<String, dynamic> json) {
    List<String> sportsList = [];
    if (json['sports'] is List) sportsList = (json['sports'] as List).map((s) => s.toString()).toList();
    List<String> amenitiesList = [];
    if (json['amenities'] is List) amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    String imageUrl = '';
    if (json['photo']?['url'] != null) imageUrl = ApiConstants.getFullImageUrl(json['photo']['url'].toString());
    return DashboardVenue(
      id: json['id'].toString(), name: json['name'] ?? '',
      location: json['location'] ?? '', closeTime: json['closeTime'] ?? '23:00',
      isActive: json['isActive'] ?? true, sports: sportsList,
      amenities: amenitiesList, imageUrl: imageUrl,
    );
  }
}

class DashboardCourt {
  final String id, name, location, venueId;
  final SportType sport;
  final double pricePerHour;
  final Color color;
  final String? imageUrl, courtImgUrl;
  final List<String> photosUrls;
  bool isActive;

  DashboardCourt({
    required this.id, required this.name, required this.location,
    required this.venueId, required this.sport, required this.pricePerHour,
    required this.color, this.imageUrl, this.courtImgUrl,
    this.photosUrls = const [], required this.isActive,
  });

  String get displayImageUrl {
    if (courtImgUrl != null && courtImgUrl!.isNotEmpty) return courtImgUrl!;
    if (photosUrls.isNotEmpty) return photosUrls.first;
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    return '';
  }
}

class ManagerBooking {
  final String id;
  final CourtReservation reservation;
  final String playerName, playerPhone, bookingReference;
  bool isPending;
  String bookingStatus;
  final String? workerName, workerId;

  ManagerBooking({
    required this.id, required this.reservation,
    required this.playerName, required this.playerPhone,
    required this.bookingReference,
    this.isPending = true, this.bookingStatus = 'pending',
    this.workerName, this.workerId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  final String? managerToken;
  const Dashboard({super.key, this.managerToken});
  @override State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedVenueIndex = 0;
  List<DashboardVenue>  _venues   = [];
  List<DashboardCourt>  _allCourts = [];
  List<DashboardCourt>  _courts   = [];
  List<ManagerBooking>  _bookings = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true, _isLoadingCourts = false, _isLoadingBookings = false;
  String? _error;

  @override void initState() { super.initState(); _loadUserData(); _loadVenues(); _loadBookings(); }

  // ── getters ──────────────────────────────────────────────────────────────
  String get _managerName => _currentUser?['username']?.toString() ?? _currentUser?['name']?.toString() ?? 'Manager';
  String get _managerInitials {
    final n = _managerName;
    if (n.isEmpty || n == 'Manager') return 'M';
    final p = n.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : n[0].toUpperCase();
  }
  Map<String, dynamic>? get _currentUserData => _currentUser == null ? null : {
    'username': _currentUser!['username'] ?? _managerName,
    'email':    _currentUser!['email']    ?? '',
    'phone':    _currentUser!['phone']    ?? '',
    'photoUrl': _currentUser!['photoUrl'],
  };
  int get _pending => _bookings.where((b) => b.isPending).length;
  int get _active  => _courts.where((c) => c.isActive).length;

  // ── data loading ──────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    if (widget.managerToken?.isNotEmpty == true) return widget.managerToken;
    return const FlutterSecureStorage().read(key: 'jwt_token');
  }

  Future<void> _loadUserData() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await PlayerManagerAuthService.getMe(token);
      setState(() {
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          String? photoUrl;
          if (response['photoUrl']?.toString().isNotEmpty == true) {
            photoUrl = response['photoUrl'];
          } else if (response['profile']?['photo']?['url'] != null) {
            photoUrl = ApiConstants.getFullImageUrl(response['profile']['photo']['url'].toString());
          }
          _currentUser!['photoUrl'] = photoUrl;
        } else { _currentUser = response; }
      });
    } catch (e) { debugPrint('Error loading user data: $e'); }
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() { _error = 'Please login again'; _isLoading = false; }); return; }
      final venuesData = await VenueService.getVenues(token);
      _venues = venuesData.map((v) => DashboardVenue.fromJson(v)).toList();
      if (_venues.isNotEmpty) await _loadAllCourts();
      setState(() => _isLoading = false);
    } catch (e) { setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  Future<void> _loadAllCourts() async {
    setState(() => _isLoadingCourts = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() => _isLoadingCourts = false); return; }
      final courtsData = await CourtService.getCourts(token);
      final List<DashboardCourt> loaded = [];
      for (var j in courtsData) {
        String? courtImgUrl;
        if (j['court_img_url'] != null) courtImgUrl = ApiConstants.getFullImageUrl(j['court_img_url'].toString());
        else if (j['court_img']?['url'] != null) courtImgUrl = ApiConstants.getFullImageUrl(j['court_img']['url'].toString());
        List<String> photosUrls = [];
        if (j['photos_urls'] is List) photosUrls = (j['photos_urls'] as List).map((u) => ApiConstants.getFullImageUrl(u.toString())).toList();
        else if (j['photos'] is List) photosUrls = (j['photos'] as List).where((p) => p?['url'] != null).map((p) => ApiConstants.getFullImageUrl(p['url'].toString())).toList();
        String? oldImageUrl;
        if (j['photo']?['url'] != null) oldImageUrl = ApiConstants.getFullImageUrl(j['photo']['url'].toString());
        final venueId = (j['venueId'] ?? j['venue_id'] ?? j['venue']?['id'] ?? '').toString();
        loaded.add(DashboardCourt(
          id: j['id'].toString(), name: j['name'] ?? '', location: j['location'] ?? '',
          venueId: venueId, sport: _parseSport(j['sport']),
          pricePerHour: (j['pricePerHour'] ?? 0).toDouble(),
          color: _parseSport(j['sport']).color,
          imageUrl: oldImageUrl, courtImgUrl: courtImgUrl, photosUrls: photosUrls,
          isActive: j['isActive'] ?? true,
        ));
      }
      _allCourts = loaded;
      _filterCourtsForVenue(_selectedVenueIndex);
    } catch (e) { debugPrint('Error loading courts: $e'); }
    setState(() => _isLoadingCourts = false);
  }

  void _filterCourtsForVenue(int venueIndex) {
    if (_venues.isEmpty) { _courts = []; return; }
    final venueId = _venues[venueIndex].id;
    _courts = _allCourts.where((c) => c.venueId == venueId).toList();
  }

  SportType _parseSport(String? s) {
    switch (s?.toLowerCase()) {
      case 'tennis':     return SportType.tennis;
      case 'padel':      return SportType.padel;
      case 'basketball': return SportType.basketball;
      default:           return SportType.football;
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() => _isLoadingBookings = false); return; }
      
      // ✅ FIX: Add populate for time_slot to get correct start/end times
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reservations?populate[court][populate][worker]=*&populate[court][populate][court_img]=*&populate[time_slot]=*'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200) { 
        print('Failed to load bookings: ${response.statusCode}');
        setState(() => _isLoadingBookings = false); 
        return; 
      }
      
      final responseData = json.decode(response.body);
      List<dynamic> reservations = responseData['data'] ?? (responseData is List ? responseData : []);
      final List<ManagerBooking> loaded = [];
      final today = DateTime.now();

      for (final res in reservations) {
        final attrs = res['attributes'] ?? res;

        // ✅ FIX: Get time_slot data FIRST (for correct start/end times)
        String startTime = '';
        String endTime = '';
        
        final timeSlotRel = attrs['time_slot'];
        if (timeSlotRel != null) {
          final timeSlotData = timeSlotRel['data'] ?? timeSlotRel;
          if (timeSlotData != null) {
            final timeSlotObj = timeSlotData is Map ? timeSlotData : null;
            if (timeSlotObj != null) {
              final timeSlotAttrs = timeSlotObj['attributes'] ?? timeSlotObj;
              startTime = timeSlotAttrs['startTime']?.toString() ?? '';
              endTime = timeSlotAttrs['endTime']?.toString() ?? '';
            }
          }
        }
        
        // Fallback to start_time/end_time from reservation if time_slot not available
        if (startTime.isEmpty) {
          startTime = attrs['start_time'] ?? '00:00';
        }
        if (endTime.isEmpty) {
          endTime = attrs['end_time'] ?? '01:00';
        }

        // player
        String playerName = 'Unknown Player', playerPhone = '';
        final playerRaw = attrs['player'];
        final playerData = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) : null;
        if (playerData is Map) {
          final pa = playerData['attributes'] ?? playerData;
          playerName  = pa['nom']?.toString() ?? pa['name']?.toString() ?? pa['username']?.toString() ?? 'Player';
          playerPhone = pa['phone']?.toString() ?? '';
          final userData = pa['player'];
          final ud = userData is Map ? (userData['data'] ?? userData) : null;
          if (ud is Map) {
            final ua = ud['attributes'] ?? ud;
            if (ua['username'] != null) playerName = ua['username'].toString();
          }
        }

        // court
        String courtName = '', courtId = '', courtImageUrl = '';
        String? workerName, workerId;
        SportType sport = SportType.football;
        final courtRaw = attrs['court'];
        final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) : null;
        if (courtData is Map) {
          final ca = courtData['attributes'] ?? courtData;
          courtId   = courtData['id']?.toString() ?? '';
          courtName = ca['name']?.toString() ?? '';
          sport     = _parseSport(ca['sport']?.toString());

          // worker
          final workerRaw = ca['worker'];
          final workerData = workerRaw is Map ? (workerRaw['data'] ?? workerRaw) : null;
          if (workerData is Map) {
            final wa = workerData['attributes'] ?? workerData;
            workerId   = workerData['id']?.toString();
            workerName = wa['nom']?.toString() ?? wa['name']?.toString() ?? 'Worker';
          }

          // court image
          final ciRaw = ca['court_img'];
          final ciData = ciRaw is Map ? (ciRaw['data'] ?? ciRaw) : null;
          if (ciData is Map) {
            final ia = ciData['attributes'] ?? ciData;
            final url = ia['url']?.toString() ?? '';
            if (url.isNotEmpty) courtImageUrl = _getFullImageUrl(url);
          }
          if (courtImageUrl.isEmpty) {
            final photosRaw = ca['photos'];
            final photosData = photosRaw is Map ? (photosRaw['data'] ?? photosRaw) : null;
            if (photosData is List && photosData.isNotEmpty) {
              final fp = photosData[0];
              final fpo = fp is Map ? (fp['data'] ?? fp) : null;
              if (fpo is Map) {
                final pa = fpo['attributes'] ?? fpo;
                final url = pa['url']?.toString() ?? '';
                if (url.isNotEmpty) courtImageUrl = _getFullImageUrl(url);
              }
            }
          }
          // Also check flat fields added by our venue.service.js
          if (courtImageUrl.isEmpty && ca['court_img_url'] != null) {
            courtImageUrl = _getFullImageUrl(ca['court_img_url'].toString());
          }
        }

        // date filter — today only
        final bookingDateStr = attrs['booking_date_play']?.toString();
        DateTime date = DateTime.now();
        if (bookingDateStr != null) {
          try { date = DateTime.parse(bookingDateStr); } catch (_) {}
        }
        if (date.year != today.year || date.month != today.month || date.day != today.day) continue;

        final durationHours = (attrs['duration_hours'] as num?)?.toDouble() ?? 1.0;
        final totalPrice    = (attrs['total_price']    as num?)?.toDouble() ?? 0.0;
        final paymentMethod = attrs['payment_method']?.toString() ?? 'pay_at_venue';
        final paymentOption = paymentMethod == 'pay_now' ? PaymentOption.payNow : PaymentOption.payAtVenue;
        final bookingStatus = attrs['booking_status']?.toString() ?? 'pending';
        final isPending     = paymentOption == PaymentOption.payAtVenue && bookingStatus == 'pending';
        final bookingRef    = attrs['booking_reference']?.toString() ?? '';

        final reservation = CourtReservation(
          id: res['id']?.toString() ?? '', courtId: courtId, courtName: courtName,
          hostId: '', sport: sport, date: date, startTime: startTime, endTime: endTime,
          durationHours: durationHours, totalPrice: totalPrice, paymentOption: paymentOption,
          courtImageUrl: courtImageUrl.isNotEmpty ? courtImageUrl : null,
        );
        loaded.add(ManagerBooking(
          id: res['id']?.toString() ?? '', reservation: reservation,
          playerName: playerName, playerPhone: playerPhone,
          bookingReference: bookingRef, isPending: isPending,
          bookingStatus: bookingStatus, workerName: workerName, workerId: workerId,
        ));
      }
      loaded.sort((a, b) => a.reservation.startTime.compareTo(b.reservation.startTime));
      setState(() { _bookings = loaded; _isLoadingBookings = false; });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      setState(() => _isLoadingBookings = false);
    }
  }

  // ── actions ───────────────────────────────────────────────────────────────
  void _onVenueChanged(int index) => setState(() { _selectedVenueIndex = index; _filterCourtsForVenue(index); });

  void _toggleCourt(String id) async {
    final court = _courts.firstWhere((c) => c.id == id);
    try {
      final token = await _getToken();
      if (token != null) {
        await CourtService.updateCourt(token: token, courtId: id, isActive: !court.isActive, photosIds: []);
        setState(() {
          for (final list in [_courts, _allCourts]) {
            final i = list.indexWhere((c) => c.id == id);
            if (i != -1) list[i].isActive = !list[i].isActive;
          }
        });
        _snack(court.isActive ? 'Court closed' : 'Court opened', kGreen);
      }
    } catch (e) { _snack('Failed to update court status', kRed); }
  }

  Future<void> _confirmBooking(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/confirm'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw Exception('Failed to confirm');
      setState(() {
        final i = _bookings.indexWhere((b) => b.id == id);
        if (i != -1) { _bookings[i].isPending = false; _bookings[i].bookingStatus = 'confirmed'; }
      });
      _snack('Booking confirmed ✓', kGreen);
    } catch (e) { _snack('Failed to confirm: $e', kRed); }
  }

  Future<void> _declineBooking(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/cancel'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw Exception('Failed to decline');
      setState(() => _bookings.removeWhere((b) => b.id == id));
      _snack('Booking declined', kRed);
    } catch (e) { _snack('Failed to decline: $e', kRed); }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
  ));

  void _openCourtSheet(DashboardCourt court) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _CourtManageSheet(court: court, onToggle: () { _toggleCourt(court.id); Navigator.pop(context); }),
  );

  void _openBookingSheet(ManagerBooking b) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _BookingDetailSheet(
      booking: b,
      onConfirm: b.isPending ? () { Navigator.pop(context); _confirmBooking(b.id); } : null,
      onDecline: b.isPending ? () { Navigator.pop(context); _declineBooking(b.id); } : null,
    ),
  );

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DashboardHeader(
            pendingCount: _pending, activeCourts: _active, totalCourts: _courts.length,
            managerName: _managerName, managerInitials: _managerInitials,
            currentUser: _currentUserData, venues: _venues,
            selectedVenueIndex: _selectedVenueIndex, onVenueChanged: _onVenueChanged,
            isLoading: _isLoading, onProfileUpdated: _onProfileUpdated,
          )),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, navH + 24),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // ── Courts ──────────────────────────────────────────────────
              _SectionTitle('My Courts', sub: '${_courts.length} courts'),
              const SizedBox(height: 14),
              if (_isLoadingCourts)
                const Center(child: CircularProgressIndicator(color: kPrimary))
              else if (_courts.isEmpty)
                _emptyBox('No courts yet. Add courts from the Venue page.')
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _CourtCard(court: _courts[i], onManage: () => _openCourtSheet(_courts[i])),
                  ),
                ),
              const SizedBox(height: 32),

              // ── Today's schedule ─────────────────────────────────────────
              _SectionTitle(
                "Today's Schedule",
                sub: '${_bookings.length} booking${_bookings.length == 1 ? '' : 's'} · $_pending pending',
                pendingBadge: _pending > 0 ? _pending : null,
                onRefresh: _loadBookings,
              ),
              const SizedBox(height: 14),
              if (_isLoadingBookings)
                const Center(child: CircularProgressIndicator(color: kPrimary))
              else if (_bookings.isEmpty)
                _emptyBox('No bookings today')
              else
                ..._bookings.map((b) => _BookingCard(
                  booking: b,
                  onTap: () => _openBookingSheet(b),
                  onConfirm: b.isPending ? () => _confirmBooking(b.id) : null,
                  onDecline: b.isPending ? () => _declineBooking(b.id) : null,
                )),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 36),
    alignment: Alignment.center,
    child: Text(text, style: const TextStyle(color: kTextMid, fontSize: 13)),
  );

  void _onProfileUpdated(Map<String, dynamic> u) {
    setState(() {
      if (_currentUser != null) {
        _currentUser!['username'] = u['username'];
        _currentUser!['email']    = u['email'];
        _currentUser!['phone']    = u['phone'];
        _currentUser!['photoUrl'] = u['photoUrl'];
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING CARD — matches bookings_page.dart exactly
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onConfirm, onDecline;
  const _BookingCard({required this.booking, required this.onTap, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b  = booking;
    final r  = b.reservation;
    final sc = r.sport.color;
    final hasWorker = b.workerName != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: b.isPending ? Border.all(color: kAmber.withOpacity(0.35), width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Court image with time overlay ────────────────────────────
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 68, height: 68,
                    child: r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                        ? Image.network(r.courtImageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: sc.withOpacity(0.12),
                              child: Icon(r.sport.icon, color: sc, size: 28),
                            ))
                        : Container(
                            color: sc.withOpacity(0.12),
                            child: Icon(r.sport.icon, color: sc, size: 28),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)]),
                    ),
                    child: Center(child: Text(r.startTime,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
              const SizedBox(width: 14),

              // ── Info column ──────────────────────────────────────────────
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Sport + worker chips
                Row(children: [
                  _Tag(r.sport.label, r.sport.icon, sc),
                  if (hasWorker) ...[
                    const SizedBox(width: 6),
                    _Tag('Worker', Icons.engineering_rounded, kAmber),
                  ],
                ]),
                const SizedBox(height: 5),
                Text(r.courtName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, size: 12, color: kTextLight),
                  const SizedBox(width: 4),
                  Expanded(child: Text(b.playerName,
                      style: const TextStyle(fontSize: 12, color: kTextMid), overflow: TextOverflow.ellipsis)),
                ]),
                if (hasWorker) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.engineering_rounded, size: 11, color: kAmber),
                    const SizedBox(width: 4),
                    Text('Worker: ${b.workerName}', style: const TextStyle(fontSize: 10, color: kAmber)),
                  ]),
                ],
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 11, color: kTextLight),
                  const SizedBox(width: 4),
                  Text('${r.startTime} – ${r.endTime} · ${r.durationHours}h',
                      style: const TextStyle(fontSize: 10, color: kTextLight)),
                ]),
              ])),

              // ── Status + price ───────────────────────────────────────────
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _StatusBadge(isPending: b.isPending, paymentOption: r.paymentOption),
                const SizedBox(height: 8),
                Text('${r.totalPrice.toInt()} DT',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)),
              ]),
            ]),
          ),

          // ── Pending action strip ─────────────────────────────────────────
          if (b.isPending) ...[
            Container(height: 1, color: const Color(0xFFF0F2F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(children: [
                // Call strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAmber.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.phone_rounded, size: 13, color: kAmber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      b.playerPhone.isNotEmpty
                          ? 'Call ${b.playerName.split(' ').first} to verify — ${b.playerPhone}'
                          : 'Call ${b.playerName.split(' ').first} to verify booking',
                      style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
                const SizedBox(height: 10),
                // Decline + Confirm
                Row(children: [
                  Expanded(child: _ActionBtn('Decline', kRed,   false, onDecline)),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn('Confirm', kGreen, true,  onConfirm)),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING DETAIL SHEET — matches bookings_page.dart
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailSheet extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback? onConfirm, onDecline;
  const _BookingDetailSheet({required this.booking, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b   = booking;
    final r   = b.reservation;
    final sc  = r.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    final hasWorker = b.workerName != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFC5C9D4), borderRadius: BorderRadius.circular(2))),
        )),

        // Court photo hero
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 185,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                    ? Image.network(r.courtImageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(sc, Colors.black, 0.4)!, sc]))))
                    : Container(decoration: BoxDecoration(gradient: LinearGradient(
                        colors: [Color.lerp(sc, Colors.black, 0.4)!, sc]))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.72)], stops: const [0.3, 1.0]))),

                // Sport pill
                Positioned(top: 12, left: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(r.sport.icon, size: 11, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(r.sport.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                )),

                // Worker badge
                if (hasWorker) Positioned(top: 12, right: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.engineering_rounded, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(b.workerName!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ]),
                )),

                // Court name + time
                Positioned(bottom: 14, left: 14, right: 14, child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.courtName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text('${r.startTime} – ${r.endTime} · ${r.durationHours}h',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ])),
                  Text('${r.totalPrice.toInt()} DT',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ])),
              ]),
            ),
          ),
        ),

        // Player card + actions
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bot + 20),
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEFF2)),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    // Avatar
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [sc, sc.withOpacity(0.6)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(
                        b.playerName.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.playerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 12, color: kTextLight),
                        const SizedBox(width: 4),
                        Text(b.playerPhone.isNotEmpty ? b.playerPhone : 'No phone number',
                            style: const TextStyle(fontSize: 12, color: kTextMid, fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.receipt_long_rounded, size: 12, color: kTextLight),
                        const SizedBox(width: 4),
                        Text('Ref: ${b.bookingReference}',
                            style: const TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w500)),
                      ]),
                      if (hasWorker) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.engineering_rounded, size: 11, color: kAmber),
                          const SizedBox(width: 4),
                          Text('Worker: ${b.workerName}',
                              style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ])),
                    if (b.playerPhone.isNotEmpty)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.phone_rounded, size: 18, color: kGreen),
                      ),
                  ]),
                ),
                // Payment banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.07),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(
                      color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.15))),
                  ),
                  child: Row(children: [
                    Icon(
                      r.paymentOption == PaymentOption.payNow ? Icons.bolt_rounded : Icons.storefront_rounded,
                      size: 14, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      r.paymentOption == PaymentOption.payNow
                          ? 'Paid online — confirmed automatically'
                          : 'Pay at venue — call player to confirm',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber,
                      ),
                    )),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (b.isPending)
              Row(children: [
                Expanded(child: _ActionBtn('Decline',         kRed,   false, onDecline)),
                const SizedBox(width: 12),
                Expanded(child: _ActionBtn('Confirm Booking', kGreen, true,  onConfirm)),
              ])
            else
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: kGreen),
                  SizedBox(width: 8),
                  Text('Booking Confirmed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen)),
                ])),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _Tag(this.label, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isPending; final PaymentOption paymentOption;
  const _StatusBadge({required this.isPending, required this.paymentOption});
  @override Widget build(BuildContext context) {
    final isOnline = paymentOption == PaymentOption.payNow;
    final color    = isPending ? kAmber : kGreen;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(isPending ? 'Pending' : 'Confirmed',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOnline ? Icons.bolt_rounded : Icons.storefront_rounded,
            size: 10, color: isOnline ? kGreen : kAmber),
        const SizedBox(width: 3),
        Text(isOnline ? 'Online' : 'At venue',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isOnline ? kGreen : kAmber)),
      ]),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final bool filled; final VoidCallback? onTap;
  const _ActionBtn(this.label, this.color, this.filled, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: filled
          ? BoxDecoration(
              gradient: LinearGradient(colors: color == kGreen ? [kGreen, const Color(0xFF15803D)] : [color, color]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            )
          : BoxDecoration(
              color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: filled ? Colors.white : color))),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final int pendingCount, activeCourts, totalCourts;
  final String managerName, managerInitials;
  final Map<String, dynamic>? currentUser;
  final List<DashboardVenue> venues;
  final int selectedVenueIndex;
  final ValueChanged<int> onVenueChanged;
  final bool isLoading;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const _DashboardHeader({
    required this.pendingCount, required this.activeCourts, required this.totalCourts,
    required this.managerName, required this.managerInitials, this.currentUser,
    required this.venues, required this.selectedVenueIndex, required this.onVenueChanged,
    required this.isLoading, this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerProfilePage(
              token: null,
              currentUser: currentUser ?? {'username': managerName, 'email': '', 'phone': ''},
              onProfileUpdated: (u) { if (onProfileUpdated != null) onProfileUpdated!(u); },
            ))),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF007B7D), Color(0xFF00A8AB)]),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5),
              ),
              child: currentUser?['photoUrl']?.toString().isNotEmpty == true
                  ? ClipOval(child: Image.network(currentUser!['photoUrl'], fit: BoxFit.cover, width: 46, height: 46,
                      errorBuilder: (_, __, ___) => Center(child: Text(managerInitials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)))))
                  : Center(child: Text(managerInitials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
            Text(managerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          ])),
          Stack(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            ),
            if (pendingCount > 0) Positioned(right: 8, top: 8, child: Container(
              width: 9, height: 9,
              decoration: BoxDecoration(color: kAmber, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF003D3E), width: 1.5)),
            )),
          ]),
        ]),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (venues.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.12))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.white70),
              SizedBox(width: 12),
              Expanded(child: Text('No venues yet. Add your first venue from the Venue page.', style: TextStyle(color: Colors.white70))),
            ]),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final v = venues[index];
                final isSel = selectedVenueIndex == index;
                return GestureDetector(
                  onTap: () => onVenueChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSel ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.12), width: isSel ? 1.8 : 1),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: isSel ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                          child: Icon(Icons.stadium_rounded, color: isSel ? Colors.white : Colors.white.withOpacity(0.7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(v.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isSel) Container(width: 7, height: 7, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withOpacity(0.55)),
                        const SizedBox(width: 3),
                        Expanded(child: Text(v.location, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      _VenueChip(v.isActive ? 'Open' : 'Closed', v.isActive ? kGreen.withOpacity(0.25) : kRed.withOpacity(0.25), v.isActive ? kGreen : kRed),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final int? pendingBadge;
  final VoidCallback? onRefresh;
  const _SectionTitle(this.title, {required this.sub, this.pendingBadge, this.onRefresh});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.4)),
        if (pendingBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(20)),
            child: Text('$pendingBadge pending', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ]),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(fontSize: 12, color: kTextMid)),
    ])),
    if (onRefresh != null)
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, size: 16, color: kPrimary),
        ),
      ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final DashboardCourt court;
  final VoidCallback onManage;
  const _CourtCard({required this.court, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final c = court; final sc = c.color; final imageUrl = c.displayImageUrl;
    return GestureDetector(
      onTap: onManage,
      child: Container(
        width: 180,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: kElevation),
        clipBehavior: Clip.hardEdge,
        child: Stack(fit: StackFit.expand, children: [
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: sc.withOpacity(0.12), child: Icon(c.sport.icon, color: sc, size: 40)))
              : Container(color: sc.withOpacity(0.12), child: Icon(c.sport.icon, color: sc, size: 40)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.78)], stops: const [0.3, 1.0]))),
          Positioned(top: 10, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(c.sport.icon, size: 9, color: Colors.white), const SizedBox(width: 3), Text(c.sport.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.isActive ? kGreen.withOpacity(0.85) : kRed.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 3), Text(c.isActive ? 'Open' : 'Closed', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))])),
          ])),
          Positioned(left: 12, right: 12, bottom: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${c.pricePerHour.toInt()} DT', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.25))),
                child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
            ]),
          ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT MANAGE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CourtManageSheet extends StatelessWidget {
  final DashboardCourt court; final VoidCallback onToggle;
  const _CourtManageSheet({required this.court, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = court; final sc = c.color; final bot = MediaQuery.of(context).padding.bottom; final imageUrl = c.displayImageUrl;
    return Container(
      decoration: const BoxDecoration(color: kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 30, offset: Offset(0, -6))]),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(children: [
            SizedBox(height: 180, width: double.infinity, child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: sc.withOpacity(0.1)))
                : Container(color: sc.withOpacity(0.1))),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.70)])))),
            Positioned(top: 12, left: 0, right: 0, child: Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2))))),
            Positioned(bottom: 16, left: 20, right: 20, child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(10)), child: Icon(c.sport.icon, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                Text('${c.pricePerHour.toInt()} DT · ${c.sport.label}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: c.isActive ? kGreen.withOpacity(0.85) : kRed.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                child: Text(c.isActive ? 'Open' : 'Closed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            Row(children: [
              _StatBox(Icons.calendar_today_rounded, '0',                       'Today', sc),
              const SizedBox(width: 10),
              _StatBox(Icons.sports_rounded,          c.sport.label,             'Sport', sc),
              const SizedBox(width: 10),
              _StatBox(Icons.attach_money_rounded,    '${c.pricePerHour.toInt()} DT', 'Price', sc),
            ]),
            const SizedBox(height: 20),
            _SheetBtn(icon: c.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded, label: c.isActive ? 'Close Court' : 'Open Court', color: c.isActive ? kRed : kGreen, filled: true, onTap: onToggle),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _VenueChip extends StatelessWidget {
  final String text; final Color bg, fg;
  const _VenueChip(this.text, this.bg, this.fg);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatBox(this.icon, this.value, this.label, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextMid)),
    ]),
  ));
}

class _SheetBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool filled; final VoidCallback onTap;
  const _SheetBtn({required this.icon, required this.label, required this.color, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: color.withOpacity(0.3)),
        boxShadow: filled ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: filled ? Colors.white : color),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
      ])),
    ),
  );
}






















/*// dashboard.dart — Views/Manager/dashboard.dart
// Manager home: uses CourtModel, CourtReservation
// Updated: Today's schedule now matches bookings_page.dart style fully
// — court image hero, sport/worker chips, pending call strip, confirm/decline

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/venue_service.dart';
import 'package:sporta/Services/court_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────
String _getFullImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${ApiConstants.mediaBaseUrl}$url';
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL MODELS
// ─────────────────────────────────────────────────────────────────────────────
class DashboardVenue {
  final String id, name, location, closeTime;
  final bool isActive;
  final List<String> sports, amenities;
  final String imageUrl;

  DashboardVenue({
    required this.id, required this.name, required this.location,
    required this.closeTime, required this.isActive,
    required this.sports, required this.amenities, required this.imageUrl,
  });

  factory DashboardVenue.fromJson(Map<String, dynamic> json) {
    List<String> sportsList = [];
    if (json['sports'] is List) sportsList = (json['sports'] as List).map((s) => s.toString()).toList();
    List<String> amenitiesList = [];
    if (json['amenities'] is List) amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    String imageUrl = '';
    if (json['photo']?['url'] != null) imageUrl = ApiConstants.getFullImageUrl(json['photo']['url'].toString());
    return DashboardVenue(
      id: json['id'].toString(), name: json['name'] ?? '',
      location: json['location'] ?? '', closeTime: json['closeTime'] ?? '23:00',
      isActive: json['isActive'] ?? true, sports: sportsList,
      amenities: amenitiesList, imageUrl: imageUrl,
    );
  }
}

class DashboardCourt {
  final String id, name, location, venueId;
  final SportType sport;
  final double pricePerHour;
  final Color color;
  final String? imageUrl, courtImgUrl;
  final List<String> photosUrls;
  bool isActive;

  DashboardCourt({
    required this.id, required this.name, required this.location,
    required this.venueId, required this.sport, required this.pricePerHour,
    required this.color, this.imageUrl, this.courtImgUrl,
    this.photosUrls = const [], required this.isActive,
  });

  String get displayImageUrl {
    if (courtImgUrl != null && courtImgUrl!.isNotEmpty) return courtImgUrl!;
    if (photosUrls.isNotEmpty) return photosUrls.first;
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    return '';
  }
}

class ManagerBooking {
  final String id;
  final CourtReservation reservation;
  final String playerName, playerPhone, bookingReference;
  bool isPending;
  String bookingStatus;
  final String? workerName, workerId;

  ManagerBooking({
    required this.id, required this.reservation,
    required this.playerName, required this.playerPhone,
    required this.bookingReference,
    this.isPending = true, this.bookingStatus = 'pending',
    this.workerName, this.workerId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  final String? managerToken;
  const Dashboard({super.key, this.managerToken});
  @override State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedVenueIndex = 0;
  List<DashboardVenue>  _venues   = [];
  List<DashboardCourt>  _allCourts = [];
  List<DashboardCourt>  _courts   = [];
  List<ManagerBooking>  _bookings = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true, _isLoadingCourts = false, _isLoadingBookings = false;
  String? _error;

  @override void initState() { super.initState(); _loadUserData(); _loadVenues(); _loadBookings(); }

  // ── getters ──────────────────────────────────────────────────────────────
  String get _managerName => _currentUser?['username']?.toString() ?? _currentUser?['name']?.toString() ?? 'Manager';
  String get _managerInitials {
    final n = _managerName;
    if (n.isEmpty || n == 'Manager') return 'M';
    final p = n.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : n[0].toUpperCase();
  }
  Map<String, dynamic>? get _currentUserData => _currentUser == null ? null : {
    'username': _currentUser!['username'] ?? _managerName,
    'email':    _currentUser!['email']    ?? '',
    'phone':    _currentUser!['phone']    ?? '',
    'photoUrl': _currentUser!['photoUrl'],
  };
  int get _pending => _bookings.where((b) => b.isPending).length;
  int get _active  => _courts.where((c) => c.isActive).length;

  // ── data loading ──────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    if (widget.managerToken?.isNotEmpty == true) return widget.managerToken;
    return const FlutterSecureStorage().read(key: 'jwt_token');
  }

  Future<void> _loadUserData() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await PlayerManagerAuthService.getMe(token);
      setState(() {
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          String? photoUrl;
          if (response['photoUrl']?.toString().isNotEmpty == true) {
            photoUrl = response['photoUrl'];
          } else if (response['profile']?['photo']?['url'] != null) {
            photoUrl = ApiConstants.getFullImageUrl(response['profile']['photo']['url'].toString());
          }
          _currentUser!['photoUrl'] = photoUrl;
        } else { _currentUser = response; }
      });
    } catch (e) { debugPrint('Error loading user data: $e'); }
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() { _error = 'Please login again'; _isLoading = false; }); return; }
      final venuesData = await VenueService.getVenues(token);
      _venues = venuesData.map((v) => DashboardVenue.fromJson(v)).toList();
      if (_venues.isNotEmpty) await _loadAllCourts();
      setState(() => _isLoading = false);
    } catch (e) { setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  Future<void> _loadAllCourts() async {
    setState(() => _isLoadingCourts = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() => _isLoadingCourts = false); return; }
      final courtsData = await CourtService.getCourts(token);
      final List<DashboardCourt> loaded = [];
      for (var j in courtsData) {
        String? courtImgUrl;
        if (j['court_img_url'] != null) courtImgUrl = ApiConstants.getFullImageUrl(j['court_img_url'].toString());
        else if (j['court_img']?['url'] != null) courtImgUrl = ApiConstants.getFullImageUrl(j['court_img']['url'].toString());
        List<String> photosUrls = [];
        if (j['photos_urls'] is List) photosUrls = (j['photos_urls'] as List).map((u) => ApiConstants.getFullImageUrl(u.toString())).toList();
        else if (j['photos'] is List) photosUrls = (j['photos'] as List).where((p) => p?['url'] != null).map((p) => ApiConstants.getFullImageUrl(p['url'].toString())).toList();
        String? oldImageUrl;
        if (j['photo']?['url'] != null) oldImageUrl = ApiConstants.getFullImageUrl(j['photo']['url'].toString());
        final venueId = (j['venueId'] ?? j['venue_id'] ?? j['venue']?['id'] ?? '').toString();
        loaded.add(DashboardCourt(
          id: j['id'].toString(), name: j['name'] ?? '', location: j['location'] ?? '',
          venueId: venueId, sport: _parseSport(j['sport']),
          pricePerHour: (j['pricePerHour'] ?? 0).toDouble(),
          color: _parseSport(j['sport']).color,
          imageUrl: oldImageUrl, courtImgUrl: courtImgUrl, photosUrls: photosUrls,
          isActive: j['isActive'] ?? true,
        ));
      }
      _allCourts = loaded;
      _filterCourtsForVenue(_selectedVenueIndex);
    } catch (e) { debugPrint('Error loading courts: $e'); }
    setState(() => _isLoadingCourts = false);
  }

  void _filterCourtsForVenue(int venueIndex) {
    if (_venues.isEmpty) { _courts = []; return; }
    final venueId = _venues[venueIndex].id;
    _courts = _allCourts.where((c) => c.venueId == venueId).toList();
  }

  SportType _parseSport(String? s) {
    switch (s?.toLowerCase()) {
      case 'tennis':     return SportType.tennis;
      case 'padel':      return SportType.padel;
      case 'basketball': return SportType.basketball;
      default:           return SportType.football;
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) { setState(() => _isLoadingBookings = false); return; }
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reservations'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) { setState(() => _isLoadingBookings = false); return; }
      final responseData = json.decode(response.body);
      List<dynamic> reservations = responseData['data'] ?? (responseData is List ? responseData : []);
      final List<ManagerBooking> loaded = [];
      final today = DateTime.now();

      for (final res in reservations) {
        final attrs = res['attributes'] ?? res;

        // player
        String playerName = 'Unknown Player', playerPhone = '';
        final playerRaw = attrs['player'];
        final playerData = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) : null;
        if (playerData is Map) {
          final pa = playerData['attributes'] ?? playerData;
          playerName  = pa['nom']?.toString() ?? pa['name']?.toString() ?? pa['username']?.toString() ?? 'Player';
          playerPhone = pa['phone']?.toString() ?? '';
          final userData = pa['player'];
          final ud = userData is Map ? (userData['data'] ?? userData) : null;
          if (ud is Map) {
            final ua = ud['attributes'] ?? ud;
            if (ua['username'] != null) playerName = ua['username'].toString();
          }
        }

        // court
        String courtName = '', courtId = '', courtImageUrl = '';
        String? workerName, workerId;
        SportType sport = SportType.football;
        final courtRaw = attrs['court'];
        final courtData = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) : null;
        if (courtData is Map) {
          final ca = courtData['attributes'] ?? courtData;
          courtId   = courtData['id']?.toString() ?? '';
          courtName = ca['name']?.toString() ?? '';
          sport     = _parseSport(ca['sport']?.toString());

          // worker
          final workerRaw = ca['worker'];
          final workerData = workerRaw is Map ? (workerRaw['data'] ?? workerRaw) : null;
          if (workerData is Map) {
            final wa = workerData['attributes'] ?? workerData;
            workerId   = workerData['id']?.toString();
            workerName = wa['nom']?.toString() ?? wa['name']?.toString() ?? 'Worker';
          }

          // court image
          final ciRaw = ca['court_img'];
          final ciData = ciRaw is Map ? (ciRaw['data'] ?? ciRaw) : null;
          if (ciData is Map) {
            final ia = ciData['attributes'] ?? ciData;
            final url = ia['url']?.toString() ?? '';
            if (url.isNotEmpty) courtImageUrl = _getFullImageUrl(url);
          }
          if (courtImageUrl.isEmpty) {
            final photosRaw = ca['photos'];
            final photosData = photosRaw is Map ? (photosRaw['data'] ?? photosRaw) : null;
            if (photosData is List && photosData.isNotEmpty) {
              final fp = photosData[0];
              final fpo = fp is Map ? (fp['data'] ?? fp) : null;
              if (fpo is Map) {
                final pa = fpo['attributes'] ?? fpo;
                final url = pa['url']?.toString() ?? '';
                if (url.isNotEmpty) courtImageUrl = _getFullImageUrl(url);
              }
            }
          }
          // Also check flat fields added by our venue.service.js
          if (courtImageUrl.isEmpty && ca['court_img_url'] != null) {
            courtImageUrl = _getFullImageUrl(ca['court_img_url'].toString());
          }
        }

        // date filter — today only
        final bookingDateStr = attrs['booking_date_play']?.toString();
        DateTime date = DateTime.now();
        if (bookingDateStr != null) {
          try { date = DateTime.parse(bookingDateStr); } catch (_) {}
        }
        if (date.year != today.year || date.month != today.month || date.day != today.day) continue;

        final startTime     = attrs['start_time']?.toString()  ?? '00:00';
        final endTime       = attrs['end_time']?.toString()    ?? '01:00';
        final durationHours = (attrs['duration_hours'] as num?)?.toDouble() ?? 1.0;
        final totalPrice    = (attrs['total_price']    as num?)?.toDouble() ?? 0.0;
        final paymentMethod = attrs['payment_method']?.toString() ?? 'pay_at_venue';
        final paymentOption = paymentMethod == 'pay_now' ? PaymentOption.payNow : PaymentOption.payAtVenue;
        final bookingStatus = attrs['booking_status']?.toString() ?? 'pending';
        final isPending     = paymentOption == PaymentOption.payAtVenue && bookingStatus == 'pending';
        final bookingRef    = attrs['booking_reference']?.toString() ?? '';

        final reservation = CourtReservation(
          id: res['id']?.toString() ?? '', courtId: courtId, courtName: courtName,
          hostId: '', sport: sport, date: date, startTime: startTime, endTime: endTime,
          durationHours: durationHours, totalPrice: totalPrice, paymentOption: paymentOption,
          courtImageUrl: courtImageUrl.isNotEmpty ? courtImageUrl : null,
        );
        loaded.add(ManagerBooking(
          id: res['id']?.toString() ?? '', reservation: reservation,
          playerName: playerName, playerPhone: playerPhone,
          bookingReference: bookingRef, isPending: isPending,
          bookingStatus: bookingStatus, workerName: workerName, workerId: workerId,
        ));
      }
      loaded.sort((a, b) => a.reservation.startTime.compareTo(b.reservation.startTime));
      setState(() { _bookings = loaded; _isLoadingBookings = false; });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      setState(() => _isLoadingBookings = false);
    }
  }

  // ── actions ───────────────────────────────────────────────────────────────
  void _onVenueChanged(int index) => setState(() { _selectedVenueIndex = index; _filterCourtsForVenue(index); });

  void _toggleCourt(String id) async {
    final court = _courts.firstWhere((c) => c.id == id);
    try {
      final token = await _getToken();
      if (token != null) {
        await CourtService.updateCourt(token: token, courtId: id, isActive: !court.isActive, photosIds: []);
        setState(() {
          for (final list in [_courts, _allCourts]) {
            final i = list.indexWhere((c) => c.id == id);
            if (i != -1) list[i].isActive = !list[i].isActive;
          }
        });
        _snack(court.isActive ? 'Court closed' : 'Court opened', kGreen);
      }
    } catch (e) { _snack('Failed to update court status', kRed); }
  }

  Future<void> _confirmBooking(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/confirm'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw Exception('Failed to confirm');
      setState(() {
        final i = _bookings.indexWhere((b) => b.id == id);
        if (i != -1) { _bookings[i].isPending = false; _bookings[i].bookingStatus = 'confirmed'; }
      });
      _snack('Booking confirmed ✓', kGreen);
    } catch (e) { _snack('Failed to confirm: $e', kRed); }
  }

  Future<void> _declineBooking(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/cancel'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw Exception('Failed to decline');
      setState(() => _bookings.removeWhere((b) => b.id == id));
      _snack('Booking declined', kRed);
    } catch (e) { _snack('Failed to decline: $e', kRed); }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
  ));

  void _openCourtSheet(DashboardCourt court) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _CourtManageSheet(court: court, onToggle: () { _toggleCourt(court.id); Navigator.pop(context); }),
  );

  void _openBookingSheet(ManagerBooking b) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _BookingDetailSheet(
      booking: b,
      onConfirm: b.isPending ? () { Navigator.pop(context); _confirmBooking(b.id); } : null,
      onDecline: b.isPending ? () { Navigator.pop(context); _declineBooking(b.id); } : null,
    ),
  );

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DashboardHeader(
            pendingCount: _pending, activeCourts: _active, totalCourts: _courts.length,
            managerName: _managerName, managerInitials: _managerInitials,
            currentUser: _currentUserData, venues: _venues,
            selectedVenueIndex: _selectedVenueIndex, onVenueChanged: _onVenueChanged,
            isLoading: _isLoading, onProfileUpdated: _onProfileUpdated,
          )),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, navH + 24),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // ── Courts ──────────────────────────────────────────────────
              _SectionTitle('My Courts', sub: '${_courts.length} courts'),
              const SizedBox(height: 14),
              if (_isLoadingCourts)
                const Center(child: CircularProgressIndicator(color: kPrimary))
              else if (_courts.isEmpty)
                _emptyBox('No courts yet. Add courts from the Venue page.')
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _CourtCard(court: _courts[i], onManage: () => _openCourtSheet(_courts[i])),
                  ),
                ),
              const SizedBox(height: 32),

              // ── Today's schedule ─────────────────────────────────────────
              _SectionTitle(
                "Today's Schedule",
                sub: '${_bookings.length} booking${_bookings.length == 1 ? '' : 's'} · $_pending pending',
                pendingBadge: _pending > 0 ? _pending : null,
                onRefresh: _loadBookings,
              ),
              const SizedBox(height: 14),
              if (_isLoadingBookings)
                const Center(child: CircularProgressIndicator(color: kPrimary))
              else if (_bookings.isEmpty)
                _emptyBox('No bookings today')
              else
                ..._bookings.map((b) => _BookingCard(
                  booking: b,
                  onTap: () => _openBookingSheet(b),
                  onConfirm: b.isPending ? () => _confirmBooking(b.id) : null,
                  onDecline: b.isPending ? () => _declineBooking(b.id) : null,
                )),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 36),
    alignment: Alignment.center,
    child: Text(text, style: const TextStyle(color: kTextMid, fontSize: 13)),
  );

  void _onProfileUpdated(Map<String, dynamic> u) {
    setState(() {
      if (_currentUser != null) {
        _currentUser!['username'] = u['username'];
        _currentUser!['email']    = u['email'];
        _currentUser!['phone']    = u['phone'];
        _currentUser!['photoUrl'] = u['photoUrl'];
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING CARD — matches bookings_page.dart exactly
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onConfirm, onDecline;
  const _BookingCard({required this.booking, required this.onTap, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b  = booking;
    final r  = b.reservation;
    final sc = r.sport.color;
    final hasWorker = b.workerName != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: b.isPending ? Border.all(color: kAmber.withOpacity(0.35), width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Court image with time overlay ────────────────────────────
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 68, height: 68,
                    child: r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                        ? Image.network(r.courtImageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: sc.withOpacity(0.12),
                              child: Icon(r.sport.icon, color: sc, size: 28),
                            ))
                        : Container(
                            color: sc.withOpacity(0.12),
                            child: Icon(r.sport.icon, color: sc, size: 28),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)]),
                    ),
                    child: Center(child: Text(r.startTime,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
              const SizedBox(width: 14),

              // ── Info column ──────────────────────────────────────────────
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Sport + worker chips
                Row(children: [
                  _Tag(r.sport.label, r.sport.icon, sc),
                  if (hasWorker) ...[
                    const SizedBox(width: 6),
                    _Tag('Worker', Icons.engineering_rounded, kAmber),
                  ],
                ]),
                const SizedBox(height: 5),
                Text(r.courtName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, size: 12, color: kTextLight),
                  const SizedBox(width: 4),
                  Expanded(child: Text(b.playerName,
                      style: const TextStyle(fontSize: 12, color: kTextMid), overflow: TextOverflow.ellipsis)),
                ]),
                if (hasWorker) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.engineering_rounded, size: 11, color: kAmber),
                    const SizedBox(width: 4),
                    Text('Worker: ${b.workerName}', style: const TextStyle(fontSize: 10, color: kAmber)),
                  ]),
                ],
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 11, color: kTextLight),
                  const SizedBox(width: 4),
                  Text('${r.startTime} – ${r.endTime} · ${r.durationHours}h',
                      style: const TextStyle(fontSize: 10, color: kTextLight)),
                ]),
              ])),

              // ── Status + price ───────────────────────────────────────────
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _StatusBadge(isPending: b.isPending, paymentOption: r.paymentOption),
                const SizedBox(height: 8),
                Text('${r.totalPrice.toInt()} DT',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)),
              ]),
            ]),
          ),

          // ── Pending action strip ─────────────────────────────────────────
          if (b.isPending) ...[
            Container(height: 1, color: const Color(0xFFF0F2F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(children: [
                // Call strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAmber.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.phone_rounded, size: 13, color: kAmber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      b.playerPhone.isNotEmpty
                          ? 'Call ${b.playerName.split(' ').first} to verify — ${b.playerPhone}'
                          : 'Call ${b.playerName.split(' ').first} to verify booking',
                      style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
                const SizedBox(height: 10),
                // Decline + Confirm
                Row(children: [
                  Expanded(child: _ActionBtn('Decline', kRed,   false, onDecline)),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn('Confirm', kGreen, true,  onConfirm)),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING DETAIL SHEET — matches bookings_page.dart
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailSheet extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback? onConfirm, onDecline;
  const _BookingDetailSheet({required this.booking, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b   = booking;
    final r   = b.reservation;
    final sc  = r.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    final hasWorker = b.workerName != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFC5C9D4), borderRadius: BorderRadius.circular(2))),
        )),

        // Court photo hero
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 185,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                    ? Image.network(r.courtImageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(sc, Colors.black, 0.4)!, sc]))))
                    : Container(decoration: BoxDecoration(gradient: LinearGradient(
                        colors: [Color.lerp(sc, Colors.black, 0.4)!, sc]))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.72)], stops: const [0.3, 1.0]))),

                // Sport pill
                Positioned(top: 12, left: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(r.sport.icon, size: 11, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(r.sport.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                )),

                // Worker badge
                if (hasWorker) Positioned(top: 12, right: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.engineering_rounded, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(b.workerName!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ]),
                )),

                // Court name + time
                Positioned(bottom: 14, left: 14, right: 14, child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.courtName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text('${r.startTime} – ${r.endTime} · ${r.durationHours}h',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ])),
                  Text('${r.totalPrice.toInt()} DT',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ])),
              ]),
            ),
          ),
        ),

        // Player card + actions
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bot + 20),
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEFF2)),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    // Avatar
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [sc, sc.withOpacity(0.6)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(
                        b.playerName.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.playerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 12, color: kTextLight),
                        const SizedBox(width: 4),
                        Text(b.playerPhone.isNotEmpty ? b.playerPhone : 'No phone number',
                            style: const TextStyle(fontSize: 12, color: kTextMid, fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.receipt_long_rounded, size: 12, color: kTextLight),
                        const SizedBox(width: 4),
                        Text('Ref: ${b.bookingReference}',
                            style: const TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w500)),
                      ]),
                      if (hasWorker) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.engineering_rounded, size: 11, color: kAmber),
                          const SizedBox(width: 4),
                          Text('Worker: ${b.workerName}',
                              style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ])),
                    if (b.playerPhone.isNotEmpty)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.phone_rounded, size: 18, color: kGreen),
                      ),
                  ]),
                ),
                // Payment banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.07),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(
                      color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.15))),
                  ),
                  child: Row(children: [
                    Icon(
                      r.paymentOption == PaymentOption.payNow ? Icons.bolt_rounded : Icons.storefront_rounded,
                      size: 14, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      r.paymentOption == PaymentOption.payNow
                          ? 'Paid online — confirmed automatically'
                          : 'Pay at venue — call player to confirm',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber,
                      ),
                    )),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (b.isPending)
              Row(children: [
                Expanded(child: _ActionBtn('Decline',         kRed,   false, onDecline)),
                const SizedBox(width: 12),
                Expanded(child: _ActionBtn('Confirm Booking', kGreen, true,  onConfirm)),
              ])
            else
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: kGreen),
                  SizedBox(width: 8),
                  Text('Booking Confirmed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen)),
                ])),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _Tag(this.label, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool isPending; final PaymentOption paymentOption;
  const _StatusBadge({required this.isPending, required this.paymentOption});
  @override Widget build(BuildContext context) {
    final isOnline = paymentOption == PaymentOption.payNow;
    final color    = isPending ? kAmber : kGreen;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(isPending ? 'Pending' : 'Confirmed',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOnline ? Icons.bolt_rounded : Icons.storefront_rounded,
            size: 10, color: isOnline ? kGreen : kAmber),
        const SizedBox(width: 3),
        Text(isOnline ? 'Online' : 'At venue',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isOnline ? kGreen : kAmber)),
      ]),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final bool filled; final VoidCallback? onTap;
  const _ActionBtn(this.label, this.color, this.filled, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: filled
          ? BoxDecoration(
              gradient: LinearGradient(colors: color == kGreen ? [kGreen, const Color(0xFF15803D)] : [color, color]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            )
          : BoxDecoration(
              color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: filled ? Colors.white : color))),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final int pendingCount, activeCourts, totalCourts;
  final String managerName, managerInitials;
  final Map<String, dynamic>? currentUser;
  final List<DashboardVenue> venues;
  final int selectedVenueIndex;
  final ValueChanged<int> onVenueChanged;
  final bool isLoading;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const _DashboardHeader({
    required this.pendingCount, required this.activeCourts, required this.totalCourts,
    required this.managerName, required this.managerInitials, this.currentUser,
    required this.venues, required this.selectedVenueIndex, required this.onVenueChanged,
    required this.isLoading, this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerProfilePage(
              token: null,
              currentUser: currentUser ?? {'username': managerName, 'email': '', 'phone': ''},
              onProfileUpdated: (u) { if (onProfileUpdated != null) onProfileUpdated!(u); },
            ))),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF007B7D), Color(0xFF00A8AB)]),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5),
              ),
              child: currentUser?['photoUrl']?.toString().isNotEmpty == true
                  ? ClipOval(child: Image.network(currentUser!['photoUrl'], fit: BoxFit.cover, width: 46, height: 46,
                      errorBuilder: (_, __, ___) => Center(child: Text(managerInitials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)))))
                  : Center(child: Text(managerInitials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
            Text(managerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
          ])),
          Stack(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            ),
            if (pendingCount > 0) Positioned(right: 8, top: 8, child: Container(
              width: 9, height: 9,
              decoration: BoxDecoration(color: kAmber, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF003D3E), width: 1.5)),
            )),
          ]),
        ]),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (venues.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.12))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.white70),
              SizedBox(width: 12),
              Expanded(child: Text('No venues yet. Add your first venue from the Venue page.', style: TextStyle(color: Colors.white70))),
            ]),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final v = venues[index];
                final isSel = selectedVenueIndex == index;
                return GestureDetector(
                  onTap: () => onVenueChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSel ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.12), width: isSel ? 1.8 : 1),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: isSel ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                          child: Icon(Icons.stadium_rounded, color: isSel ? Colors.white : Colors.white.withOpacity(0.7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(v.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isSel) Container(width: 7, height: 7, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withOpacity(0.55)),
                        const SizedBox(width: 3),
                        Expanded(child: Text(v.location, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      _VenueChip(v.isActive ? 'Open' : 'Closed', v.isActive ? kGreen.withOpacity(0.25) : kRed.withOpacity(0.25), v.isActive ? kGreen : kRed),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final int? pendingBadge;
  final VoidCallback? onRefresh;
  const _SectionTitle(this.title, {required this.sub, this.pendingBadge, this.onRefresh});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.4)),
        if (pendingBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(20)),
            child: Text('$pendingBadge pending', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ]),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(fontSize: 12, color: kTextMid)),
    ])),
    if (onRefresh != null)
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, size: 16, color: kPrimary),
        ),
      ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final DashboardCourt court;
  final VoidCallback onManage;
  const _CourtCard({required this.court, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final c = court; final sc = c.color; final imageUrl = c.displayImageUrl;
    return GestureDetector(
      onTap: onManage,
      child: Container(
        width: 180,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: kElevation),
        clipBehavior: Clip.hardEdge,
        child: Stack(fit: StackFit.expand, children: [
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: sc.withOpacity(0.12), child: Icon(c.sport.icon, color: sc, size: 40)))
              : Container(color: sc.withOpacity(0.12), child: Icon(c.sport.icon, color: sc, size: 40)),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.78)], stops: const [0.3, 1.0]))),
          Positioned(top: 10, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(c.sport.icon, size: 9, color: Colors.white), const SizedBox(width: 3), Text(c.sport.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.isActive ? kGreen.withOpacity(0.85) : kRed.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 3), Text(c.isActive ? 'Open' : 'Closed', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))])),
          ])),
          Positioned(left: 12, right: 12, bottom: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${c.pricePerHour.toInt()} DT', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.25))),
                child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
            ]),
          ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT MANAGE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CourtManageSheet extends StatelessWidget {
  final DashboardCourt court; final VoidCallback onToggle;
  const _CourtManageSheet({required this.court, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = court; final sc = c.color; final bot = MediaQuery.of(context).padding.bottom; final imageUrl = c.displayImageUrl;
    return Container(
      decoration: const BoxDecoration(color: kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 30, offset: Offset(0, -6))]),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(children: [
            SizedBox(height: 180, width: double.infinity, child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: sc.withOpacity(0.1)))
                : Container(color: sc.withOpacity(0.1))),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.70)])))),
            Positioned(top: 12, left: 0, right: 0, child: Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2))))),
            Positioned(bottom: 16, left: 20, right: 20, child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(10)), child: Icon(c.sport.icon, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                Text('${c.pricePerHour.toInt()} DT · ${c.sport.label}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: c.isActive ? kGreen.withOpacity(0.85) : kRed.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                child: Text(c.isActive ? 'Open' : 'Closed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            Row(children: [
              _StatBox(Icons.calendar_today_rounded, '0',                       'Today', sc),
              const SizedBox(width: 10),
              _StatBox(Icons.sports_rounded,          c.sport.label,             'Sport', sc),
              const SizedBox(width: 10),
              _StatBox(Icons.attach_money_rounded,    '${c.pricePerHour.toInt()} DT', 'Price', sc),
            ]),
            const SizedBox(height: 20),
            _SheetBtn(icon: c.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded, label: c.isActive ? 'Close Court' : 'Open Court', color: c.isActive ? kRed : kGreen, filled: true, onTap: onToggle),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _VenueChip extends StatelessWidget {
  final String text; final Color bg, fg;
  const _VenueChip(this.text, this.bg, this.fg);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatBox(this.icon, this.value, this.label, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextMid)),
    ]),
  ));
}

class _SheetBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool filled; final VoidCallback onTap;
  const _SheetBtn({required this.icon, required this.label, required this.color, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: color.withOpacity(0.3)),
        boxShadow: filled ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: filled ? Colors.white : color),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
      ])),
    ),
  );
}



****************************************************************************




// dashboard.dart — Views/Manager/dashboard.dart
// Manager home: uses CourtModel, CourtReservation
// Completely self-contained with its own models like venue_page.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Views/Player/matches_page.dart' show TournamentModel;
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/venue_service.dart';
import 'package:sporta/Services/court_service.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'manager_profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL MODELS (same pattern as venue_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

/// Local Venue model for dashboard (similar to ManagedVenue in venue_page.dart)
class DashboardVenue {
  final String id;
  final String name;
  final String location;
  final String closeTime;
  final bool isActive;
  final List<String> sports;
  final List<String> amenities;
  final String imageUrl;

  DashboardVenue({
    required this.id,
    required this.name,
    required this.location,
    required this.closeTime,
    required this.isActive,
    required this.sports,
    required this.amenities,
    required this.imageUrl,
  });

  // Factory constructor to create from backend JSON (same as ManagedVenue)
  factory DashboardVenue.fromJson(Map<String, dynamic> json) {
    // Parse sports
    List<String> sportsList = [];
    if (json['sports'] != null && json['sports'] is List) {
      sportsList = (json['sports'] as List).map((s) => s.toString()).toList();
    }

    // Parse amenities
    List<String> amenitiesList = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      amenitiesList = (json['amenities'] as List).map((a) => a.toString()).toList();
    }

    // Parse photos - get first photo URL
    String imageUrl = '';
    if (json['photo'] != null && json['photo']['url'] != null) {
      imageUrl = '${ApiConstants.mediaBaseUrl}${json['photo']['url']}';
    }

    return DashboardVenue(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      closeTime: json['closeTime'] ?? '23:00',
      isActive: json['isActive'] ?? true,
      sports: sportsList,
      amenities: amenitiesList,
      imageUrl: imageUrl,
    );
  }
}

/// Local Court model for dashboard (similar to ManagedCourt in venue_page.dart)
class DashboardCourt {
  final String id;
  final String name;
  final String location;
  final String venueId;
  final SportType sport;
  final double pricePerHour;
  final Color color;
  final String? imageUrl;
  final String? courtImgUrl; // NEW: main court image
  final List<String> photosUrls; // NEW: gallery images
  bool isActive;

  DashboardCourt({
    required this.id,
    required this.name,
    required this.location,
    required this.venueId,
    required this.sport,
    required this.pricePerHour,
    required this.color,
    this.imageUrl,
    this.courtImgUrl,
    this.photosUrls = const [],
    required this.isActive,
  });
  
  // Helper to get the best image URL (court_img first, then photos, then imageUrl)
  String get displayImageUrl {
    if (courtImgUrl != null && courtImgUrl!.isNotEmpty) {
      return courtImgUrl!;
    }
    if (photosUrls.isNotEmpty) {
      return photosUrls.first;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return '';
  }
}

/// Wraps CourtReservation + manager-only fields (playerName, isPending)
class ManagerBooking {
  final String id;
  final CourtReservation reservation;
  final String playerName;
  final String playerPhone;
  bool isPending;
  ManagerBooking({
    required this.id,
    required this.reservation,
    required this.playerName,
    required this.playerPhone,
    this.isPending = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  final String? managerToken;
  const Dashboard({super.key, this.managerToken});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedVenueIndex = 0;
  List<DashboardVenue> _venues = [];
  List<DashboardCourt> _allCourts = [];
  List<DashboardCourt> _courts = [];
  List<ManagerBooking> _bookings = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  bool _isLoadingCourts = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVenues();
    _loadBookings();
  }

  // ── Derive display name & initials from _currentUser ──────────────────────
  String get _managerName {
    if (_currentUser == null) return 'Manager';
    return _currentUser!['username']?.toString() ??
        _currentUser!['name']?.toString() ??
        _currentUser!['firstName']?.toString() ??
        'Manager';
  }

  String get _managerInitials {
    final name = _managerName;
    if (name.isEmpty || name == 'Manager') return 'M';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Map<String, dynamic>? get _currentUserData {
    if (_currentUser == null) return null;
    return {
      'username': _currentUser!['username'] ?? _managerName,
      'email': _currentUser!['email'] ?? '',
      'phone': _currentUser!['phone'] ?? '',
      'photoUrl': _currentUser!['photoUrl'],
    };
  }

  Future<void> _loadUserData() async {
    try {
      final token = widget.managerToken ?? await _getToken();
      if (token == null) return;
      final response = await PlayerManagerAuthService.getMe(token);
      
      setState(() {
        if (response.containsKey('user')) {
          _currentUser = response['user'] as Map<String, dynamic>;
          
          // Get photoUrl from response
          String? photoUrl;
          if (response['photoUrl'] != null && response['photoUrl'].toString().isNotEmpty) {
            photoUrl = response['photoUrl'];
          } else if (response['profile'] != null) {
            final profile = response['profile'] as Map<String, dynamic>;
            if (profile['photo'] != null) {
              final photo = profile['photo'] as Map<String, dynamic>;
              if (photo['url'] != null) {
                photoUrl = ApiConstants.getFullImageUrl(photo['url'].toString());
              }
            }
          }
          
          _currentUser!['photoUrl'] = photoUrl;
        } else {
          _currentUser = response;
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<String?> _getToken() async {
    if (widget.managerToken != null && widget.managerToken!.isNotEmpty) {
      return widget.managerToken;
    }
    const storage = FlutterSecureStorage();
    return storage.read(key: 'jwt_token');
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Please login again';
          _isLoading = false;
        });
        return;
      }

      print('===== DEBUG: Starting to load venues =====');
      final venuesData = await VenueService.getVenues(token);
      print('Venues loaded count: ${venuesData.length}');

      final List<DashboardVenue> loadedVenues =
          venuesData.map((v) => DashboardVenue.fromJson(v)).toList();

      print('Loaded ${loadedVenues.length} venues');

      if (loadedVenues.isNotEmpty) {
        _venues = loadedVenues;
        await _loadAllCourts();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading venues: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load ALL courts from backend once, then filter client-side by venueId.
  Future<void> _loadAllCourts() async {
    setState(() => _isLoadingCourts = true);
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() => _isLoadingCourts = false);
        return;
      }

      print('===== DEBUG: Loading all courts =====');
      final courtsData = await CourtService.getCourts(token);
      print('Total courts from backend: ${courtsData.length}');

      final List<DashboardCourt> loaded = [];
      for (var courtJson in courtsData) {
        // Get court_img URL (main image)
        String? courtImgUrl;
        if (courtJson['court_img_url'] != null) {
          courtImgUrl = ApiConstants.getFullImageUrl(courtJson['court_img_url'].toString());
        } else if (courtJson['court_img'] != null && courtJson['court_img']['url'] != null) {
          courtImgUrl = ApiConstants.getFullImageUrl(courtJson['court_img']['url'].toString());
        }
        
        // Get photos URLs (gallery images)
        List<String> photosUrls = [];
        if (courtJson['photos_urls'] != null && courtJson['photos_urls'] is List) {
          photosUrls = (courtJson['photos_urls'] as List)
              .map((url) => ApiConstants.getFullImageUrl(url.toString()))
              .toList();
        } else if (courtJson['photos'] != null && courtJson['photos'] is List) {
          photosUrls = (courtJson['photos'] as List)
              .where((p) => p != null && p['url'] != null)
              .map((p) => ApiConstants.getFullImageUrl(p['url'].toString()))
              .toList();
        }

        // Fallback to old photo field if exists
        String? oldImageUrl;
        if (courtJson['photo'] != null && courtJson['photo']['url'] != null) {
          oldImageUrl = ApiConstants.getFullImageUrl(courtJson['photo']['url'].toString());
        }

        // Extract venueId
        final venueId = (courtJson['venueId'] ??
                courtJson['venue_id'] ??
                courtJson['venue']?['id'] ??
                '')
            .toString();

        loaded.add(DashboardCourt(
          id: courtJson['id'].toString(),
          name: courtJson['name'] ?? '',
          location: courtJson['location'] ?? '',
          venueId: venueId,
          sport: _parseSportType(courtJson['sport']),
          pricePerHour: (courtJson['pricePerHour'] ?? 0).toDouble(),
          color: _parseSportType(courtJson['sport']).color,
          imageUrl: oldImageUrl,
          courtImgUrl: courtImgUrl,
          photosUrls: photosUrls,
          isActive: courtJson['isActive'] ?? true,
        ));
      }

      _allCourts = loaded;
      _filterCourtsForVenue(_selectedVenueIndex);
      print('Loaded ${loaded.length} total courts');
    } catch (e, stackTrace) {
      print('Error loading courts: $e');
      print('Stack trace: $stackTrace');
    }
    setState(() => _isLoadingCourts = false);
  }

  /// Filter _allCourts to only those belonging to the selected venue.
  void _filterCourtsForVenue(int venueIndex) {
    if (_venues.isEmpty) {
      _courts = [];
      return;
    }
    final venueId = _venues[venueIndex].id;
    _courts = _allCourts.where((c) => c.venueId == venueId).toList();
    print('Filtered courts for venue "$venueId": ${_courts.length} courts');
  }

  SportType _parseSportType(String? sport) {
    if (sport == null) return SportType.football;
    switch (sport.toLowerCase()) {
      case 'football':
        return SportType.football;
      case 'tennis':
        return SportType.tennis;
      case 'padel':
        return SportType.padel;
      case 'basketball':
        return SportType.basketball;
      default:
        return SportType.football;
    }
  }

  Future<void> _loadBookings() async {
    // Sample booking data - replace with actual API call
    _bookings = [
      ManagerBooking(
        id: 'b1',
        playerName: 'Karim Jaziri',
        playerPhone: '+216 54 123 456',
        isPending: false,
        reservation: CourtReservation(
          id: 'r1',
          courtId: 'c1',
          courtName: 'Court Alpha',
          hostId: 'p1',
          sport: SportType.football,
          date: DateTime.now(),
          startTime: '08:00',
          endTime: '09:00',
          durationHours: 1,
          totalPrice: 90,
          paymentOption: PaymentOption.payNow,
          courtImageUrl:
              'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
        ),
      ),
      ManagerBooking(
        id: 'b2',
        playerName: 'Nadia Ben Salah',
        playerPhone: '+216 52 234 567',
        isPending: true,
        reservation: CourtReservation(
          id: 'r2',
          courtId: 'c2',
          courtName: 'Court Beta',
          hostId: 'p2',
          sport: SportType.padel,
          date: DateTime.now(),
          startTime: '09:30',
          endTime: '11:00',
          durationHours: 1.5,
          totalPrice: 120,
          paymentOption: PaymentOption.payAtVenue,
          courtImageUrl:
              'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=300&q=80',
        ),
      ),
      ManagerBooking(
        id: 'b3',
        playerName: 'Mehdi Trabelsi',
        playerPhone: '+216 55 345 678',
        isPending: false,
        reservation: CourtReservation(
          id: 'r3',
          courtId: 'c3',
          courtName: 'Court Gamma',
          hostId: 'p3',
          sport: SportType.tennis,
          date: DateTime.now(),
          startTime: '11:00',
          endTime: '12:00',
          durationHours: 1,
          totalPrice: 105,
          paymentOption: PaymentOption.payNow,
          courtImageUrl:
              'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=300&q=80',
        ),
      ),
    ];
  }

  void _onVenueChanged(int index) {
    setState(() {
      _selectedVenueIndex = index;
      _filterCourtsForVenue(index);
    });
  }

  void _toggleCourt(String id) async {
    final court = _courts.firstWhere((c) => c.id == id);
    try {
      final token = await _getToken();
      if (token != null) {
        await CourtService.updateCourt(
          token: token,
          courtId: id,
          isActive: !court.isActive, photosIds: [],
        );
        setState(() {
          for (final list in [_courts, _allCourts]) {
            final i = list.indexWhere((c) => c.id == id);
            if (i != -1) list[i].isActive = !list[i].isActive;
          }
        });
        _snack(court.isActive ? 'Court closed' : 'Court opened', kGreen);
      }
    } catch (e) {
      _snack('Failed to update court status', kRed);
    }
  }

  void _confirmBooking(String id) => setState(() {
        final i = _bookings.indexWhere((b) => b.id == id);
        if (i != -1) _bookings[i].isPending = false;
      });

  void _declineBooking(String id) => setState(() {
        _bookings.removeWhere((b) => b.id == id);
      });

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

  int get _pending => _bookings.where((b) => b.isPending).length;
  int get _active => _courts.where((c) => c.isActive).length;

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DashboardHeader(
              pendingCount: _pending,
              activeCourts: _active,
              totalCourts: _courts.length,
              managerName: _managerName,
              managerInitials: _managerInitials,
              currentUser: _currentUserData,
              venues: _venues,
              selectedVenueIndex: _selectedVenueIndex,
              onVenueChanged: _onVenueChanged,
              isLoading: _isLoading,
              onProfileUpdated: _onProfileUpdated,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, navH + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle('My Courts', sub: '${_courts.length} courts'),
                const SizedBox(height: 14),
                _isLoadingCourts
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimary))
                    : _courts.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: const Text(
                              'No courts yet. Add courts from the Venue page.',
                              style: TextStyle(color: kTextMid),
                            ),
                          )
                        : SizedBox(
                            height: 210,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _courts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) => _CourtCard(
                                court: _courts[i],
                                onManage: () => _openCourtSheet(_courts[i]),
                              ),
                            ),
                          ),
                const SizedBox(height: 32),
                _SectionTitle(
                  "Today's Schedule",
                  sub: '${_bookings.length} bookings · $_pending pending',
                  pendingBadge: _pending > 0 ? _pending : null,
                ),
                const SizedBox(height: 14),
                ..._bookings.map(
                  (b) => _BookingCard(
                    booking: b,
                    onTap: () => _openBookingSheet(b),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _onProfileUpdated(Map<String, dynamic> updatedUser) {
    setState(() {
      if (_currentUser != null) {
        _currentUser!['username'] = updatedUser['username'];
        _currentUser!['email'] = updatedUser['email'];
        _currentUser!['phone'] = updatedUser['phone'];
        _currentUser!['photoUrl'] = updatedUser['photoUrl'];
      }
    });
  }

  void _openCourtSheet(DashboardCourt court) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CourtManageSheet(
          court: court,
          onToggle: () {
            _toggleCourt(court.id);
            Navigator.pop(context);
          },
        ),
      );

  void _openBookingSheet(ManagerBooking b) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BookingDetailSheet(
          booking: b,
          onConfirm: b.isPending
              ? () {
                  _confirmBooking(b.id);
                  Navigator.pop(context);
                  _snack('Booking confirmed ✓', kGreen);
                }
              : null,
          onDecline: b.isPending
              ? () {
                  _declineBooking(b.id);
                  Navigator.pop(context);
                  _snack('Booking declined', kRed);
                }
              : null,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final int pendingCount, activeCourts, totalCourts;
  final String managerName;
  final String managerInitials;
  final Map<String, dynamic>? currentUser;
  final List<DashboardVenue> venues;
  final int selectedVenueIndex;
  final ValueChanged<int> onVenueChanged;
  final bool isLoading;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const _DashboardHeader({
    required this.pendingCount,
    required this.activeCourts,
    required this.totalCourts,
    required this.managerName,
    required this.managerInitials,
    this.currentUser,
    required this.venues,
    required this.selectedVenueIndex,
    required this.onVenueChanged,
    required this.isLoading,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManagerProfilePage(
                            token: null,
                            currentUser: currentUser ?? {
                              'username': managerName,
                              'email': '',
                              'phone': '',
                            },
                            onProfileUpdated: (updatedUser) {
                              if (onProfileUpdated != null) {
                                onProfileUpdated!(updatedUser);
                              }
                            },
                          ),
                        ),
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [Color(0xFF007B7D), Color(0xFF00A8AB)]),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 2.5),
                        ),
                        child: currentUser != null && currentUser!['photoUrl'] != null && currentUser!['photoUrl'].toString().isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  currentUser!['photoUrl'],
                                  fit: BoxFit.cover,
                                  width: 46,
                                  height: 46,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      managerInitials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  managerInitials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                          Text(
                            managerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: kAmber,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF003D3E), width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                else if (venues.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white70),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No venues yet. Add your first venue from the Venue page.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: venues.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final v = venues[index];
                        final isSelected = selectedVenueIndex == index;
                        return GestureDetector(
                          onTap: () => onVenueChanged(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 220,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.18)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.45)
                                    : Colors.white.withOpacity(0.12),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        Icons.stadium_rounded,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.7),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        v.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: kPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 11,
                                      color: Colors.white.withOpacity(0.55),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        v.location,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.65),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _Chip(
                                      v.isActive ? 'Open' : 'Closed',
                                      v.isActive
                                          ? kGreen.withOpacity(0.25)
                                          : kRed.withOpacity(0.25),
                                      v.isActive ? kGreen : kRed,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Chip(this.text, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final int? pendingBadge;
  const _SectionTitle(this.title, {required this.sub, this.pendingBadge});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                  letterSpacing: -0.4,
                ),
              ),
              if (pendingBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kAmber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingBadge pending',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 12, color: kTextMid)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD - UPDATED with proper image display
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final DashboardCourt court;
  final VoidCallback onManage;
  const _CourtCard({required this.court, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.color;
    final imageUrl = c.displayImageUrl;
    
    return GestureDetector(
      onTap: onManage,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: kElevation,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: sc.withOpacity(0.12),
                      child: Icon(c.sport.icon, color: sc, size: 40),
                    ),
                  )
                : Container(
                    color: sc.withOpacity(0.12),
                    child: Icon(c.sport.icon, color: sc, size: 40),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.78)
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sc,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.sport.icon, size: 9, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          c.sport.label,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isActive
                          ? kGreen.withOpacity(0.85)
                          : kRed.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          c.isActive ? 'Open' : 'Closed',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${c.pricePerHour.toInt()} DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'Manage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 9,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '0 today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 10,
                        ),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT MANAGE SHEET - UPDATED with proper image display
// ─────────────────────────────────────────────────────────────────────────────
class _CourtManageSheet extends StatelessWidget {
  final DashboardCourt court;
  final VoidCallback onToggle;
  const _CourtManageSheet({required this.court, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.color;
    final bot = MediaQuery.of(context).padding.bottom;
    final imageUrl = c.displayImageUrl;
    
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: sc.withOpacity(0.1)),
                        )
                      : Container(color: sc.withOpacity(0.1)),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.70)
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: sc,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(c.sport.icon,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              '${c.pricePerHour.toInt()} DT · ${c.sport.label}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.isActive
                              ? kGreen.withOpacity(0.85)
                              : kRed.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.isActive ? 'Open' : 'Closed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _StatBox(
                        Icons.calendar_today_rounded, '0', 'Today', sc),
                    const SizedBox(width: 10),
                    _StatBox(
                        Icons.sports_rounded, c.sport.label, 'Sport', sc),
                    const SizedBox(width: 10),
                    _StatBox(Icons.attach_money_rounded,
                        '${c.pricePerHour.toInt()} DT', 'Price', sc),
                  ],
                ),
                const SizedBox(height: 20),
                _SheetBtn(
                  icon: c.isActive
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  label: c.isActive ? 'Close Court' : 'Open Court',
                  color: c.isActive ? kRed : kGreen,
                  filled: true,
                  onTap: onToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final r = b.reservation;
    final sc = r.sport.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kElevation,
          border: b.isPending
              ? Border.all(color: kAmber.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                color: sc.withOpacity(0.08),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  r.courtImageUrl != null
                      ? Image.network(
                          r.courtImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: sc.withOpacity(0.1)),
                        )
                      : Container(color: sc.withOpacity(0.1)),
                  Container(color: Colors.black.withOpacity(0.35)),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          r.startTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Icon(r.sport.icon,
                            color: Colors.white.withOpacity(0.8), size: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.courtName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: kTextLight),
                        const SizedBox(width: 4),
                        Text(b.playerName,
                            style:
                                const TextStyle(fontSize: 12, color: kTextMid)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (b.isPending ? kAmber : kGreen).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (b.isPending ? kAmber : kGreen).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      b.isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.check_circle_rounded,
                      size: 11,
                      color: b.isPending ? kAmber : kGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      b.isPending ? 'Pending' : 'Confirmed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: b.isPending ? kAmber : kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailSheet extends StatelessWidget {
  final ManagerBooking booking;
  final VoidCallback? onConfirm, onDecline;
  const _BookingDetailSheet({
    required this.booking,
    this.onConfirm,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final r = b.reservation;
    final sc = r.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: r.courtImageUrl != null
                      ? Image.network(
                          r.courtImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: sc.withOpacity(0.15),
                            child: Icon(r.sport.icon, color: sc, size: 48),
                          ),
                        )
                      : Container(
                          color: sc.withOpacity(0.15),
                          child: Icon(r.sport.icon, color: sc, size: 48),
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.68)
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 28,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: b.isPending ? kAmber : kGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (b.isPending ? kAmber : kGreen)
                              .withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          b.isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          b.isPending ? 'Pending' : 'Confirmed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: sc,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(r.sport.icon,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.courtName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${r.startTime} – ${r.endTime}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [sc, sc.withOpacity(0.6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  b.playerName
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.playerName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: kTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 12, color: kTextLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        b.playerPhone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextMid,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(Icons.phone_rounded,
                                    size: 18, color: kGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (r.paymentOption == PaymentOption.payNow
                                  ? kGreen
                                  : kAmber)
                              .withOpacity(0.07),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14)),
                          border: Border(
                            top: BorderSide(
                              color: (r.paymentOption == PaymentOption.payNow
                                      ? kGreen
                                      : kAmber)
                                  .withOpacity(0.15),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              r.paymentOption == PaymentOption.payNow
                                  ? Icons.bolt_rounded
                                  : Icons.storefront_rounded,
                              size: 14,
                              color: r.paymentOption == PaymentOption.payNow
                                  ? kGreen
                                  : kAmber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.paymentOption == PaymentOption.payNow
                                    ? 'Paid online — confirmed automatically'
                                    : 'Pay at venue — call player to confirm',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      r.paymentOption == PaymentOption.payNow
                                          ? kGreen
                                          : kAmber,
                                ),
                              ),
                            ),
                            Text(
                              '${r.totalPrice.toInt()} DT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: sc,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (b.isPending)
                  Row(
                    children: [
                      Expanded(
                        child: _SheetBtn(
                          icon: Icons.close_rounded,
                          label: 'Decline',
                          color: kRed,
                          onTap: onDecline ?? () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetBtn(
                          icon: Icons.check_rounded,
                          label: 'Confirm',
                          color: kGreen,
                          filled: true,
                          onTap: onConfirm ?? () {},
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreen.withOpacity(0.25)),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: kGreen),
                          SizedBox(width: 8),
                          Text(
                            'Booking confirmed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: kTextMid)),
            ],
          ),
        ),
      );
}

class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _SheetBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: filled ? color : color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border:
                filled ? null : Border.all(color: color.withOpacity(0.3)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: filled ? Colors.white : color),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}*/