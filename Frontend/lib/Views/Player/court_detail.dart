// court_detail.dart — Views/Player/court_detail.dart
// Full court detail page: image gallery, info, then date/time/confirm booking flow

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'package:sporta/Models/venue_model.dart';
import 'Navigation.dart';

class CourtDetailPage extends StatefulWidget {
  final CourtModel court;
  final VenueModel venue;
  final Map<String, dynamic> courtData;
  const CourtDetailPage({
    super.key,
    required this.court,
    required this.venue,
    required this.courtData,
  });
  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  int _imgIndex = 0;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _time;

  // Multiple images — real app fetches from backend
  List<String> get _images {
    final primary = widget.court.imageUrl;
    if (primary != null) {
      // Simulate multiple angles of the same court
      return [
        primary,
        primary.replaceAll('?w=800', '?w=800&crop=top'),
        primary.replaceAll('?w=800', '?w=800&crop=bottom'),
      ];
    }
    return [];
  }

  bool get _canBook => _time != null && _time!.isNotEmpty;
  double get _total => widget.court.pricePerHour;

  CourtReservation _buildReservation(PaymentOption option) {
    final h = int.parse(_time!.split(':')[0]);
    final m = int.parse(_time!.split(':')[1]);
    final endMin = h * 60 + m + 60;
    final eH = endMin ~/ 60;
    final eM = endMin % 60;
    return CourtReservation(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      courtId: widget.court.id,
      courtName: widget.court.name,
      hostId: 'p1',
      sport: widget.court.sport,
      date: _date,
      startTime: _time!,
      endTime:
          '${eH.toString().padLeft(2, '0')}:${eM.toString().padLeft(2, '0')}',
      durationHours: 1.0,
      totalPrice: _total,
      paymentOption: option,
      courtImageUrl: widget.court.imageUrl,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: kPrimary),
          ),
        ),
        child: child!,
      ),
    );
    if (p != null)
      setState(() {
        _date = p;
        _time = null;
      });
  }

  void _showConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        court: widget.court,
        venue: widget.venue,
        date: _date,
        time: _time!,
        total: _total,
        onConfirm: (option) async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          final res = _buildReservation(option);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _BookingSuccessScreen(reservation: res),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.court;
    final v = widget.venue;
    final sc = c.color;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Image gallery hero ────────────────────────────────────────────────
          Stack(
            children: [
              // Image
              SizedBox(
                height: 280,
                width: double.infinity,
                child: _images.isNotEmpty
                    ? PageView.builder(
                        itemCount: _images.length,
                        onPageChanged: (i) => setState(() => _imgIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          _images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _courtPlaceholder(sc),
                        ),
                      )
                    : _courtPlaceholder(sc),
              ),
              // Gradient overlay bottom
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Image counter
                        if (_images.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_imgIndex + 1} / ${_images.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Court name at bottom of hero
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c.sport.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            v.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sc,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: sc.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${c.pricePerHour.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Dot indicators
              if (_images.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _images.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _imgIndex == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _imgIndex == i
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Scrollable content ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 100),
              children: [
                // ── Court info row ──────────────────────────────────────────────
                Row(
                  children: [
                    _InfoChip(Icons.sports_rounded, c.sport.label, sc),
                    const SizedBox(width: 8),
                    _InfoChip(
                      Icons.location_on_rounded,
                      v.location.split(',').first,
                      kTextMid,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      Icons.access_time_rounded,
                      'Until ${v.openUntil}',
                      kTextMid,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Manager quick info ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: kElevation,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, Color(0xFF007B7D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            v.managerAvatar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
                            const Text(
                              'Managed by',
                              style: TextStyle(fontSize: 10, color: kTextMid),
                            ),
                            Text(
                              v.managerName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 14,
                                color: kPrimary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Amenities ───────────────────────────────────────────────────
                const Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: v.amenities.map((a) => _AmenityChip(a)).toList(),
                ),
                const SizedBox(height: 24),

                // ── Date ────────────────────────────────────────────────────────
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _DateTile(date: _date, onTap: _pickDate),
                const SizedBox(height: 20),

                // ── Time slots ──────────────────────────────────────────────────
                const Text(
                  'Start Time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _TimeGrid(
                  slots: widget.court.availableTimeSlots,
                  selected: _time,
                  color: sc,
                  onSelect: (t) => setState(() => _time = t),
                ),
                const SizedBox(height: 20),

                // ── Price summary ───────────────────────────────────────────────
                if (_canBook) _PriceBanner(court: c, time: _time!),
              ],
            ),
          ),

          // ── Book button ────────────────────────────────────────────────────
          Container(
            color: kCard,
            padding: EdgeInsets.fromLTRB(20, 12, 20, navH + 8),
            child: PrimaryButton(
              _canBook
                  ? 'Book Now  ·  ${_total.toStringAsFixed(0)} DT'
                  : 'Select a time to continue',
              color: sc,
              icon: Icons.check_circle_rounded,
              onTap: _canBook ? _showConfirm : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courtPlaceholder(Color color) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(color, Colors.black, 0.3)!, color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Icon(
      widget.court.sport.icon,
      size: 60,
      color: Colors.white.withOpacity(0.3),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.black.withOpacity(0.07)),
      boxShadow: kElevation,
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    ),
  );
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.date, required this.onTap});

  String get _label {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kElevation,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: kPrimary,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kTextLight),
        ],
      ),
    ),
  );
}

