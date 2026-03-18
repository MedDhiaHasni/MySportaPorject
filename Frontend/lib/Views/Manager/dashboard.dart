// dashboard.dart — Manager Dashboard
// Rebuilt: no stats cards, no settings, clean courts + schedule + tournaments

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Views/Manager/ManageTournamentPage.dart' as manage;
import 'package:sporta/Views/Manager/tournaments.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _Court {
  final String id, name, imageUrl;
  final SportType sport;
  final double price;
  bool isActive;
  final int bookingsToday;
  _Court({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sport,
    required this.price,
    required this.isActive,
    required this.bookingsToday,
  });
}

class _Booking {
  final String id, time, courtName, courtImage, player;
  final SportType sport;
  bool isPending;
  _Booking({
    required this.id,
    required this.time,
    required this.courtName,
    required this.courtImage,
    required this.player,
    required this.sport,
    required this.isPending,
  });
}

class TournamentData {
  final String id, name, date, description, posterUrl;
  final SportType sport;
  final int teams, max;
  final int entryFee, prizePool;
  TournamentData({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.posterUrl,
    required this.sport,
    required this.teams,
    required this.max,
    required this.entryFee,
    required this.prizePool,
  });
  bool get isFull => teams >= max;
  int get spotsLeft => max - teams;
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<_Court> _courts = [
    _Court(
      id: 'c1',
      name: 'Court Alpha',
      imageUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
      sport: SportType.football,
      price: 90,
      isActive: true,
      bookingsToday: 6,
    ),
    _Court(
      id: 'c2',
      name: 'Court Beta',
      imageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
      sport: SportType.padel,
      price: 120,
      isActive: true,
      bookingsToday: 4,
    ),
    _Court(
      id: 'c3',
      name: 'Court Gamma',
      imageUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
      sport: SportType.tennis,
      price: 105,
      isActive: false,
      bookingsToday: 2,
    ),
    _Court(
      id: 'c4',
      name: 'Court Delta',
      imageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=700&q=80',
      sport: SportType.basketball,
      price: 75,
      isActive: true,
      bookingsToday: 5,
    ),
  ];

  List<_Booking> _bookings = [
    _Booking(
      id: 'b1',
      time: '08:00',
      courtName: 'Court Alpha',
      courtImage:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
      player: 'Karim Jaziri',
      sport: SportType.football,
      isPending: false,
    ),
    _Booking(
      id: 'b2',
      time: '09:30',
      courtName: 'Court Beta',
      courtImage:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=300&q=80',
      player: 'Nadia Ben Salah',
      sport: SportType.padel,
      isPending: false,
    ),
    _Booking(
      id: 'b3',
      time: '11:00',
      courtName: 'Court Gamma',
      courtImage:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=300&q=80',
      player: 'Mehdi Trabelsi',
      sport: SportType.basketball,
      isPending: true,
    ),
    _Booking(
      id: 'b4',
      time: '14:00',
      courtName: 'Court Alpha',
      courtImage:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
      player: 'Leila Mallouli',
      sport: SportType.tennis,
      isPending: false,
    ),
    _Booking(
      id: 'b5',
      time: '19:00',
      courtName: 'Court Delta',
      courtImage:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=300&q=80',
      player: 'Ahmed Ben Ali',
      sport: SportType.football,
      isPending: true,
    ),
  ];

  List<TournamentData> _tournaments = [
    TournamentData(
      id: 't1',
      name: 'Summer Padel Cup',
      sport: SportType.padel,
      date: 'Jun 15',
      description: 'Annual padel championship open to all levels.',
      posterUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=700&q=80',
      teams: 8,
      max: 16,
      entryFee: 60,
      prizePool: 1200,
    ),
    TournamentData(
      id: 't2',
      name: 'Friday Football 5v5',
      sport: SportType.football,
      date: 'Jun 21',
      description: 'Weekly 5-a-side league. Fast-paced, competitive.',
      posterUrl:
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=700&q=80',
      teams: 6,
      max: 8,
      entryFee: 80,
      prizePool: 2000,
    ),
    TournamentData(
      id: 't3',
      name: 'Tennis Open Singles',
      sport: SportType.tennis,
      date: 'Jul 5',
      description: 'Open singles bracket for all skill levels.',
      posterUrl:
          'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=700&q=80',
      teams: 12,
      max: 32,
      entryFee: 100,
      prizePool: 3000,
    ),
  ];

