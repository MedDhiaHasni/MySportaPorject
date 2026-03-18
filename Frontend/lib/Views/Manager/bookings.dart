import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// bookings_page.dart
// ─────────────────────────────────────────────────────────────────────────────

List<BoxShadow> get _shadow => [
  BoxShadow(
    color: Colors.black.withOpacity(0.055),
    blurRadius: 18,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.022),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];
BoxDecoration kCard$(double r) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(r),
  boxShadow: _shadow,
);

// ─────────────────────────────────────────────────────────────────────────────
class Bookings extends StatefulWidget {
  const Bookings({super.key});
  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  int _selectedDay = 2; // default: Wednesday
  String _filter = 'All';

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _dates = [3, 4, 5, 6, 7, 8, 9];

  List<_Booking> _bookings = [
    _Booking(
      '08:00',
      '1h',
      'Court Alpha',
      'Karim Jaziri',
      false,
      kPrimary,
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
    ),
    _Booking(
      '09:30',
      '1h 30',
      'Court Beta',
      'Nadia Ben Salah',
      false,
      kPurple,
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=300&q=80',
    ),
    _Booking(
      '11:00',
      '2h',
      'Court Gamma',
      'Mehdi Trabelsi',
      true,
      kOrange,
      'https://images.unsplash.com/photo-1545809074-59472b3f5ecc?w=300&q=80',
    ),
    _Booking(
      '14:00',
      '1h',
      'Court Alpha',
      'Leila Mallouli',
      false,
      kGreen,
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=300&q=80',
    ),
    _Booking(
      '16:30',
      '1h 30',
      'Court Beta',
      'Omar Haddad',
      false,
      kPrimary,
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=300&q=80',
    ),
    _Booking(
      '19:00',
      '1h',
      'Court Delta',
      'Ahmed Ben Ali',
      true,
      kAmber,
      'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=300&q=80',
    ),
  ];

  List<_Booking> get _filtered {
    switch (_filter) {
      case 'Confirmed':
        return _bookings.where((b) => !b.isPending).toList();
      case 'Pending':
        return _bookings.where((b) => b.isPending).toList();
      default:
        return _bookings;
    }
  }

  void _approve(_Booking b) {
    setState(() {
      final i = _bookings.indexWhere((x) => x.id == b.id);
      if (i != -1) {
        _bookings[i] = _Booking(
          b.time,
          b.duration,
          b.court,
          b.player,
          false,
          b.color,
          b.courtImageUrl,
          id: b.id,
        );
      }
    });
  }

  void _decline(_Booking b) {
    setState(() => _bookings.removeWhere((x) => x.id == b.id));
  }

  void _openBookingDetails(_Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: booking,
        onApprove: booking.isPending ? () => _approve(booking) : null,
        onDecline: booking.isPending ? () => _decline(booking) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final confirmed = _bookings.where((b) => !b.isPending).length;
    final pending = _bookings.where((b) => b.isPending).length;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bookings',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '$confirmed confirmed · $pending pending',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Filter icon - kept only this
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: kTextMid,
                          ),
                        ),
                        // Removed the bell icon completely
                      ],
                    ),
                  ),

                  // ── Day strip ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final sel = i == _selectedDay;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 38,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
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

                  // ── Filter tabs ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: ['All', 'Confirmed', 'Pending'].map((f) {
                        final sel = _filter == f;
                        int? count;
                        if (f == 'Confirmed') count = confirmed;
                        if (f == 'Pending') count = pending;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : kBg,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : kTextMid,
                                    ),
                                  ),
                                  if (count != null && count > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: sel
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
                                            color: sel
                                                ? Colors.white
                                                : kPrimary,
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
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Booking list ──────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(filter: _filter)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, navBarH + 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final b = _filtered[i];
                      return _BookingCard(
                        booking: b,
                        onTap: () => _openBookingDetails(b),
                        onApprove: b.isPending ? () => _approve(b) : null,
                        onDecline: b.isPending ? () => _decline(b) : null,
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
// Booking card - Now with photo and no emojis
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatefulWidget {
  final _Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onApprove,
    this.onDecline,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -2, 0))
              : Matrix4.identity(),
          decoration: kCard$(18),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // ── Main info row with photo ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Court photo instead of time pill
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(
                          image: NetworkImage(b.courtImageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Fallback to colored container if image fails
                          },
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              b.time,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),

                    // Court + player
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.court, // No emojis now
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
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: b.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 10,
                                  color: b.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  b.player,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kTextMid,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: kTextLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${b.time} · ${b.duration}',
                                style: TextStyle(
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
                    _StatusBadge(
                      label: b.isPending ? 'Pending' : 'Confirmed',
                      color: b.isPending ? kAmber : kGreen,
                    ),
                  ],
                ),
              ),

              // ── Pending actions ──
              if (b.isPending) ...[
                Container(height: 1, color: kBg),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Decline',
                          color: kRed,
                          filled: false,
                          onTap: widget.onDecline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Approve',
                          color: kGreen,
                          filled: true,
                          onTap: widget.onApprove,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Detail Sheet - New stateful modal
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailSheet extends StatefulWidget {
  final _Booking booking;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const _BookingDetailSheet({
    required this.booking,
    this.onApprove,
    this.onDecline,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final bot = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: kCard,
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

          // Court photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    b.courtImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: b.color.withOpacity(0.2),
                      child: Icon(
                        Icons.sports_tennis,
                        color: b.color,
                        size: 40,
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
                      ),
                    ),
                  ),
                  // Time badge on photo
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${b.time} (${b.duration})',
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
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bot + 20),
            child: Column(
              children: [
                // Court and player info
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: b.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        color: b.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.court,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: kTextLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b.player,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kTextMid,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: b.isPending ? 'Pending' : 'Confirmed',
                      color: b.isPending ? kAmber : kGreen,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons for pending bookings
                if (b.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Decline',
                          color: kRed,
                          filled: false,
                          onTap: () {
                            widget.onDecline?.call();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Approve',
                          color: kGreen,
                          filled: true,
                          onTap: () {
                            widget.onApprove?.call();
                            Navigator.pop(context);
                          },
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
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: kPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            filter == 'All'
                ? 'No bookings scheduled for this day'
                : 'No ${filter.toLowerCase()} bookings for this day',
            style: const TextStyle(fontSize: 12, color: kTextMid),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withOpacity(0.3)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Model - Added id and courtImageUrl
// ─────────────────────────────────────────────────────────────────────────────
class _Booking {
  final String id;
  final String time, duration, court, player;
  final bool isPending;
  final Color color;
  final String courtImageUrl;     

  _Booking(
    this.time,
    this.duration,
    this.court,
    this.player,
    this.isPending,
    this.color,
    this.courtImageUrl, {
    String? id,
  }) : id = id ?? 'b_${DateTime.now().millisecondsSinceEpoch}_$time';
}
