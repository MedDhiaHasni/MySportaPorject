// lib/Views/Manager/bookings_page.dart
// Two tabs: Bookings (day-filtered) | Payments (payment tracking)
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart' show CourtReservation, PaymentOption;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFFF2F4F7);
const _kCard    = Colors.white;
const _kInk     = Color(0xFF0A0E1A);
const _kMid     = Color(0xFF64748B);
const _kLight   = Color(0xFFB0BAC9);
const _kBorder  = Color(0xFFE8EDF4);

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fixUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${ApiConstants.mediaBaseUrl}$url';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
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

class PaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final String status;        // pending | succeeded | failed
  final String? stripeIntentId;
  final DateTime createdAt;
  // From populated reservation
  final String reservationId;
  final String courtName;
  final String venueName;
  final String playerName;
  final String courtImageUrl;
  final String bookingDate;
  final SportType sport;

  const PaymentRecord({
    required this.id, required this.amount, required this.currency,
    required this.status, this.stripeIntentId,
    required this.createdAt, required this.reservationId,
    required this.courtName, required this.venueName,
    required this.playerName, required this.courtImageUrl,
    required this.bookingDate, required this.sport,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final id    = json['id']?.toString() ?? '';

    // Reservation
    final resRaw   = attrs['reservation'];
    final resData  = resRaw is Map ? (resRaw['data'] ?? resRaw) as Map<String, dynamic>? : null;
    final resAttrs = resData != null ? ((resData['attributes'] ?? resData) as Map<String, dynamic>) : <String, dynamic>{};
    final resId    = resData?['id']?.toString() ?? '';

    // Court
    final courtRaw   = resAttrs['court'];
    final courtData  = courtRaw is Map ? (courtRaw['data'] ?? courtRaw) as Map<String, dynamic>? : null;
    final courtAttrs = courtData != null ? ((courtData['attributes'] ?? courtData) as Map<String, dynamic>) : <String, dynamic>{};
    final courtName  = courtAttrs['name']?.toString() ?? '';

    // Sport
    SportType sport = SportType.football;
    switch ((courtAttrs['sport']?.toString() ?? '').toLowerCase()) {
      case 'tennis':     sport = SportType.tennis;     break;
      case 'padel':      sport = SportType.padel;      break;
      case 'basketball': sport = SportType.basketball; break;
    }

    // Venue
    final venueRaw   = courtAttrs['venue'];
    final venueData  = venueRaw is Map ? (venueRaw['data'] ?? venueRaw) as Map<String, dynamic>? : null;
    final venueAttrs = venueData != null ? ((venueData['attributes'] ?? venueData) as Map<String, dynamic>) : <String, dynamic>{};
    final venueName  = venueAttrs['name']?.toString() ?? '';

    // Court image
    String imgUrl = courtAttrs['court_img_url']?.toString() ?? '';
    if (imgUrl.isEmpty) {
      final imgRaw  = courtAttrs['court_img'];
      final imgData = imgRaw is Map ? (imgRaw['data'] ?? imgRaw) as Map<String, dynamic>? : null;
      final imgUrl2 = (imgData != null ? ((imgData['attributes'] ?? imgData) as Map)['url']?.toString() : null) ?? '';
      imgUrl = _fixUrl(imgUrl2);
    } else {
      imgUrl = _fixUrl(imgUrl);
    }

    // Player
    final playerRaw   = resAttrs['player'];
    final playerData  = playerRaw is Map ? (playerRaw['data'] ?? playerRaw) as Map<String, dynamic>? : null;
    final playerAttrs = playerData != null ? ((playerData['attributes'] ?? playerData) as Map<String, dynamic>) : <String, dynamic>{};
    final authRaw     = playerAttrs['player'];
    final authData    = authRaw is Map ? (authRaw['data'] ?? authRaw) as Map<String, dynamic>? : null;
    final authAttrs   = authData != null ? ((authData['attributes'] ?? authData) as Map<String, dynamic>) : <String, dynamic>{};
    final playerName  = authAttrs['username']?.toString() ?? playerAttrs['nom']?.toString() ?? 'Player';

    // Date
    final dateStr = resAttrs['booking_date_play']?.toString().split('T')[0] ?? '';

    // Created at
    DateTime created = DateTime.now();
    try { created = DateTime.parse(attrs['createdAt']?.toString() ?? ''); } catch (_) {}

    return PaymentRecord(
      id:             id,
      amount:         (attrs['amount'] as num?)?.toDouble() ?? 0,
      currency:       attrs['currency']?.toString() ?? 'eur',
      status:         attrs['status']?.toString() ?? 'pending',
      stripeIntentId: attrs['stripe_payment_intent_id']?.toString(),
      createdAt:      created,
      reservationId:  resId,
      courtName:      courtName,
      venueName:      venueName,
      playerName:     playerName,
      courtImageUrl:  imgUrl,
      bookingDate:    dateStr,
      sport:          sport,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Bookings extends StatefulWidget {
  final String? managerToken;
  const Bookings({super.key, this.managerToken});
  @override State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // ── Bookings state ────────────────────────────────────────────────────────
  List<ManagerBooking> _bookings       = [];
  int    _selectedDay                  = DateTime.now().weekday - 1;
  String _bookingFilter                = 'All';
  bool   _loadingBookings              = true;
  String? _bookingsError;

  // ── Payments state ────────────────────────────────────────────────────────
  List<PaymentRecord> _payments        = [];
  String _paymentFilter                = 'All';
  bool   _loadingPayments              = false;
  bool   _paymentsLoaded               = false;
  String? _paymentsError;
  Map<String, dynamic> _paymentStats   = {'total': 0, 'totalRevenue': 0.0, 'pending': 0, 'succeeded': 0, 'failed': 0};

  // ── Auth ──────────────────────────────────────────────────────────────────
  String? _token;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      // Lazy-load payments the first time the tab is opened
      if (_tab.index == 1 && !_paymentsLoaded && !_loadingPayments) {
        _loadPayments();
      }
    });
    _init();
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    String? tok = widget.managerToken;
    if (tok == null || tok.isEmpty) tok = await const FlutterSecureStorage().read(key: 'jwt_token');
    if (tok == null || tok.isEmpty) {
      setState(() { _bookingsError = 'Please login to view bookings'; _loadingBookings = false; });
      return;
    }
    _token = tok;
    try {
      final me = await PlayerManagerAuthService.getMe(tok);
      final role = me['user']?['user_role']?.toString();
      if (role != 'manager' && role != 'admin') {
        setState(() { _bookingsError = 'Only managers can access this page'; _loadingBookings = false; });
        return;
      }
    } catch (e) {
      setState(() { _bookingsError = 'Auth error: $e'; _loadingBookings = false; });
      return;
    }
    await _loadBookings();
  }

  // ── Load bookings ─────────────────────────────────────────────────────────

  Future<void> _loadBookings() async {
    setState(() { _loadingBookings = true; _bookingsError = null; });
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reservations?populate[court][populate][worker]=*&populate[court][populate][court_img]=*&populate[time_slot]=*'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'});
      if (r.statusCode != 200) throw Exception('Server error ${r.statusCode}');

      final raw  = json.decode(r.body);
      final list = (raw['data'] ?? (raw is List ? raw : [])) as List<dynamic>;
      final loaded = <ManagerBooking>[];

      for (final res in list) {
        try {
          final attrs = res['attributes'] ?? res;

          // time_slot
          String st = '', et = '';
          final tsRaw = attrs['time_slot'];
          if (tsRaw != null) {
            final tsData = tsRaw['data'] ?? tsRaw;
            if (tsData is Map) {
              final a = tsData['attributes'] ?? tsData;
              st = a['startTime']?.toString() ?? '';
              et = a['endTime']?.toString()   ?? '';
            }
          }
          if (st.isEmpty) st = attrs['start_time'] ?? '00:00';
          if (et.isEmpty) et = attrs['end_time']   ?? '01:00';

          // player
          String playerName = 'Unknown', playerPhone = '';
          final pRaw = attrs['player'];
          final pData = pRaw is Map ? (pRaw['data'] ?? pRaw) : null;
          if (pData is Map) {
            final pa = pData['attributes'] ?? pData;
            playerName  = pa['nom']?.toString() ?? pa['username']?.toString() ?? 'Player';
            playerPhone = pa['phone']?.toString() ?? '';
            final uRaw = pa['player']; final uData = uRaw is Map ? (uRaw['data'] ?? uRaw) : null;
            if (uData is Map) { final ua = uData['attributes'] ?? uData; if (ua['username'] != null) playerName = ua['username'].toString(); }
          }

          // court
          String courtName = '', courtId = '', courtImg = '';
          String? workerName, workerId;
          SportType sport = SportType.football;
          final cRaw = attrs['court'];
          final cData = cRaw is Map ? (cRaw['data'] ?? cRaw) : null;
          if (cData is Map) {
            final ca = cData['attributes'] ?? cData;
            courtId   = cData['id']?.toString() ?? '';
            courtName = ca['name']?.toString() ?? '';
            switch ((ca['sport']?.toString() ?? '').toLowerCase()) {
              case 'tennis': sport = SportType.tennis; break;
              case 'padel':  sport = SportType.padel;  break;
              case 'basketball': sport = SportType.basketball; break;
            }
            final wRaw = ca['worker']; final wData = wRaw is Map ? (wRaw['data'] ?? wRaw) : null;
            if (wData is Map) { final wa = wData['attributes'] ?? wData; workerId = wData['id']?.toString(); workerName = wa['nom']?.toString() ?? 'Worker'; }
            final imgRaw = ca['court_img']; final imgData = imgRaw is Map ? (imgRaw['data'] ?? imgRaw) : null;
            if (imgData is Map) { final ia = imgData['attributes'] ?? imgData; final u = ia['url']?.toString() ?? ''; if (u.isNotEmpty) courtImg = _fixUrl(u); }
            if (courtImg.isEmpty && ca['court_img_url'] != null) courtImg = _fixUrl(ca['court_img_url'].toString());
          }

          // date
          DateTime date = DateTime.now();
          try { date = DateTime.parse(attrs['booking_date_play']?.toString() ?? ''); } catch (_) {}

          final dur    = (attrs['duration_hours'] as num?)?.toDouble() ?? 1.0;
          final price  = (attrs['total_price']    as num?)?.toDouble() ?? 0.0;
          final payOpt = attrs['payment_method'] == 'pay_now' ? PaymentOption.payNow : PaymentOption.payAtVenue;
          final status = attrs['booking_status']?.toString() ?? 'pending';
          final ref    = attrs['booking_reference']?.toString() ?? '';

          loaded.add(ManagerBooking(
            id: res['id']?.toString() ?? '',
            reservation: CourtReservation(id: res['id']?.toString() ?? '', courtId: courtId, courtName: courtName,
              hostId: '', sport: sport, date: date, startTime: st, endTime: et,
              durationHours: dur, totalPrice: price, paymentOption: payOpt,
              courtImageUrl: courtImg.isNotEmpty ? courtImg : null),
            playerName: playerName, playerPhone: playerPhone,
            bookingReference: ref,
            isPending: payOpt == PaymentOption.payAtVenue && status == 'pending',
            bookingStatus: status, workerName: workerName, workerId: workerId));
        } catch (_) {}
      }
      setState(() { _bookings = loaded; _loadingBookings = false; });
    } catch (e) {
      setState(() { _bookingsError = e.toString().replaceAll('Exception: ', ''); _loadingBookings = false; });
    }
  }

  // ── Load payments ─────────────────────────────────────────────────────────

  Future<void> _loadPayments() async {
    setState(() { _loadingPayments = true; _paymentsError = null; });
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payments?limit=200'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'});
      if (r.statusCode != 200) throw Exception('Server error ${r.statusCode}');

      final raw  = json.decode(r.body) as Map<String, dynamic>;
      final list = (raw['payments'] as List<dynamic>? ?? []);
      final stats = raw['stats'] as Map<String, dynamic>? ?? {};

      setState(() {
        _payments      = list.map((j) => PaymentRecord.fromJson(j as Map<String, dynamic>)).toList();
        _paymentStats  = {
          'total':        stats['total']        ?? 0,
          'totalRevenue': (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          'pending':      stats['pending']      ?? 0,
          'succeeded':    stats['succeeded']    ?? 0,
          'failed':       stats['failed']       ?? 0,
        };
        _loadingPayments = false;
        _paymentsLoaded  = true;
      });
    } catch (e) {
      setState(() { _paymentsError = e.toString().replaceAll('Exception: ', ''); _loadingPayments = false; });
    }
  }

  // ── Booking actions ───────────────────────────────────────────────────────

  Future<void> _confirmBooking(String id) async {
    try {
      final r = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/confirm'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'});
      if (r.statusCode != 200) throw Exception('Failed to confirm');
      setState(() {
        final i = _bookings.indexWhere((b) => b.id == id);
        if (i != -1) { _bookings[i].isPending = false; _bookings[i].bookingStatus = 'confirmed'; }
      });
      _snack('Booking confirmed ✓', kGreen);
    } catch (e) { _snack('Failed to confirm', kRed); }
  }

  Future<void> _declineBooking(String id) async {
    try {
      final r = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/reservations/$id/cancel'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'});
      if (r.statusCode != 200) throw Exception('Failed');
      setState(() => _bookings.removeWhere((b) => b.id == id));
      _snack('Booking declined', kRed);
    } catch (e) { _snack('Failed to decline', kRed); }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2)));

  // ── Computed ──────────────────────────────────────────────────────────────

  int get _confirmedCount => _bookings.where((b) => !b.isPending && b.bookingStatus == 'confirmed').length;
  int get _pendingCount   => _bookings.where((b) => b.isPending).length;

  List<ManagerBooking> get _filteredBookings {
    final today     = DateTime.now();
    final startWk   = today.subtract(Duration(days: today.weekday - 1));
    final target    = startWk.add(Duration(days: _selectedDay));
    final targetDay = DateTime(target.year, target.month, target.day);
    final dayFiltered = _bookings.where((b) {
      final d = DateTime(b.reservation.date.year, b.reservation.date.month, b.reservation.date.day);
      return d.isAtSameMomentAs(targetDay);
    }).toList();
    switch (_bookingFilter) {
      case 'Confirmed': return dayFiltered.where((b) => !b.isPending && b.bookingStatus == 'confirmed').toList();
      case 'Pending':   return dayFiltered.where((b) => b.isPending).toList();
      default:          return dayFiltered;
    }
  }

  List<PaymentRecord> get _filteredPayments {
    switch (_paymentFilter) {
      case 'Succeeded': return _payments.where((p) => p.status == 'succeeded').toList();
      case 'Pending':   return _payments.where((p) => p.status == 'pending').toList();
      case 'Failed':    return _payments.where((p) => p.status == 'failed').toList();
      default:          return _payments;
    }
  }

  DateTime _dateForWeekday(int i) {
    final today = DateTime.now();
    return today.add(Duration(days: i - (today.weekday - 1)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── Top bar ──────────────────────────────────────────────────────────
        Container(color: _kCard, child: SafeArea(bottom: false, child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 14), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bookings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _kInk, letterSpacing: -0.6)),
              const SizedBox(height: 2),
              if (!_loadingBookings)
                RichText(text: TextSpan(children: [
                  TextSpan(text: '$_confirmedCount confirmed', style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600)),
                  TextSpan(text: '  ·  $_pendingCount pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _pendingCount > 0 ? kAmber : _kMid)),
                ])),
            ])),
            if (_pendingCount > 0 && !_loadingBookings)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: kAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: kAmber.withOpacity(0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: kAmber, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$_pendingCount to call', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kAmber)),
                ])),
          ])),

          // TabBar
          TabBar(
            controller:              _tab,
            labelColor:              kPrimary,
            unselectedLabelColor:    _kMid,
            indicatorColor:          kPrimary,
            indicatorWeight:         2.5,
            labelStyle:              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Bookings'),
              Tab(text: 'Payments'),
            ]),
        ]))),

        // ── Tab bodies ────────────────────────────────────────────────────────
        Expanded(child: TabBarView(controller: _tab, children: [

          // ── BOOKINGS TAB ─────────────────────────────────────────────────
          Column(children: [
            Container(color: _kCard, child: Column(children: [
              // Day strip
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (i) {
                    final sel  = i == _selectedDay;
                    final date = _dateForWeekday(i);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40, padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: sel ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : []),
                        child: Column(children: [
                          Text(_days[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white.withOpacity(0.75) : _kMid)),
                          const SizedBox(height: 3),
                          Text('${date.day}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: sel ? Colors.white : _kInk)),
                        ])));
                  })))),
              // Filter chips
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  _FilterChip(label: 'All',       selected: _bookingFilter == 'All',       onTap: () => setState(() => _bookingFilter = 'All')),
                  _FilterChip(label: 'Confirmed', selected: _bookingFilter == 'Confirmed', count: _confirmedCount, onTap: () => setState(() => _bookingFilter = 'Confirmed')),
                  _FilterChip(label: 'Pending',   selected: _bookingFilter == 'Pending',   count: _pendingCount,   onTap: () => setState(() => _bookingFilter = 'Pending')),
                ])),
            ])),
            Expanded(child: _loadingBookings
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _bookingsError != null
                    ? _ErrorState(msg: _bookingsError!, onRetry: _loadBookings)
                    : _filteredBookings.isEmpty
                        ? const _EmptyState(icon: Icons.calendar_today_rounded, text: 'No bookings for this day')
                        : RefreshIndicator(onRefresh: _loadBookings, color: kPrimary,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 16),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (_, i) {
                                final b = _filteredBookings[i];
                                return _BookingCard(booking: b,
                                  onTap: () => _openBookingSheet(b),
                                  onConfirm: b.isPending ? () => _confirmBooking(b.id) : null,
                                  onDecline: b.isPending ? () => _declineBooking(b.id) : null);
                              }))),
          ]),

          // ── PAYMENTS TAB ─────────────────────────────────────────────────
          Column(children: [
            // Stats strip
            if (!_loadingPayments && _paymentsLoaded)
              _PaymentStatsStrip(stats: _paymentStats),
            // Filter chips
            Container(color: _kCard, padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                _FilterChip(label: 'All',       selected: _paymentFilter == 'All',       onTap: () => setState(() => _paymentFilter = 'All')),
                _FilterChip(label: 'Succeeded', selected: _paymentFilter == 'Succeeded', color: kGreen,
                  count: (_paymentStats['succeeded'] as num?)?.toInt(),
                  onTap: () => setState(() => _paymentFilter = 'Succeeded')),
                _FilterChip(label: 'Pending',   selected: _paymentFilter == 'Pending',   color: kAmber,
                  count: (_paymentStats['pending'] as num?)?.toInt(),
                  onTap: () => setState(() => _paymentFilter = 'Pending')),
                _FilterChip(label: 'Failed',    selected: _paymentFilter == 'Failed',    color: kRed,
                  count: (_paymentStats['failed'] as num?)?.toInt(),
                  onTap: () => setState(() => _paymentFilter = 'Failed')),
              ])),
            Expanded(child: _loadingPayments
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _paymentsError != null
                    ? _ErrorState(msg: _paymentsError!, onRetry: _loadPayments)
                    : _filteredPayments.isEmpty
                        ? const _EmptyState(icon: Icons.payment_rounded, text: 'No payments found')
                        : RefreshIndicator(onRefresh: _loadPayments, color: kPrimary,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 16),
                              itemCount: _filteredPayments.length,
                              itemBuilder: (_, i) => _PaymentCard(payment: _filteredPayments[i])))),
          ]),
        ])),
      ]),
    );
  }

  void _openBookingSheet(ManagerBooking b) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(booking: b,
      onConfirm: b.isPending ? () { Navigator.pop(context); _confirmBooking(b.id); } : null,
      onDecline: b.isPending ? () { Navigator.pop(context); _declineBooking(b.id); } : null));
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentStatsStrip extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _PaymentStatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final revenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(children: [
        Expanded(child: _StatBox(
          icon: Icons.payments_rounded, color: kGreen,
          value: '${revenue.toStringAsFixed(0)} DT', label: 'Revenue')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
          icon: Icons.check_circle_rounded, color: kGreen,
          value: '${stats['succeeded'] ?? 0}', label: 'Succeeded')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
          icon: Icons.hourglass_top_rounded, color: kAmber,
          value: '${stats['pending'] ?? 0}', label: 'Pending')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
          icon: Icons.cancel_rounded, color: kRed,
          value: '${stats['failed'] ?? 0}', label: 'Failed')),
      ]));
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon; final Color color; final String value, label;
  const _StatBox({required this.icon, required this.color, required this.value, required this.label});
  @override Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: _kMid)),
    ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentCard extends StatelessWidget {
  final PaymentRecord payment;
  const _PaymentCard({required this.payment});

  Color get _statusColor {
    switch (payment.status) {
      case 'succeeded': return kGreen;
      case 'failed':    return kRed;
      default:          return kAmber;
    }
  }

  IconData get _statusIcon {
    switch (payment.status) {
      case 'succeeded': return Icons.check_circle_rounded;
      case 'failed':    return Icons.cancel_rounded;
      default:          return Icons.hourglass_top_rounded;
    }
  }

  String get _statusLabel {
    switch (payment.status) {
      case 'succeeded': return 'Paid';
      case 'failed':    return 'Failed';
      default:          return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc  = payment.sport.color;
    final col = _statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: payment.status == 'failed' ? kRed.withOpacity(0.2) : _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        // Court image
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 58, height: 58,
            child: payment.courtImageUrl.isNotEmpty
                ? Image.network(payment.courtImageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(sc))
                : _fallback(sc))),
        const SizedBox(width: 13),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Sport chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(payment.sport.icon, size: 9, color: sc), const SizedBox(width: 3),
              Text(payment.sport.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sc))])),
          const SizedBox(height: 5),
          Text(payment.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.person_outline_rounded, size: 11, color: _kLight), const SizedBox(width: 4),
            Expanded(child: Text(payment.playerName, style: const TextStyle(fontSize: 12, color: _kMid), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          if (payment.venueName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 11, color: _kLight), const SizedBox(width: 4),
              Text(payment.venueName, style: const TextStyle(fontSize: 11, color: _kLight)),
            ]),
          ],
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: _kLight), const SizedBox(width: 4),
            Text(payment.bookingDate, style: const TextStyle(fontSize: 11, color: _kLight)),
          ]),
        ])),
        const SizedBox(width: 10),

        // Amount + status
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${payment.amount.toStringAsFixed(0)} ${payment.currency.toUpperCase()}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _kInk)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_statusIcon, size: 11, color: col), const SizedBox(width: 4),
              Text(_statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: col)),
            ])),
          // Stripe intent short id
          if (payment.stripeIntentId != null) ...[
            const SizedBox(height: 5),
            Text(
              payment.stripeIntentId!.length > 14
                  ? '…${payment.stripeIntentId!.substring(payment.stripeIntentId!.length - 10)}'
                  : payment.stripeIntentId!,
              style: const TextStyle(fontSize: 9, color: _kLight, fontFamily: 'monospace')),
          ],
        ]),
      ])));
  }

  Widget _fallback(Color c) => Container(color: c.withOpacity(0.1), child: Icon(payment.sport.icon, color: c, size: 24));
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final ManagerBooking booking; final VoidCallback onTap;
  final VoidCallback? onConfirm, onDecline;
  const _BookingCard({required this.booking, required this.onTap, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b = booking; final r = b.reservation; final sc = r.sport.color;
    return GestureDetector(onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: b.isPending ? Border.all(color: kAmber.withOpacity(0.3), width: 1.5) : Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(13),
                child: SizedBox(width: 64, height: 64,
                  child: r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                      ? Image.network(r.courtImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: sc.withOpacity(0.12), child: Icon(r.sport.icon, color: sc, size: 26)))
                      : Container(color: sc.withOpacity(0.12), child: Icon(r.sport.icon, color: sc, size: 26)))),
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(height: 22,
                  decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)])),
                  child: Center(child: Text(r.startTime, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))))),
            ]),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _Chip(r.sport.label, r.sport.icon, sc),
                if (b.workerName != null) ...[const SizedBox(width: 5), _Chip('Worker', Icons.engineering_rounded, kAmber)],
              ]),
              const SizedBox(height: 5),
              Text(r.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.person_outline_rounded, size: 12, color: _kLight), const SizedBox(width: 4), Expanded(child: Text(b.playerName, style: const TextStyle(fontSize: 12, color: _kMid), maxLines: 1, overflow: TextOverflow.ellipsis))]),
              const SizedBox(height: 2),
              Row(children: [const Icon(Icons.access_time_rounded, size: 11, color: _kLight), const SizedBox(width: 4), Text('${r.startTime} – ${r.endTime}', style: const TextStyle(fontSize: 11, color: _kLight))]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: (b.isPending ? kAmber : kGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: (b.isPending ? kAmber : kGreen).withOpacity(0.2))),
                child: Text(b.isPending ? 'Pending' : 'Confirmed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: b.isPending ? kAmber : kGreen))),
              const SizedBox(height: 8),
              Text('${r.totalPrice.toInt()} DT', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _kInk)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(r.paymentOption == PaymentOption.payNow ? Icons.bolt_rounded : Icons.storefront_rounded, size: 10, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber),
                const SizedBox(width: 3),
                Text(r.paymentOption == PaymentOption.payNow ? 'Online' : 'At venue', style: TextStyle(fontSize: 9, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ])),
          if (b.isPending) ...[
            Container(height: 1, color: _kBorder),
            Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 12), child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kAmber.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: kAmber.withOpacity(0.18))),
                child: Row(children: [
                  const Icon(Icons.phone_rounded, size: 13, color: kAmber), const SizedBox(width: 8),
                  Expanded(child: Text(
                    b.playerPhone.isNotEmpty ? 'Call ${b.playerName.split(' ').first} — ${b.playerPhone}' : 'Call ${b.playerName.split(' ').first} to verify',
                    style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w600))),
                ])),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _ActionBtn('Decline', kRed,   false, onDecline)),
                const SizedBox(width: 10),
                Expanded(child: _ActionBtn('Confirm', kGreen, true,  onConfirm)),
              ]),
            ])),
          ],
        ])));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _BookingSheet extends StatelessWidget {
  final ManagerBooking booking; final VoidCallback? onConfirm, onDecline;
  const _BookingSheet({required this.booking, this.onConfirm, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final b = booking; final r = b.reservation; final sc = r.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), child: Stack(children: [
          SizedBox(height: 185, width: double.infinity,
            child: r.courtImageUrl != null && r.courtImageUrl!.isNotEmpty
                ? Image.network(r.courtImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _heroBg(sc))
                : _heroBg(sc)),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.75)], stops: const [0.25, 1.0])))),
          Positioned(top: 12, left: 0, right: 0, child: Center(child: Container(width: 38, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2))))),
          Positioned(top: 24, left: 14, child: _Chip(r.sport.label, r.sport.icon, sc, big: true)),
          if (b.workerName != null) Positioned(top: 24, right: 14, child: _Chip(b.workerName!, Icons.engineering_rounded, kAmber, big: true)),
          Positioned(bottom: 14, left: 16, right: 16, child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.courtName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Row(children: [const Icon(Icons.access_time_rounded, size: 12, color: Colors.white70), const SizedBox(width: 4), Text('${r.startTime} – ${r.endTime} · ${r.durationHours}h', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
            ])),
            Text('${r.totalPrice.toInt()} DT', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ])),
        ])),
        Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, bot + 20), child: Column(children: [
          Container(
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: [sc, sc.withOpacity(0.7)]), shape: BoxShape.circle),
                  child: Center(child: Text(b.playerName.split(' ').map((e) => e[0]).take(2).join(), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.playerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kInk)),
                  const SizedBox(height: 3),
                  Row(children: [const Icon(Icons.phone_outlined, size: 12, color: _kLight), const SizedBox(width: 4), Text(b.playerPhone.isNotEmpty ? b.playerPhone : 'No phone', style: const TextStyle(fontSize: 12, color: _kMid))]),
                  const SizedBox(height: 2),
                  Row(children: [const Icon(Icons.receipt_long_rounded, size: 11, color: _kLight), const SizedBox(width: 4), Text('Ref: ${b.bookingReference}', style: const TextStyle(fontSize: 11, color: _kMid))]),
                ])),
                if (b.playerPhone.isNotEmpty) Container(width: 38, height: 38, decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.phone_rounded, size: 17, color: kGreen)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: (r.paymentOption == PaymentOption.payNow ? kGreen : kAmber).withOpacity(0.15)))),
                child: Row(children: [
                  Icon(r.paymentOption == PaymentOption.payNow ? Icons.bolt_rounded : Icons.storefront_rounded, size: 14, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.paymentOption == PaymentOption.payNow ? 'Paid online — confirmed automatically' : 'Pay at venue — call player to confirm',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.paymentOption == PaymentOption.payNow ? kGreen : kAmber))),
                ])),
            ])),
          const SizedBox(height: 14),
          if (b.isPending)
            Row(children: [
              Expanded(child: _ActionBtn('Decline',         kRed,   false, onDecline)),
              const SizedBox(width: 12),
              Expanded(child: _ActionBtn('Confirm Booking', kGreen, true,  onConfirm)),
            ])
          else
            Container(height: 50,
              decoration: BoxDecoration(color: kGreen.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: kGreen.withOpacity(0.2))),
              child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, size: 16, color: kGreen), SizedBox(width: 8),
                Text('Booking Confirmed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen))]))),
        ])),
      ]));
  }

  Widget _heroBg(Color c) => Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(c, Colors.black, 0.5)!, c], begin: Alignment.topLeft, end: Alignment.bottomRight)));
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final int? count;
  final Color? color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, this.count, this.color, required this.onTap});

  @override Widget build(_) => Padding(padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(color: selected ? (color ?? kPrimary) : _kBg, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : _kMid)),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 5),
            Container(width: 18, height: 18,
              decoration: BoxDecoration(color: selected ? Colors.white.withOpacity(0.25) : (color ?? kPrimary).withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text('$count', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: selected ? Colors.white : (color ?? kPrimary))))),
          ],
        ]))));
}

