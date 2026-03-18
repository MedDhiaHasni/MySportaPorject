// court_booking_page.dart
// "I want to book a court" entry point
// Sport filter → court → date → time → duration → confirm sheet → success screen

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/sample_data.dart';
import 'package:sporta/Widgets/Buttons/primary_button.dart';
import 'Navigation.dart';

class CourtBookingPage extends StatefulWidget {
  final CourtModel? preselectedCourt;
  const CourtBookingPage({
    super.key,
    this.preselectedCourt,
    required String venueName,
  });
  @override
  State<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends State<CourtBookingPage> {
  SportType? _sportFilter;
  CourtModel? _court;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _time;

  @override
  void initState() {
    super.initState();
    _court = widget.preselectedCourt;
    if (_court != null) _sportFilter = _court!.sport;
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<CourtModel> get _courts => _sportFilter == null
      ? sampleCourts
      : sampleCourts.where((c) => c.sport == _sportFilter).toList();

  String get _effectiveTime => _time ?? '';

  bool get _canBook =>
      _court != null &&
      _effectiveTime.isNotEmpty &&
      RegExp(r'^\d{2}:\d{2}$').hasMatch(_effectiveTime);

  // Fixed price — no duration multiplier
  double get _total => _court?.pricePerHour ?? 0;

  CourtReservation _buildReservation(PaymentOption option) {
    final h = int.parse(_effectiveTime.split(':')[0]);
    final m = int.parse(_effectiveTime.split(':')[1]);
    final endMin = h * 60 + m + 60; // fixed 1h slot
    final eH = endMin ~/ 60;
    final eM = endMin % 60;
    return CourtReservation(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      courtId: _court!.id,
      courtName: _court!.name,
      hostId: 'p1',
      sport: _court!.sport,
      date: _date,
      startTime: _effectiveTime,
      endTime:
          '${eH.toString().padLeft(2, '0')}:${eM.toString().padLeft(2, '0')}',
      durationHours: 1.0,
      totalPrice: _total,
      paymentOption: option,
      courtImageUrl: _court!.imageUrl,
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
        court: _court!,
        date: _date,
        time: _effectiveTime,
        total: _total,
        onConfirm: (option) async {
          Navigator.pop(context); // close confirm sheet
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          final res = _buildReservation(option);
          // Go to success screen instead of MatchDetailPage
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
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: kCard,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
                child: Row(
                  children: [
                    _BackBtn(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book a Court',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Pick your court, time & duration',
                            style: TextStyle(fontSize: 12, color: kTextMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 100),
              children: [
                // ── Sport filter ─────────────────────────────────────────────
                _Label('Sport'),
                const SizedBox(height: 10),
                _SportFilterRow(
                  selected: _sportFilter,
                  onSelect: (s) => setState(() {
                    _sportFilter = s;
                    if (_court != null && _court!.sport != s) _court = null;
                  }),
                ),
                const SizedBox(height: 22),

                // ── Courts ───────────────────────────────────────────────────
                _Label('Available Courts'),
                const SizedBox(height: 10),
                ..._courts.map(
                  (c) => _CourtCard(
                    court: c,
                    selected: _court?.id == c.id,
                    onTap: () => setState(() {
                      _court = c;
                      _time = null;
                    }),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Date ─────────────────────────────────────────────────────
                _Label('Date'),
                const SizedBox(height: 10),
                _DateTile(date: _date, onTap: _pickDate),
                const SizedBox(height: 22),

                // ── Time ─────────────────────────────────────────────────────
                _Label('Start Time'),
                const SizedBox(height: 8),
                if (_court == null)
                  _Hint('Select a court first to see available times')
                else
                  _TimeGrid(
                    slots: _court!.availableTimeSlots,
                    selected: _time,
                    onSelect: (t) => setState(() {
                      _time = t;
                    }),
                  ),
                const SizedBox(height: 22),

                // ── Price preview ─────────────────────────────────────────────
                if (_court != null)
                  _PriceBanner(court: _court!, time: _effectiveTime),
              ],
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────────────
          Container(
            color: kCard,
            padding: EdgeInsets.fromLTRB(16, 12, 16, navH + 8),
            child: PrimaryButton(
              _canBook
                  ? 'Confirm Booking  ·  ${_total.toStringAsFixed(0)} DT'
                  : 'Choose court & time to continue',
              color: kPrimary,
              icon: Icons.check_circle_rounded,
              onTap: _canBook ? _showConfirm : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING SUCCESS SCREEN — replaces MatchDetailPage after court booking
// Shows court photo, booking summary, next steps
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
  late Animation<double> _scale;
  late Animation<double> _fade;

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
          // ── Hero — court photo with gradient + success badge ──────────────
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
              // Dark overlay
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
                          onTap: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
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
              // Animated success badge
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
              // Court name at bottom of hero
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

          // ── Booking details ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, navH + 16),
              children: [
                // Summary card
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
                      _divider(),
                      _Row(
                        Icons.access_time_rounded,
                        'Time',
                        '${res.startTime} – ${res.endTime}',
                        kPrimary,
                      ),
                      _divider(),
                      _Row(
                        Icons.timelapse_rounded,
                        'Duration',
                        '${res.durationHours}h',
                        kPrimary,
                      ),
                      _divider(),
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

                // Payment-specific notice
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
                              ? 'Your court is secured. A confirmation has been sent to your account. See you on the court!'
                              : 'Your slot is reserved. Please arrive a few minutes early to settle payment at the reception.',
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

                // What's next
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
                        sub: 'Let players know you need teammates',
                        onTap: () => _showAnnouncementSheet(context, res),
                      ),
                      const SizedBox(height: 10),
                      _NextTile(
                        icon: Icons.home_rounded,
                        color: kTextMid,
                        title: 'Go to Home',
                        sub: 'See your booking in Upcoming Bookings',
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => Navigation()),
                            (route) => false,
                          );
                        },
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

  Widget _divider() => Divider(height: 1, color: kBg, indent: 0, endIndent: 0);

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

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENT SHEET — posted after booking confirmation
// ─────────────────────────────────────────────────────────────────────────────
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
    // Add to global sample list (in production: API call)
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
        content: Text('Announcement posted! Players can now request to join.'),
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
                          'Tell players how many spots you need filled',
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
                  // Booking summary chip
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

                  // Players needed stepper
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
                              'How many more players do you need?',
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

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell players what level you\'re looking for, the vibe, etc.',
                    style: TextStyle(fontSize: 11, color: kTextMid),
                  ),
                  const SizedBox(height: 10),
                  _MessageInput(ctrl: _descCtrl),
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

class _NextTile extends StatefulWidget {
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
  State<_NextTile> createState() => _NextTileState();
}

class _NextTileState extends State<_NextTile> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: widget.color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                Text(
                  widget.sub,
                  style: const TextStyle(fontSize: 11, color: kTextMid),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: widget.color.withOpacity(0.5),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmSheet extends StatefulWidget {
  final CourtModel court;
  final DateTime date;
  final String time;
  final double total;
  final ValueChanged<PaymentOption> onConfirm;
  const _ConfirmSheet({
    required this.court,
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
          // handle
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

          // Court summary card with photo
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

          // Payment option
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
            title: 'Pay Now  — ${widget.total.toStringAsFixed(0)} DT online',
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

class _PayOption extends StatefulWidget {
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
  State<_PayOption> createState() => _PayOptionState();
}

class _PayOptionState extends State<_PayOption> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.selected ? widget.color.withOpacity(0.05) : kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.selected
              ? widget.color.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.sub,
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
              color: widget.selected ? widget.color : Colors.transparent,
              border: Border.all(
                color: widget.selected ? widget.color : kTextLight,
                width: 1.5,
              ),
            ),
            child: widget.selected
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : const SizedBox(),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Small local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.arrow_back_ios_rounded,
        size: 16,
        color: kTextDark,
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: kTextDark,
      letterSpacing: -0.2,
    ),
  );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: kTextLight),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: kTextMid)),
      ],
    ),
  );
}

class _SportFilterRow extends StatefulWidget {
  final SportType? selected;
  final ValueChanged<SportType?> onSelect;
  const _SportFilterRow({required this.selected, required this.onSelect});
  @override
  State<_SportFilterRow> createState() => _SportFilterRowState();
}

class _SportFilterRowState extends State<_SportFilterRow> {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _pill(null, 'All', Icons.sports_rounded),
      ...SportType.values.map((s) => _pill(s, s.label, s.icon)),
    ],
  );

  Widget _pill(SportType? sport, String label, IconData icon) {
    final sel = widget.selected == sport;
    final color = sport?.color ?? kPrimary;
    return GestureDetector(
      onTap: () => widget.onSelect(sport),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? color.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: kElevation,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: sel ? color : kTextMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? color : kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtCard extends StatefulWidget {
  final CourtModel court;
  final bool selected;
  final VoidCallback onTap;
  const _CourtCard({
    required this.court,
    required this.selected,
    required this.onTap,
  });
  @override
  State<_CourtCard> createState() => _CourtCardState();
}

class _CourtCardState extends State<_CourtCard> {
  @override
  Widget build(BuildContext context) {
    final c = widget.court;
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kElevation,
          border: Border.all(
            color: sel ? c.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Court photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: c.imageUrl != null
                    ? Image.network(
                        c.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ph(c),
                      )
                    : _ph(c),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kTextDark,
                            ),
                          ),
                        ),
                        if (sel)
                          Icon(
                            Icons.check_circle_rounded,
                            color: c.color,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.location,
                      style: const TextStyle(fontSize: 11, color: kTextMid),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.sport.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: c.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${c.pricePerHour.toStringAsFixed(0)} DT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.color,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _ph(CourtModel c) => Container(
    color: c.color.withOpacity(0.07),
    child: Icon(c.sport.icon, color: c.color.withOpacity(0.3), size: 28),
  );
}

class _DateTile extends StatefulWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.date, required this.onTap});
  @override
  State<_DateTile> createState() => _DateTileState();
}

class _DateTileState extends State<_DateTile> {
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
    final d = widget.date;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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

class _TimeGrid extends StatefulWidget {
  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _TimeGrid({
    required this.slots,
    required this.selected,
    required this.onSelect,
  });
  @override
  State<_TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<_TimeGrid> {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: widget.slots.map((t) {
      final sel = t == widget.selected;
      return GestureDetector(
        onTap: () => widget.onSelect(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? kPrimary : kCard,
            borderRadius: BorderRadius.circular(11),
            boxShadow: sel
                ? [BoxShadow(color: kPrimary.withOpacity(0.22), blurRadius: 6)]
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
      color: kPrimary.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kPrimary.withOpacity(0.12)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: kPrimary,
            size: 19,
          ),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        if (time.isNotEmpty)
          Text(time, style: const TextStyle(fontSize: 11, color: kTextMid)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE INPUT  — clean pill-style, no visible border at rest
// ─────────────────────────────────────────────────────────────────────────────
class _MessageInput extends StatefulWidget {
  final TextEditingController ctrl;
  const _MessageInput({required this.ctrl});
  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: _focused ? Colors.white : const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(16),
      boxShadow: _focused
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: TextField(
      controller: widget.ctrl,
      focusNode: _focus,
      maxLines: 5,
      minLines: 4,
      style: const TextStyle(fontSize: 13, color: kTextDark, height: 1.5),
      decoration: const InputDecoration(
        hintText: 'e.g. Friendly match, intermediate level. All welcome! 🙌',
        hintStyle: TextStyle(color: kTextLight, fontSize: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.all(16),
      ),
    ),
  );
}