  void _confirmBooking(String id) => setState(() {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1) _bookings[i].isPending = false;
  });

  void _declineBooking(String id) => setState(() {
    _bookings.removeWhere((b) => b.id == id);
  });

  void _toggleCourt(String id) => setState(() {
    final i = _courts.indexWhere((c) => c.id == id);
    if (i != -1) _courts[i].isActive = !_courts[i].isActive;
  });

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final pending = _bookings.where((b) => b.isPending).length;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              pendingCount: pending,
              courtsActive: _courts.where((c) => c.isActive).length,
              totalCourts: _courts.length,
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, navH + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── My Courts ─────────────────────────────────────────────────
                _SectionTitle('My Courts', sub: '${_courts.length} courts'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _courts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _CourtCard(
                      court: _courts[i],
                      onToggle: () => _toggleCourt(_courts[i].id),
                      onManage: () => _openCourtManage(_courts[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Today's Schedule ──────────────────────────────────────────
                _SectionTitle(
                  "Today's Schedule",
                  sub: '${_bookings.length} bookings · $pending pending',
                  pendingBadge: pending > 0 ? pending : null,
                ),
                const SizedBox(height: 14),
                ..._bookings.map(
                  (b) => _BookingCard(
                    booking: b,
                    onTap: () => _openBookingDetail(b),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Tournaments ───────────────────────────────────────────────
                _SectionTitle(
                  'Tournaments',
                  sub: '${_tournaments.length} active',
                ),
                const SizedBox(height: 14),
                ..._tournaments.map(
                  (t) => _TournamentPosterCard(
                    tournament: t,
                    onManage: () => _openManageTournament(t),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openCourtManage(_Court court) {
    showModalBottomSheet(
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
  }

  void _openBookingDetail(_Booking b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: b,
        onConfirm: b.isPending
            ? () {
                _confirmBooking(b.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(_snack('Booking confirmed ✓', kGreen));
              }
            : null,
        onDecline: b.isPending
            ? () {
                _declineBooking(b.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(_snack('Booking declined', kRed));
              }
            : null,
      ),
    );
  }

  void _openManageTournament(TournamentData t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => manage.ManageTournamentPage(tournament: t),
      ),
    );
  }

  SnackBar _snack(String msg, Color color) => SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final int pendingCount, courtsActive, totalCourts;
  const _DashboardHeader({
    required this.pendingCount,
    required this.courtsActive,
    required this.totalCourts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Top row
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
                    child: const Center(
                      child: Icon(
                        Icons.sports_tennis,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back 👋',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                        const Text(
                          'Arena Sport Center', // Changed from "Mohamed Karim" to venue name
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
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
              const SizedBox(height: 24),

              // Venue card
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
                          const Text(
                            'Arena Sport Center',
                            style: TextStyle(
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
                                'Lac 2, Tunis',
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
                        _HeaderChip(
                          '$courtsActive/$totalCourts active',
                          Colors.white.withOpacity(0.15),
                          Colors.white,
                        ),
                        const SizedBox(height: 6),
                        if (pendingCount > 0)
                          _HeaderChip(
                            '$pendingCount pending',
                            kAmber.withOpacity(0.25),
                            kAmber,
                          )
                        else
                          _HeaderChip(
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
}

class _HeaderChip extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _HeaderChip(this.text, this.bg, this.fg);
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT CARD — no /hr, no hall, tappable → manage sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CourtCard extends StatelessWidget {
  final _Court court;
  final VoidCallback onToggle, onManage;
  const _CourtCard({
    required this.court,
    required this.onToggle,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.sport.color;
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
            // Photo
            Image.network(
              c.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: sc.withOpacity(0.12),
                child: Icon(c.sport.icon, color: sc, size: 40),
              ),
            ),

            // Gradient
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

            // Top badges
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

            // Bottom info
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
                        '${c.price.toInt()} DT',
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
                        '${c.bookingsToday} today',
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
  final _Court court;
  final VoidCallback onToggle;
  const _CourtManageSheet({required this.court, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = court;
    final sc = c.sport.color;
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
          // Photo hero
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    c.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: sc.withOpacity(0.1)),
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
                              '${c.price.toInt()} DT per session',
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
                // Stats row
                Row(
                  children: [
                    _StatBox(
                      Icons.calendar_today_rounded,
                      '${c.bookingsToday}',
                      'Today',
                      sc,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(Icons.sports_rounded, c.sport.label, 'Sport', sc),
                    const SizedBox(width: 10),
                    _StatBox(
                      Icons.attach_money_rounded,
                      '${c.price.toInt()} DT',
                      'Price',
                      sc,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _SheetBtn(
                        icon: c.isActive
                            ? Icons.pause_circle_rounded
                            : Icons.play_circle_rounded,
                        label: c.isActive ? 'Close Court' : 'Open Court',
                        color: c.isActive ? kRed : kGreen,
                        onTap: onToggle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SheetBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit Details',
                        color: kPrimary,
                        filled: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
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
// BOOKING CARD — tappable
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final _Booking booking;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final sc = b.sport.color;
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
            // Time thumbnail
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
                  Image.network(
                    b.courtImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: sc.withOpacity(0.1)),
                  ),
                  Container(color: Colors.black.withOpacity(0.35)),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Icon(
                          b.sport.icon,
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
                      b.courtName,
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
                          b.player,
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
// BOOKING DETAIL SHEET — beautiful, confirmed or confirm/decline
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailSheet extends StatelessWidget {
  final _Booking booking;
  final VoidCallback? onConfirm, onDecline;
  const _BookingDetailSheet({
    required this.booking,
    this.onConfirm,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final sc = b.sport.color;
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
          // Hero with photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    b.courtImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: sc.withOpacity(0.15),
                      child: Icon(b.sport.icon, color: sc, size: 48),
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
                // Status badge
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
                          b.sport.icon,
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
                              b.courtName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              b.time,
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
                // Player info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                            b.player.split(' ').map((e) => e[0]).take(2).join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.player,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.sport.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sc.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          b.time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: sc,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                if (b.isPending) ...[
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
                  ),
                ] else
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
// TOURNAMENT POSTER CARD — full image, no progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _TournamentPosterCard extends StatelessWidget {
  final TournamentData tournament;
  final VoidCallback onManage;
  const _TournamentPosterCard({
    required this.tournament,
    required this.onManage,
  });

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
            // Poster image
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

            // Gradient overlay
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

            // Sport badge top-left
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

            // Spots badge top-right
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

            // Bottom info
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
                            t.name,
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
                                t.date,
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
                                '${t.teams}/${t.max}',
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
// SHARED MICRO WIDGETS
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
