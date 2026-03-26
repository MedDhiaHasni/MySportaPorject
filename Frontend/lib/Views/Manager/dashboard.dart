// dashboard.dart — Views/Manager/dashboard.dart
// Manager home: uses CourtModel, CourtReservation, TournamentModel
// same models as player side → backend maps 1:1

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Views/Manager/ManageTournamentPage.dart';
import 'package:sporta/Views/Player/matches_page.dart' show TournamentModel;

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER-SIDE WRAPPER MODELS
// These thin wrappers add manager-only state on top of the shared models.
// In the backend: isPending = reservation status field; isActive = court status field.
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps CourtModel + manager-only fields (isActive, bookingsToday)
/// Backend: courts table + a live_status or is_active boolean field
class ManagerCourt {
  final CourtModel court;
  bool isActive;
  final int bookingsToday;
  ManagerCourt({
    required this.court,
    required this.isActive,
    required this.bookingsToday,
  });
}

/// Wraps CourtReservation + manager-only fields (playerName, isPending)
/// Backend: court_reservations table + status enum (pending/confirmed/declined)
class ManagerBooking {
  final String id;
  final CourtReservation reservation;
  final String playerName;
  final String playerPhone; // shown to manager for pay-at-venue bookings
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
// SAMPLE DATA — swap for Strapi API calls
// ─────────────────────────────────────────────────────────────────────────────
final _venue = VenueModel(
  name: 'Arena Sport Center',
  location: 'Lac 2, Tunis',
  sports: ['Football', 'Padel', 'Tennis', 'Basketball'],
  amenities: ['Parking', 'Showers', 'Floodlights', 'Locker'],
  minPrice: 75,
  maxPrice: 120,
  available: true,
  openUntil: '11:00 PM',
  image: 'assets/sportcenter.jpg',
  lat: 36.8425,
  lng: 10.2320,
  courts: [],
  managerName: 'Anis Trabelsi',
  managerPhone: '+216 71 234 567',
  managerAvatar: 'AT',
);

List<ManagerCourt> _initCourts() => [
  ManagerCourt(
    court: CourtModel(
      id: 'c1',
      name: 'Court Alpha',
      location: 'Lac 2, Tunis',
      sport: SportType.football,
      pricePerHour: 90,
      color: SportType.football.color,
      imageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    ),
    isActive: true,
    bookingsToday: 6,
  ),
  ManagerCourt(
    court: CourtModel(
      id: 'c2',
      name: 'Court Beta',
      location: 'Lac 2, Tunis',
      sport: SportType.padel,
      pricePerHour: 120,
      color: SportType.padel.color,
      imageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    ),
    isActive: true,
    bookingsToday: 4,
  ),
  ManagerCourt(
    court: CourtModel(
      id: 'c3',
      name: 'Court Gamma',
      location: 'Lac 2, Tunis',
      sport: SportType.tennis,
      pricePerHour: 105,
      color: SportType.tennis.color,
      imageUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    ),
    isActive: false,
    bookingsToday: 2,
  ),
  ManagerCourt(
    court: CourtModel(
      id: 'c4',
      name: 'Court Delta',
      location: 'Lac 2, Tunis',
      sport: SportType.basketball,
      pricePerHour: 75,
      color: SportType.basketball.color,
      imageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
    ),
    isActive: true,
    bookingsToday: 5,
  ),
];

List<ManagerBooking> _initBookings() => [
  // payNow → auto-confirmed (isPending: false)
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
  // payAtVenue → pending until manager confirms (isPending: true)
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
  // payNow → auto-confirmed
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
  // payAtVenue → pending
  ManagerBooking(
    id: 'b4',
    playerName: 'Leila Mallouli',
    playerPhone: '+216 56 456 789',
    isPending: true,
    reservation: CourtReservation(
      id: 'r4',
      courtId: 'c4',
      courtName: 'Court Delta',
      hostId: 'p4',
      sport: SportType.basketball,
      date: DateTime.now(),
      startTime: '14:00',
      endTime: '15:00',
      durationHours: 1,
      totalPrice: 75,
      paymentOption: PaymentOption.payAtVenue,
      courtImageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=300&q=80',
    ),
  ),
  // payAtVenue → pending
  ManagerBooking(
    id: 'b5',
    playerName: 'Ahmed Ben Ali',
    playerPhone: '+216 58 567 890',
    isPending: true,
    reservation: CourtReservation(
      id: 'r5',
      courtId: 'c1',
      courtName: 'Court Alpha',
      hostId: 'p5',
      sport: SportType.football,
      date: DateTime.now(),
      startTime: '19:00',
      endTime: '20:00',
      durationHours: 1,
      totalPrice: 90,
      paymentOption: PaymentOption.payAtVenue,
      courtImageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
    ),
  ),
];

List<TournamentModel> _initTournaments() => [
  TournamentModel(
    id: 't1',
    title: 'Summer Padel Cup',
    venueName: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    sport: SportType.padel,
    date: DateTime(2025, 6, 15),
    time: '10:00',
    maxTeams: 16,
    registeredTeams: 8,
    prizePool: 1200,
    entryFee: 60,
    posterUrl:
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
    description: 'Annual padel championship open to all levels.',
    format: 'Doubles Round-Robin',
    prizes: ['🥇 1st: 700 DT', '🥈 2nd: 300 DT', '🥉 3rd: 200 DT'],
  ),
  TournamentModel(
    id: 't2',
    title: 'Friday Football 5v5',
    venueName: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    sport: SportType.football,
    date: DateTime(2025, 6, 21),
    time: '09:00',
    maxTeams: 8,
    registeredTeams: 6,
    prizePool: 2000,
    entryFee: 80,
    posterUrl:
        'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
    description: 'Weekly 5-a-side league. Fast-paced, competitive.',
    format: '5v5 Knockout',
    prizes: ['🥇 1st: 1000 DT', '🥈 2nd: 600 DT', '🥉 3rd: 400 DT'],
  ),
  TournamentModel(
    id: 't3',
    title: 'Tennis Open Singles',
    venueName: 'Arena Sport Center',
    location: 'Lac 2, Tunis',
    sport: SportType.tennis,
    date: DateTime(2025, 7, 5),
    time: '08:00',
    maxTeams: 32,
    registeredTeams: 12,
    prizePool: 3000,
    entryFee: 100,
    posterUrl:
        'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
    description: 'Open singles bracket for all skill levels.',
    format: 'Singles Knockout',
    prizes: ['🥇 1st: 1500 DT', '🥈 2nd: 900 DT', '🥉 3rd: 600 DT'],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late List<ManagerCourt> _courts;
  late List<ManagerBooking> _bookings;
  late List<TournamentModel> _tournaments;

  @override
  void initState() {
    super.initState();
    _courts = _initCourts();
    _bookings = _initBookings();
    _tournaments = _initTournaments();
  }

  int get _pending => _bookings.where((b) => b.isPending).length;
  int get _active => _courts.where((c) => c.isActive).length;

  void _toggleCourt(String id) => setState(() {
    final i = _courts.indexWhere((c) => c.court.id == id);
    if (i != -1) _courts[i].isActive = !_courts[i].isActive;
  });

  void _confirmBooking(String id) => setState(() {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1) _bookings[i].isPending = false;
  });

  void _declineBooking(String id) => setState(() {
    _bookings.removeWhere((b) => b.id == id);
  });

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
              venue: _venue,
              pendingCount: _pending,
              activeCourts: _active,
              totalCourts: _courts.length,
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, navH + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── My Courts ───────────────────────────────────────────────────
                _SectionTitle('My Courts', sub: '${_courts.length} courts'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _CourtCard(
                      mc: _courts[i],
                      onManage: () => _openCourtSheet(_courts[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Today's Schedule ────────────────────────────────────────────
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
                const SizedBox(height: 32),

                // ── Tournaments ─────────────────────────────────────────────────
                _SectionTitle(
                  'Tournaments',
                  sub: '${_tournaments.length} active',
                ),
                const SizedBox(height: 14),
                ..._tournaments.map(
                  (t) => _TournamentCard(
                    tournament: t,
                    onManage: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageTournamentPage(tournament: t),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openCourtSheet(ManagerCourt mc) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CourtManageSheet(
      mc: mc,
      onToggle: () {
        _toggleCourt(mc.court.id);
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

  void _snack(
    String msg,
    Color color,
  ) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final VenueModel venue;
  final int pendingCount, activeCourts, totalCourts;
  const _DashboardHeader({
    required this.venue,
    required this.pendingCount,
    required this.activeCourts,
    required this.totalCourts,
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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Center(
                    child: Text(
                      venue.managerAvatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
                        venue.managerName,
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
                              color: const Color(0xFF003D3E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.stadium_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 11,
                              color: Colors.white.withOpacity(0.55),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              venue.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Chip(
                        '$activeCourts/$totalCourts courts',
                        Colors.white.withOpacity(0.15),
                        Colors.white,
                      ),
                      const SizedBox(height: 6),
                      pendingCount > 0
                          ? _Chip(
                              '$pendingCount pending',
                              kAmber.withOpacity(0.25),
                              kAmber,
                            )
                          : _Chip(
                              'All clear ✓',
                              kGreen.withOpacity(0.2),
                              kGreen,
                            ),
                    ],
                  ),
                ],
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
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      Text(sub, style: const TextStyle(fontSize: 12, color: kTextMid)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD — wraps CourtModel via ManagerCourt
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final ManagerCourt mc;
  final VoidCallback onManage;
  const _CourtCard({required this.mc, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final c = mc.court;
    final sc = c.color;
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
            c.imageUrl != null
                ? Image.network(
                    c.imageUrl!,
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.78)],
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
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: mc.isActive
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
                          mc.isActive ? 'Open' : 'Closed',
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
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
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
                        '${mc.bookingsToday} today',
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
// COURT MANAGE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CourtManageSheet extends StatelessWidget {
  final ManagerCourt mc;
  final VoidCallback onToggle;
  const _CourtManageSheet({required this.mc, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = mc.court;
    final sc = c.color;
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
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: c.imageUrl != null
                      ? Image.network(
                          c.imageUrl!,
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
                          Colors.black.withOpacity(0.70),
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
                        child: Icon(
                          c.sport.icon,
                          color: Colors.white,
                          size: 18,
                        ),
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: mc.isActive
                              ? kGreen.withOpacity(0.85)
                              : kRed.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          mc.isActive ? 'Open' : 'Closed',
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
                      Icons.calendar_today_rounded,
                      '${mc.bookingsToday}',
                      'Today',
                      sc,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(Icons.sports_rounded, c.sport.label, 'Sport', sc),
                    const SizedBox(width: 10),
                    _StatBox(
                      Icons.attach_money_rounded,
                      '${c.pricePerHour.toInt()} DT',
                      'Price',
                      sc,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SheetBtn(
                  icon: mc.isActive
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  label: mc.isActive ? 'Close Court' : 'Open Court',
                  color: mc.isActive ? kRed : kGreen,
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
// BOOKING CARD — uses ManagerBooking (wraps CourtReservation)
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
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
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
                        Icon(
                          r.sport.icon,
                          color: Colors.white.withOpacity(0.8),
                          size: 11,
                        ),
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
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: kTextLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          b.playerName,
                          style: const TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (b.isPending ? kAmber : kGreen).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (b.isPending ? kAmber : kGreen).withOpacity(0.3),
                  ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          Colors.black.withOpacity(0.68),
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: b.isPending ? kAmber : kGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (b.isPending ? kAmber : kGreen).withOpacity(
                            0.3,
                          ),
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
                        child: Icon(
                          r.sport.icon,
                          color: Colors.white,
                          size: 18,
                        ),
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
                // Player card
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
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 12,
                                        color: kTextLight,
                                      ),
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
                            // Call button
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  size: 18,
                                  color: kGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Payment + price row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (r.paymentOption == PaymentOption.payNow
                                      ? kGreen
                                      : kAmber)
                                  .withOpacity(0.07),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(14),
                          ),
                          border: Border(
                            top: BorderSide(
                              color:
                                  (r.paymentOption == PaymentOption.payNow
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
                                  color: r.paymentOption == PaymentOption.payNow
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
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: kGreen,
                          ),
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
// TOURNAMENT CARD — uses TournamentModel (same as player matches_page)
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onManage;
  const _TournamentCard({required this.tournament, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final sc = t.sport.color;
    return GestureDetector(
      onTap: onManage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: kElevation,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                t.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.lerp(sc, Colors.black, 0.5)!, sc],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sc,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.sport.icon, size: 11, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      t.sport.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.isFull
                      ? kRed.withOpacity(0.9)
                      : kGreen.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.isFull ? 'Full' : '${t.spotsLeft} spots left',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.dateLabel,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.groups_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${t.registeredTeams}/${t.maxTeams}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${t.entryFee} DT entry',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onManage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 13, color: sc),
                            const SizedBox(width: 5),
                            Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: sc,
                              ),
                            ),
                          ],
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
          Text(label, style: const TextStyle(fontSize: 10, color: kTextMid)),
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
        border: filled ? null : Border.all(color: color.withOpacity(0.3)),
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
            Icon(icon, size: 16, color: filled ? Colors.white : color),
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
}