class _Chip extends StatelessWidget {
  final String label; final IconData icon; final Color color; final bool big;
  const _Chip(this.label, this.icon, this.color, {this.big = false});
  @override Widget build(_) => Container(
    padding: EdgeInsets.symmetric(horizontal: big ? 10 : 6, vertical: big ? 5 : 2),
    decoration: BoxDecoration(color: big ? color.withOpacity(0.9) : color.withOpacity(0.1), borderRadius: BorderRadius.circular(big ? 20 : 6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: big ? 11 : 9, color: big ? Colors.white : color), SizedBox(width: big ? 5 : 3),
      Text(label, style: TextStyle(fontSize: big ? 11 : 9, fontWeight: FontWeight.w700, color: big ? Colors.white : color))]));
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final bool filled; final VoidCallback? onTap;
  const _ActionBtn(this.label, this.color, this.filled, this.onTap);
  @override Widget build(_) => GestureDetector(onTap: onTap,
    child: Container(height: 46,
      decoration: filled
          ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))])
          : BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(13), border: Border.all(color: color.withOpacity(0.28))),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)))));
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String text;
  const _EmptyState({required this.icon, required this.text});
  @override Widget build(_) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: kPrimary, size: 28)),
    const SizedBox(height: 14),
    Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kInk)),
    const SizedBox(height: 5),
    const Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: _kMid)),
  ]));
}

class _ErrorState extends StatelessWidget {
  final String msg; final VoidCallback onRetry;
  const _ErrorState({required this.msg, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.error_outline_rounded, color: kRed, size: 28)),
    const SizedBox(height: 14),
    const Text('Something went wrong', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kInk)),
    const SizedBox(height: 6),
    Text(msg, style: const TextStyle(fontSize: 12, color: _kMid), textAlign: TextAlign.center),
    const SizedBox(height: 18),
    ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Retry')),
  ])));
}