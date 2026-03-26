// bookings_page.dart — Views/Manager/bookings_page.dart
// Booking logic:
//   payNow     → isPending: false — auto-confirmed, no action needed
//   payAtVenue → isPending: true  — manager calls player to verify, then confirm/decline

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart'
    show CourtReservation, PaymentOption;

// ─────────────────────────────────────────────────────────────────────────────
// MANAGER BOOKING MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ManagerBooking {
  final String id;
  final CourtReservation reservation;
  final String playerName;
  final String playerPhone;
  bool isPending; // true = payAtVenue waiting for manager call

  ManagerBooking({
    required this.id,
    required this.reservation,
    required this.playerName,
    required this.playerPhone,
    this.isPending = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────
List<ManagerBooking> _initBookings() {
  final now = DateTime.now();
  return [
    ManagerBooking(
      id: 'b1',
      playerName: 'Karim Jaziri',
      playerPhone: '+216 54 123 456',
      isPending: false, // payNow → auto-confirmed
      reservation: CourtReservation(
        id: 'r1',
        courtId: 'c1',
        courtName: 'Court Alpha',
        hostId: 'p1',
        sport: SportType.football,
        date: now,
        startTime: '08:00',
        endTime: '09:00',
        durationHours: 1,
        totalPrice: 90,
        paymentOption: PaymentOption.payNow,
        courtImageUrl:
            'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=400&q=80',
      ),
    ),
    ManagerBooking(
      id: 'b2',
      playerName: 'Nadia Ben Salah',
      playerPhone: '+216 52 234 567',
      isPending: true, // payAtVenue → pending
      reservation: CourtReservation(
        id: 'r2',
        courtId: 'c2',
        courtName: 'Padel Court A',
        hostId: 'p2',
        sport: SportType.padel,
        date: now,
        startTime: '09:30',
        endTime: '11:00',
        durationHours: 1.5,
        totalPrice: 120,
        paymentOption: PaymentOption.payAtVenue,
        courtImageUrl:
            'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400&q=80',
      ),
    ),
    ManagerBooking(
      id: 'b3',
      playerName: 'Mehdi Trabelsi',
      playerPhone: '+216 55 345 678',
      isPending: false, // payNow → auto-confirmed
      reservation: CourtReservation(
        id: 'r3',
        courtId: 'c3',
        courtName: 'Tennis Court 1',
        hostId: 'p3',
        sport: SportType.tennis,
        date: now,
        startTime: '11:00',
        endTime: '12:00',
        durationHours: 1,
        totalPrice: 105,
        paymentOption: PaymentOption.payNow,
        courtImageUrl:
            'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=400&q=80',
      ),
    ),
    ManagerBooking(
      id: 'b4',
      playerName: 'Leila Mallouli',
      playerPhone: '+216 56 456 789',
      isPending: true, // payAtVenue → pending
      reservation: CourtReservation(
        id: 'r4',
        courtId: 'c4',
        courtName: 'Basketball Hall',
        hostId: 'p4',
        sport: SportType.basketball,
        date: now,
        startTime: '14:00',
        endTime: '15:00',
        durationHours: 1,
        totalPrice: 75,
        paymentOption: PaymentOption.payAtVenue,
        courtImageUrl:
            'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=400&q=80',
      ),
    ),
    ManagerBooking(
      id: 'b5',
      playerName: 'Ahmed Ben Ali',
      playerPhone: '+216 58 567 890',
      isPending: true, // payAtVenue → pending
      reservation: CourtReservation(
        id: 'r5',
        courtId: 'c1',
        courtName: 'Court Alpha',
        hostId: 'p5',
        sport: SportType.football,
        date: now,
        startTime: '19:00',
        endTime: '20:00',
        durationHours: 1,
        totalPrice: 90,
        paymentOption: PaymentOption.payAtVenue,
        courtImageUrl:
            'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=400&q=80',
      ),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class Bookings extends StatefulWidget {
  const Bookings({super.key});
  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  late List<ManagerBooking> _bookings;
  int _selectedDay = DateTime.now().weekday - 1;
  String _filter = 'All';

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dates = [3, 4, 5, 6, 7, 8, 9];

  @override
  void initState() {
    super.initState();
    _bookings = _initBookings();
  }

  int get _confirmedCount => _bookings.where((b) => !b.isPending).length;
  int get _pendingCount => _bookings.where((b) => b.isPending).length;

  List<ManagerBooking> get _filtered {
    switch (_filter) {
      case 'Confirmed':
        return _bookings.where((b) => !b.isPending).toList();
      case 'Pending':
        return _bookings.where((b) => b.isPending).toList();
      default:
        return List.from(_bookings);
    }
  }

  void _confirm(String id) => setState(() {
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i != -1) _bookings[i].isPending = false;
  });

  void _decline(String id) =>
      setState(() => _bookings.removeWhere((b) => b.id == id));

  void _openDetail(ManagerBooking b) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingDetailSheet(
      booking: b,
      onConfirm: b.isPending
          ? () {
              Navigator.pop(context);
              _confirm(b.id);
              _snack('Booking confirmed', kGreen);
            }
          : null,
      onDecline: b.isPending
          ? () {
              Navigator.pop(context);
              _decline(b.id);
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
    ),
  );

  @override
  Widget build(BuildContext context) {
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bookings',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_confirmedCount confirmed',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: kGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '  ·  ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kTextLight,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$_pendingCount pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _pendingCount > 0
                                            ? kAmber
                                            : kTextMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: kAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kAmber.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: kAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_pendingCount to call',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Day strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final sel = i == _selectedDay;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 40,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: kPrimary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _days[i],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white.withOpacity(0.75)
                                          : kTextMid,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_dates[i]}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: sel ? Colors.white : kTextDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Filter tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        _FilterTab(
                          label: 'All',
                          selected: _filter == 'All',
                          count: null,
                          onTap: () => setState(() => _filter = 'All'),
                        ),
                        _FilterTab(
                          label: 'Confirmed',
                          selected: _filter == 'Confirmed',
                          count: _confirmedCount,
                          onTap: () => setState(() => _filter = 'Confirmed'),
                        ),
                        _FilterTab(
                          label: 'Pending',
                          selected: _filter == 'Pending',
                          count: _pendingCount,
                          onTap: () => setState(() => _filter = 'Pending'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOOKING LIST ──────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(filter: _filter)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, navH + 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final b = _filtered[i];
                      return _BookingCard(
                        booking: b,
                        onTap: () => _openDetail(b),
                        onConfirm: b.isPending ? () => _confirm(b.id) : null,
                        onDecline: b.isPending ? () => _decline(b.id) : null,
                      );
                    },
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
  final VoidCallback? onConfirm, onDecline;
  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onConfirm,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final r = b.reservation;
    final sc = r.sport.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Court photo + time
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: r.courtImageUrl != null
                              ? Image.network(
                                  r.courtImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      color: sc.withOpacity(0.12),
                                    ),
                                    child: Icon(
                                      r.sport.icon,
                                      color: sc,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: sc.withOpacity(0.12),
                                  child: Icon(
                                    r.sport.icon,
                                    color: sc,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              r.startTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: sc.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(r.sport.icon, size: 9, color: sc),
                                  const SizedBox(width: 3),
                                  Text(
                                    r.sport.label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: sc,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          r.courtName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: kTextLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                b.playerName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMid,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: kTextLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${r.startTime} – ${r.endTime} · ${r.durationHours}h',
                              style: const TextStyle(
                                fontSize: 10,
                                color: kTextLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(
                        isPending: b.isPending,
                        paymentOption: r.paymentOption,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${r.totalPrice.toInt()} DT',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Pending action strip — pay at venue bookings need manager to call + confirm
            if (b.isPending) ...[
              Container(height: 1, color: const Color(0xFFF0F2F5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  children: [
                    // Call reminder
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kAmber.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAmber.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 13, color: kAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Call ${b.playerName.split(' ').first} to confirm — ${b.playerPhone}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn('Decline', kRed, false, onDecline),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn('Confirm', kGreen, true, onConfirm),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Court photo hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    r.courtImageUrl != null
                        ? Image.network(
                            r.courtImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: sc.withOpacity(0.2)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(sc, Colors.black, 0.4)!,
                                  sc,
                                ],
                              ),
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Sport pill
                    Positioned(
                      top: 12,
                      left: 12,
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
                            Icon(r.sport.icon, size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              r.sport.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Time
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.courtName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${r.startTime} – ${r.endTime} · ${r.durationHours}h',
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
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Text(
                        '${r.totalPrice.toInt()} DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bot + 20),
            child: Column(
              children: [
                // Player card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEFF2)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Avatar initials
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [sc, sc.withOpacity(0.6)],
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
                                    fontSize: 15,
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
                            Container(
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
                          ],
                        ),
                      ),
                      // Payment banner
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
                            bottom: Radius.circular(16),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action buttons or confirmed state
                if (b.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn('Decline', kRed, false, onDecline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          'Confirm Booking',
                          kGreen,
                          true,
                          onConfirm,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreen.withOpacity(0.2)),
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
                            'Booking Confirmed',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER TAB
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  _FilterTab({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : kTextMid,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : kPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : kPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: kPrimary,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No bookings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          filter == 'All'
              ? 'No bookings scheduled for this day'
              : 'No ${filter.toLowerCase()} bookings for this day',
          style: const TextStyle(fontSize: 13, color: kTextMid),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isPending;
  final PaymentOption paymentOption;
  const _StatusBadge({required this.isPending, required this.paymentOption});

  @override
  Widget build(BuildContext context) {
    final isOnline = paymentOption == PaymentOption.payNow;
    final color = isPending ? kAmber : kGreen;
    final label = isPending ? 'Pending' : 'Confirmed';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.bolt_rounded : Icons.storefront_rounded,
              size: 10,
              color: isOnline ? kGreen : kAmber,
            ),
            const SizedBox(width: 3),
            Text(
              isOnline ? 'Online' : 'At venue',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isOnline ? kGreen : kAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const _ActionBtn(this.label, this.color, this.filled, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: filled
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: color == kGreen
                    ? [kGreen, const Color(0xFF15803D)]
                    : [color, color],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            )
          : BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    ),
  );
}