class _TimeGrid extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelect;
  const _TimeGrid({
    required this.slots,
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: slots.map((t) {
      final sel = t == selected;
      return GestureDetector(
        onTap: () => onSelect(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color : kCard,
            borderRadius: BorderRadius.circular(11),
            boxShadow: sel
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                : kElevation,
          ),
          child: Text(
            t,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: sel ? Colors.white : kTextDark,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _PriceBanner extends StatelessWidget {
  final CourtModel court;
  final String time;
  const _PriceBanner({required this.court, required this.time});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: court.color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: court.color.withOpacity(0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: court.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.receipt_long_rounded, color: court.color, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  color: kTextMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${court.pricePerHour.toStringAsFixed(0)} DT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: court.color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
            const Text(
              '1 hour session',
              style: TextStyle(fontSize: 10, color: kTextMid),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatefulWidget {
  final CourtModel court;
  final VenueModel venue;
  final DateTime date;
  final String time;
  final double total;
  final ValueChanged<PaymentOption> onConfirm;
  const _ConfirmSheet({
    required this.court,
    required this.venue,
    required this.date,
    required this.time,
    required this.total,
    required this.onConfirm,
  });
  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  PaymentOption _option = PaymentOption.payNow;
  bool _paying = false;

  String get _dateLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = widget.date;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onConfirm(_option);
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    final sc = widget.court.sport.color;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: kTextLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Court summary
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: widget.court.imageUrl != null
                      ? Image.network(
                          widget.court.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(sc, Colors.black, 0.35)!,
                                  sc,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color.lerp(sc, Colors.black, 0.35)!, sc],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Icon(
                        widget.court.sport.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.court.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '$_dateLabel  ·  ${widget.time}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.total.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How do you want to pay?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PayOption(
            icon: Icons.bolt_rounded,
            title: 'Pay Now  —  ${widget.total.toStringAsFixed(0)} DT online',
            sub: 'Instant confirmation. Court secured right away.',
            color: kPrimary,
            selected: _option == PaymentOption.payNow,
            onTap: () => setState(() => _option = PaymentOption.payNow),
          ),
          const SizedBox(height: 8),
          _PayOption(
            icon: Icons.storefront_rounded,
            title: 'Pay at Venue',
            sub: 'Pay on match day at the facility.',
            color: kAmber,
            selected: _option == PaymentOption.payAtVenue,
            onTap: () => setState(() => _option = PaymentOption.payAtVenue),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            _option == PaymentOption.payNow
                ? 'Pay ${widget.total.toStringAsFixed(0)} DT & Confirm'
                : 'Reserve — Pay at Venue',
            color: _option == PaymentOption.payNow ? kPrimary : kAmber,
            icon: _option == PaymentOption.payNow
                ? Icons.payment_rounded
                : Icons.storefront_rounded,
            onTap: _paying ? null : _pay,
            loading: _paying,
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PayOption({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.05) : kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: kTextMid),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(
                color: selected ? color : kTextLight,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : const SizedBox(),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING SUCCESS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _BookingSuccessScreen extends StatefulWidget {
  final CourtReservation reservation;
  const _BookingSuccessScreen({required this.reservation});
  @override
  State<_BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<_BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _dateLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = widget.reservation.date;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservation;
    final sc = res.sport.color;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final isPaid = res.paymentOption == PaymentOption.payNow;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Hero
          Stack(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: res.courtImageUrl != null
                    ? Image.network(
                        res.courtImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color.lerp(sc, Colors.black, 0.4)!, sc],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color.lerp(sc, Colors.black, 0.4)!, sc],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fade,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scale,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kGreen.withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: kGreen,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Booking Confirmed!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid
                              ? 'Payment received — you\'re all set'
                              : 'Reserved — pay at the venue',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        res.sport.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.courtName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            res.sport.label,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
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

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 16),
              children: [
                Container(
                  decoration: kCardDeco(18),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _Row(
                        Icons.calendar_today_rounded,
                        'Date',
                        _dateLabel,
                        kPrimary,
                      ),
                      _div(),
                      _Row(
                        Icons.access_time_rounded,
                        'Time',
                        '${res.startTime} – ${res.endTime}',
                        kPrimary,
                      ),
                      _div(),
                      _Row(
                        Icons.timelapse_rounded,
                        'Duration',
                        '${res.durationHours}h',
                        kPrimary,
                      ),
                      _div(),
                      _Row(
                        isPaid ? Icons.bolt_rounded : Icons.storefront_rounded,
                        'Payment',
                        isPaid
                            ? '${res.totalPrice.toStringAsFixed(0)} DT — Paid online'
                            : '${res.totalPrice.toStringAsFixed(0)} DT — Pay at venue',
                        isPaid ? kGreen : kAmber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (isPaid ? kGreen : kAmber).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isPaid ? kGreen : kAmber).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.storefront_rounded,
                        size: 18,
                        color: isPaid ? kGreen : kAmber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPaid
                              ? 'Your court is secured. See you on the court!'
                              : 'Your slot is reserved. Arrive early to pay at reception.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPaid ? kGreen : kAmber,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: kCardDeco(18),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "What's next?",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _NextTile(
                        icon: Icons.campaign_rounded,
                        color: kPrimary,
                        title: 'Make an Announcement',
                        sub: 'Find teammates for this session',
                        onTap: () => _showAnnouncementSheet(context, res),
                      ),
                      const SizedBox(height: 10),
                      _NextTile(
                        icon: Icons.home_rounded,
                        color: kTextMid,
                        title: 'Go to Home',
                        sub: 'See your booking in Upcoming Bookings',
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => Navigation()),
                          (r) => false,
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
    );
  }

  Widget _div() => Divider(height: 1, color: kBg);

  Widget _Row(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: kTextMid),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextDark,
              ),
            ),
          ],
        ),
      );
}

void _showAnnouncementSheet(BuildContext context, CourtReservation res) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AnnouncementSheet(reservation: res),
  );
}

class _AnnouncementSheet extends StatefulWidget {
  final CourtReservation reservation;
  const _AnnouncementSheet({required this.reservation});
  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  int _playersNeeded = 2;
  final _descCtrl = TextEditingController();
  bool _posting = false;
  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _posting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    sampleAnnouncements.insert(
      0,
      AnnouncementModel(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        reservation: widget.reservation,
        host: samplePlayers.first,
        playersNeeded: _playersNeeded,
        description: _descCtrl.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement posted!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservation;
    final sc = res.sport.color;
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
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
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make an Announcement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Find teammates for your session',
                          style: TextStyle(fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: Colors.black.withOpacity(0.05)),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(20, 4, 20, bot + 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sc.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(res.sport.icon, size: 16, color: sc),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${res.courtName}  ·  ${res.dateLabel}  ·  ${res.startTime}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kTextDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Players needed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                            Text(
                              'How many more players?',
                              style: TextStyle(fontSize: 11, color: kTextMid),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_playersNeeded > 1)
                                setState(() => _playersNeeded--);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.remove_rounded,
                                size: 17,
                                color: kPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$_playersNeeded',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_playersNeeded < 20)
                                setState(() => _playersNeeded++);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 17,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextDark,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Friendly match, intermediate level. All welcome!',
                        hintStyle: TextStyle(color: kTextLight, fontSize: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    'Post Announcement',
                    color: kPrimary,
                    icon: Icons.campaign_rounded,
                    onTap: _posting ? null : _post,
                    loading: _posting,
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

class _NextTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  const _NextTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: kTextMid),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: color.withOpacity(0.5),
          ),
        ],
      ),
    ),
  );
}
