// lib/Views/Player/court_detail_page.dart
// e5er 7aja
// Stripe online payment flow (flutter_stripe v11)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:sporta/Services/payment_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/announcement_service.dart';

//
// PALETTE
// 
const _bg        = Color(0xFFF2F4F7);
const _white     = Colors.white;
const _ink       = Color(0xFF0A0E1A);
const _textMid   = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border    = Color(0xFFE8EDF3);
const _kGreen    = Color(0xFF16A34A);
const _kRed      = Color(0xFFDC2626);
const _kAmber    = Color(0xFFF59E0B);

// 
// PAGE
// 
class CourtDetailPage extends StatefulWidget {
  final CourtModel court;
  final VenueModel venue;
  final Map<String, dynamic> courtRaw;
  final String? playerToken;

  const CourtDetailPage({
    super.key,
    required this.court,
    required this.venue,
    required this.courtRaw,
    required this.playerToken,
  });

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  DateTime              _date         = DateTime.now().add(const Duration(days: 1));
  List<DayPlanSummary>  _dayPlans     = [];
  DayAvailability?      _availability;
  AvailabilitySlot?     _selected;
  bool                  _loadingSlots = false;
  String?               _slotsError;
  bool                  _booking      = false;

  late final ReservationService _svc;

  @override
  void initState() {
    super.initState();
    _svc = ReservationService(token: widget.playerToken ?? '');
    if (widget.playerToken?.isNotEmpty == true) _loadDayPlans();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadDayPlans() async {
    setState(() { _loadingSlots = true; _slotsError = null; });
    try {
      final plans = await _svc.fetchDayPlansForCourt(widget.venue.id);
      setState(() { _dayPlans = plans; _loadingSlots = false; });
      _loadSlotsForDate(_date);
    } catch (e) {
      setState(() { _slotsError = e.toString().replaceAll('Exception: ', ''); _loadingSlots = false; });
    }
  }

  void _loadSlotsForDate(DateTime date) async {
    final ds   = DateFormat('yyyy-MM-dd').format(date);
    final plan = _dayPlans.firstWhere(
      (p) => p.date == ds,
      orElse: () => DayPlanSummary(id: -1, date: '', dayOfWeek: '', dayType: ''),
    );
    if (plan.id == -1) { setState(() { _availability = null; _selected = null; }); return; }
    if (plan.dayType == 'day_off') {
      setState(() {
        _availability = DayAvailability(date: ds, dayType: 'day_off', slots: []);
        _selected     = null;
      });
      return;
    }
    setState(() { _loadingSlots = true; _slotsError = null; _selected = null; });
    try {
      final a = await _svc.fetchAvailability(plan.id);
      setState(() { _availability = a; _loadingSlots = false; });
    } catch (e) {
      setState(() { _slotsError = e.toString().replaceAll('Exception: ', ''); _loadingSlots = false; });
    }
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimary, onPrimary: Colors.white),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: kPrimary)),
        ),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() { _date = p; _selected = null; });
      _loadSlotsForDate(p);
    }
  }

  // ── Payment sheet ─────────────────────────────────────────────────────────

  void _showPaySheet() {
    if (_selected == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaySheet(
        court: widget.court,
        slot: _selected!,
        date: _date,
        onConfirm: _handleBooking,
      ),
    );
  }

  Future<void> _handleBooking(String method) async {
    Navigator.pop(context);
    if (method == 'pay_now') {
      await _bookAndPayOnline();
    } else {
      await _bookPayAtVenue();
    }
  }

  // ── Pay at venue ──────────────────────────────────────────────────────────

  Future<void> _bookPayAtVenue() async {
    setState(() => _booking = true);
    try {
      final courtId = int.tryParse(widget.courtRaw['id']?.toString() ?? '') ?? 0;
      final result  = await _svc.createReservation(
        timeSlotId:      _selected!.id,
        courtId:         courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(_date),
        startTime:       _selected!.startTime,
        endTime:         _selected!.endTime,
        durationHours:   1.0,
        totalPrice:      widget.court.pricePerHour,
        paymentMethod:   'pay_at_venue',
      );
      if (!mounted) return;
      setState(() => _booking = false);
      _goSuccess(result, 'pay_at_venue', 'pending');
    } catch (e) {
      setState(() => _booking = false);
      if (mounted) _showErr(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
// REPLACE only the _bookAndPayOnline() method in court_detail_page.dart
// Everything else in your file stays exactly the same.
// ─────────────────────────────────────────────────────────────────────────────

  Future<void> _bookAndPayOnline() async {
    setState(() => _booking = true);

    try {
      // ── Step 1: Create reservation ────────────────────────────────────────
      final courtId = int.tryParse(widget.courtRaw['id']?.toString() ?? '') ?? 0;
      final result = await _svc.createReservation(
        timeSlotId:      _selected!.id,
        courtId:         courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(_date),
        startTime:       _selected!.startTime,
        endTime:         _selected!.endTime,
        durationHours:   1.0,
        totalPrice:      widget.court.pricePerHour,
        paymentMethod:   'pay_now',
      );

      if (!mounted) return;

      // ── Step 2: Create PaymentIntent via backend ──────────────────────────
      final paymentSvc   = PaymentService(token: widget.playerToken ?? '');
      final intentResult = await paymentSvc.createIntent(result.reservationId.toString());

      if (!mounted) return;

      if (!intentResult.success || intentResult.clientSecret == null) {
        setState(() => _booking = false);
        _showErr(intentResult.error ?? 'Could not initialize payment');
        return;
      }

      // ── Step 3: Init Stripe payment sheet ─────────────────────────────────
      setState(() => _booking = false);

      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: intentResult.clientSecret!,
            merchantDisplayName: 'Sporta',

            // Pre-fill billing address to Tunisia
            billingDetails: const BillingDetails(
              address: Address(
                country: 'TN',
                city: null,
                line1: null,
                line2: null,
                postalCode: null,
                state: null,
              ),
            ),

            // Collect billing address so TN is pre-selected
            billingDetailsCollectionConfiguration:
                const BillingDetailsCollectionConfiguration(
              address: AddressCollectionMode.automatic,
              email:   CollectionMode.automatic,
              name:    CollectionMode.automatic,
              phone:   CollectionMode.never,
            ),

            // Light theme
            style: ThemeMode.light,

            // Custom appearance — matches kPrimary green
            appearance: PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primary:             const Color(0xFF16A34A),
                background:          const Color(0xFFF2F4F7),
                componentBackground: Colors.white,
                placeholderText:     const Color(0xFFB0B7C3),
                primaryText:         const Color(0xFF0D0D0D),
                secondaryText:       const Color(0xFF6B7280),
              ),
              shapes: const PaymentSheetShape(
                borderWidth: 1,
                shadow: PaymentSheetShadowParams(opacity: 0.05),
              ),
              primaryButton: PaymentSheetPrimaryButtonAppearance(
                colors: PaymentSheetPrimaryButtonTheme(
                  light: PaymentSheetPrimaryButtonThemeColors(
                    background: const Color(0xFF16A34A),
                    text:       Colors.white,
                    border:     const Color(0xFF16A34A),
                  ),
                ),
              ),
            ),
          ),
        );

        // ── Step 4: Present the sheet ───────────────────────────────────────
        await Stripe.instance.presentPaymentSheet();

      } on StripeException catch (e) {
        if (e.error.code == FailureCode.Canceled) {
          // User dismissed — not an error, just return silently
          return;
        }
        if (mounted) _showErr('Payment failed: ${e.error.localizedMessage ?? e.error.message}');
        return;
      } catch (e) {
        if (mounted) _showErr('Payment failed: ${e.toString().split('\n')[0]}');
        return;
      }

      // ── Step 5: Confirm with backend ──────────────────────────────────────
      if (!mounted) return;
      setState(() => _booking = true);

      final confirmResult = await paymentSvc.confirmPayment(intentResult.paymentId!);

      if (!mounted) return;
      setState(() => _booking = false);

      if (confirmResult.success && confirmResult.status == 'succeeded') {
        _goSuccess(result, 'pay_now', 'confirmed');
      } else {
        _showErr(confirmResult.message ?? confirmResult.error ?? 'Payment confirmation failed');
      }

    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        _showErr(e.toString().split('\n')[0]);
      }
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goSuccess(BookingResult result, String paymentMethod, String effectiveStatus) {
    final displayDate = DateFormat('EEE, d MMM').format(_date);
    final localBooking = LocalBooking(
      id:            result.reservationId.toString(),
      courtName:     widget.court.name,
      venueName:     widget.venue.name,
      courtImageUrl: widget.court.imageUrl ?? '',
      sport:         widget.court.sport.label,
      date:          displayDate,
      dateRaw:       DateFormat('yyyy-MM-dd').format(_date),
      time:          '${result.startTime} – ${result.endTime}',
      price:         result.totalPrice.toInt(),
      status:        effectiveStatus,
      reference:     result.bookingReference,
      paymentMethod: paymentMethod,
    );
    BookingStore.instance.addBooking(localBooking);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _SuccessPage(
        court:           widget.court,
        venue:           widget.venue,
        result:          result,
        date:            _date,
        paymentMethod:   paymentMethod,
        effectiveStatus: effectiveStatus,
        localBooking:    localBooking,
        playerToken:     widget.playerToken,
      )),
    );
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navH    = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final canBook = _selected != null && !_booking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(children: [
          _CourtHero(court: widget.court, venue: widget.venue, courtRaw: widget.courtRaw),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 100),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _InfoPill(widget.court.sport.label, widget.court.sport.icon, widget.court.color),
                    const SizedBox(width: 8),
                    _InfoPill(widget.venue.location.split(',').first, Icons.location_on_rounded, _textMid),
                    const SizedBox(width: 8),
                    _InfoPill('Open until ${widget.venue.openUntil}', Icons.schedule_rounded, _textMid),
                  ]),
                ),
                const SizedBox(height: 24),
                _PhotoGallery(courtRaw: widget.courtRaw),
                const SizedBox(height: 24),
                _SectionHeader('Select Date', Icons.calendar_today_rounded),
                const SizedBox(height: 10),
                _DateCard(date: _date, onTap: _pickDate),
                const SizedBox(height: 24),
                _SectionHeader('Available Slots', Icons.access_time_rounded),
                const SizedBox(height: 10),
                _SlotsPanel(
                  loading:  _loadingSlots,
                  error:    _slotsError,
                  availability: _availability,
                  selected: _selected,
                  hasToken: widget.playerToken?.isNotEmpty == true,
                  onSelect: (s) => setState(() => _selected = s),
                  onRetry:  () => _loadSlotsForDate(_date),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 24),
                  _PriceBanner(court: widget.court, slot: _selected!),
                ],
              ],
            ),
          ),
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(20, 14, 20, navH + 14),
            child: _BookCTA(
              canBook: canBook,
              booking: _booking,
              price:   widget.court.pricePerHour,
              onTap:   _showPaySheet,
            ),
          ),
        ]),
      ),
    );
  }
}

// 
// PAYMENT SHEET WIDGET (rest of the widgets remain the same)
// 
class _PaySheet extends StatefulWidget {
  final CourtModel court;
  final AvailabilitySlot slot;
  final DateTime date;
  final Future<void> Function(String) onConfirm;
  const _PaySheet({required this.court, required this.slot, required this.date, required this.onConfirm});
  @override State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String _method = 'pay_at_venue';
  bool   _paying = false;

  @override
  Widget build(BuildContext context) {
    final bot    = MediaQuery.of(context).padding.bottom;
    final isPay  = _method == 'pay_now';
    final accent = isPay ? kPrimary : _kAmber;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 24),
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 52, height: 52,
              child: widget.court.imageUrl != null && widget.court.imageUrl!.isNotEmpty
                  ? Image.network(widget.court.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _sportIcon(widget.court))
                  : _sportIcon(widget.court))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.court.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 3),
              Text(
                '${DateFormat('EEE, d MMM').format(widget.date)}  ·  ${widget.slot.startTime} – ${widget.slot.endTime}',
                style: const TextStyle(fontSize: 11, color: _textMid),
              ),
            ])),
            const SizedBox(width: 8),
            Text('${widget.court.pricePerHour.toInt()} DT',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
          ]),
        ),
        const SizedBox(height: 22),

        const Align(alignment: Alignment.centerLeft,
          child: Text('Choose payment method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink))),
        const SizedBox(height: 12),

        _PayOption(
          icon:     Icons.credit_card_rounded,
          title:    'Pay Online Now',
          subtitle: 'Secure card payment via Stripe — instant confirmation',
          tag:      'CONFIRMED',
          tagColor: _kGreen,
          color:    kPrimary,
          selected: _method == 'pay_now',
          badge:    '🔒 Stripe',
          onTap:    () => setState(() => _method = 'pay_now'),
        ),
        const SizedBox(height: 10),

        _PayOption(
          icon:     Icons.storefront_rounded,
          title:    'Pay at Venue',
          subtitle: 'Reservation held — pay cash on arrival',
          tag:      'PENDING',
          tagColor: _kAmber,
          color:    _kAmber,
          selected: _method == 'pay_at_venue',
          badge:    null,
          onTap:    () => setState(() => _method = 'pay_at_venue'),
        ),
        const SizedBox(height: 24),

        GestureDetector(
          onTap: _paying ? null : () async {
            setState(() => _paying = true);
            await widget.onConfirm(_method);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 56,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
            ),
            child: Center(child: _paying
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isPay ? Icons.credit_card_rounded : Icons.store_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isPay
                          ? 'Pay ${widget.court.pricePerHour.toInt()} DT with Stripe'
                          : 'Reserve — Pay at Venue',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ])),
          ),
        ),

        if (_method == 'pay_now') ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_rounded, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('256-bit SSL encrypted · Powered by Stripe',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ],
      ]),
    );
  }

  Widget _sportIcon(CourtModel c) => Container(
    color: kPrimary.withOpacity(0.08),
    child: Icon(c.sport.icon, color: kPrimary, size: 22));
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, tag;
  final String? badge;
  final Color tagColor, color;
  final bool selected;
  final VoidCallback onTap;
  const _PayOption({required this.icon, required this.title, required this.subtitle, required this.tag, required this.tagColor, required this.color, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: selected ? color.withOpacity(0.05) : _bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? color.withOpacity(0.5) : _border, width: selected ? 1.5 : 1)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
              child: Text(tag, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: tagColor, letterSpacing: 0.5))),
            if (badge != null) ...[const SizedBox(width: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5)),
                child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600])))],
          ]),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _textMid)),
        ])),
        AnimatedContainer(duration: const Duration(milliseconds: 180), width: 22, height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? color : Colors.transparent,
            border: Border.all(color: selected ? color : _textLight, width: 1.5)),
          child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null),
      ])));
}

// Keep all the other widgets (_SuccessPage, _CourtHero, _PhotoGallery, etc.)
// from your original file - they remain unchanged

// For brevity, I'm including only the essential widgets above.
// Make sure to keep your existing _SuccessPage, _CourtHero, _PhotoGallery,
// _InfoPill, _DateCard, _SlotsPanel, _SlotTile, _PriceBanner, _BookCTA,
// _SectionHeader, _AnnouncementSheet, _PerforationPainter from your original file.
// 
// SUCCESS PAGE
// 
class _SuccessPage extends StatelessWidget {
  final CourtModel court; final VenueModel venue;
  final BookingResult result; final DateTime date;
  final String paymentMethod, effectiveStatus;
  final LocalBooking localBooking; final String? playerToken;

  const _SuccessPage({
    required this.court, required this.venue, required this.result,
    required this.date, required this.paymentMethod, required this.effectiveStatus,
    required this.localBooking, required this.playerToken,
  });

  bool get _isPaid => effectiveStatus == 'confirmed';
  Color get _sc    => _isPaid ? _kGreen : _kAmber;

  void _showAnnouncementSheet(BuildContext context) => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _AnnouncementSheet(booking: localBooking, court: court, playerToken: playerToken));

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light,
      child: Scaffold(backgroundColor: _bg,
        body: Column(children: [
          // Hero
          SizedBox(height: 320, child: Stack(fit: StackFit.expand, children: [
            court.imageUrl != null
                ? Image.network(court.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroBg())
                : _heroBg(),
            Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.82)]))),
            // Close
            Positioned(top: 0, left: 0, child: SafeArea(bottom: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                child: GestureDetector(onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15))),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)))))),
            // Status icon
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 76, height: 76,
                decoration: BoxDecoration(color: _white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _sc.withOpacity(0.5), blurRadius: 28, spreadRadius: 6)]),
                child: Icon(_isPaid ? Icons.check_rounded : Icons.hourglass_top_rounded, color: _sc, size: 38)),
              const SizedBox(height: 16),
              Text(_isPaid ? 'Booking Confirmed!' : 'Reservation Pending',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(_isPaid ? 'Payment received — see you on the court!' : 'Pay at the venue when you arrive',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
            ])),
            // Reference
            Positioned(bottom: 16, left: 20, right: 20, child: Row(children: [
              Icon(court.sport.icon, color: Colors.white60, size: 15), const SizedBox(width: 7),
              Expanded(child: Text(court.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: Text(result.bookingReference,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2))),
            ])),
          ])),

          // Body
          Expanded(child: ListView(padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20), children: [
            // Ticket
            _TicketCard(result: result, date: date, status: effectiveStatus, sc: _sc, isPaid: _isPaid,
              paymentMethod: paymentMethod),
            const SizedBox(height: 16),

            // Status note
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _sc.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sc.withOpacity(0.2))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_isPaid ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 16, color: _sc),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _isPaid
                      ? 'Your slot is confirmed and secured. The court is ready for you!'
                      : 'Your slot is reserved. Please arrive 10 minutes early and pay at reception.',
                  style: TextStyle(fontSize: 12, color: _sc, height: 1.5, fontWeight: FontWeight.w600))),
              ])),
            const SizedBox(height: 16),

            // Teammates
            if (!BookingStore.instance.hasAnnouncementForReservation(localBooking.id))
              GestureDetector(onTap: () => _showAnnouncementSheet(context),
                child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.04)]),
                    borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(0.2))),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Need teammates?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                      SizedBox(height: 2),
                      Text('Post an announcement to find players', style: TextStyle(fontSize: 11, color: _textMid)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _textMid),
                  ]))),
            const SizedBox(height: 12),

            // Home button
            GestureDetector(onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Container(height: 54,
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.home_rounded, size: 18, color: Colors.white), SizedBox(width: 8),
                  Text('Back to Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ]))),
          ])),
        ])));
  }

  Widget _heroBg() => Container(decoration: BoxDecoration(gradient: LinearGradient(
    colors: [Color.lerp(court.color, Colors.black, 0.5)!, court.color],
    begin: Alignment.topLeft, end: Alignment.bottomRight)));
}

// 
// TICKET CARD
// 
class _TicketCard extends StatelessWidget {
  final BookingResult result; final DateTime date;
  final String status, paymentMethod; final Color sc; final bool isPaid;
  const _TicketCard({required this.result, required this.date, required this.status, required this.sc, required this.isPaid, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final paymentLabel = isPaid
        ? '${result.totalPrice.toInt()} DT · Paid online via Stripe'
        : '${result.totalPrice.toInt()} DT · Pay at venue';

    return Container(
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          _TRow(Icons.calendar_today_rounded, 'Date', DateFormat('EEEE, d MMMM yyyy').format(date), kPrimary),
          const SizedBox(height: 14),
          _TRow(Icons.access_time_rounded, 'Time', '${result.startTime} – ${result.endTime}', kPrimary),
          const SizedBox(height: 14),
          _TRow(Icons.payments_rounded, 'Payment', paymentLabel, sc),
        ])),
        SizedBox(height: 24, child: CustomPaint(painter: _PerforationPainter(), size: const Size(double.infinity, 24))),
        Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          _TRow(Icons.tag_rounded, 'Reference', result.bookingReference, _textMid),
          const SizedBox(height: 14),
          Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(isPaid ? Icons.verified_rounded : Icons.pending_rounded, size: 14, color: sc)),
            const SizedBox(width: 12),
            const Text('Status', style: TextStyle(fontSize: 13, color: _textMid)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sc, letterSpacing: 0.5)),
              ])),
          ]),
        ])),
      ]),
    );
  }
}

class _TRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _TRow(this.icon, this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(fontSize: 13, color: _textMid)),
    const Spacer(),
    Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink), textAlign: TextAlign.right)),
  ]);
}

// 
// COURT HERO WITH FIXED BACK BUTTON
// 
class _CourtHero extends StatelessWidget {
  final CourtModel court; final VenueModel venue; final Map<String, dynamic> courtRaw;
  const _CourtHero({required this.court, required this.venue, required this.courtRaw});

  String _mainImg() {
    String b(String? p) { if (p == null || p.isEmpty) return ''; if (p.startsWith('http')) return p; return '${ApiConstants.mediaBaseUrl}$p'; }
    final u = courtRaw['court_img_url']?.toString(); if (u != null && u.isNotEmpty) return b(u);
    if (courtRaw['court_img'] is Map) return b(courtRaw['court_img']['url']?.toString());
    if (courtRaw['photos'] is List && (courtRaw['photos'] as List).isNotEmpty) { final f = (courtRaw['photos'] as List).first; if (f is Map) return b(f['url']?.toString()); }
    return court.imageUrl ?? '';
  }

  @override Widget build(BuildContext context) {
    final img = _mainImg();
    return Stack(children: [
      Container(height: 280, width: double.infinity, decoration: BoxDecoration(color: court.color, image: img.isNotEmpty ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null),
        child: img.isEmpty ? Center(child: Icon(court.sport.icon, size: 64, color: Colors.white.withOpacity(0.3))) : null),
      Container(height: 280, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33000000), Color(0xB3000000)], stops: [0.3, 0.7]))),
      // Fixed back button - smaller and at top left
      Positioned(
        top: 0,
        left: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ),
      Positioned(bottom: 20, left: 20, right: 20, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kPrimary.withOpacity(0.85), borderRadius: BorderRadius.circular(6)), child: Text(court.sport.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5))),
          const SizedBox(height: 6),
          Text(court.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6, height: 1.1)),
          const SizedBox(height: 4),
          Text(venue.name, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
        ])),
        const SizedBox(width: 16),
        Container(padding: const EdgeInsets.fromLTRB(14, 8, 14, 8), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Column(children: [
            Text('${court.pricePerHour.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            const Text('DT / h', style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
          ])),
      ])),
    ]);
  }
}

class _PhotoGallery extends StatefulWidget {
  final Map<String, dynamic> courtRaw;
  const _PhotoGallery({required this.courtRaw});
  @override State<_PhotoGallery> createState() => _PhotoGalleryState();
}
class _PhotoGalleryState extends State<_PhotoGallery> {
  List<String> _urls = [];
  @override void initState() { super.initState(); _extract(); }
  void _extract() {
    final urls = <String>[];
    String b(String? p) { if (p == null || p.isEmpty) return ''; if (p.startsWith('http')) return p; return '${ApiConstants.mediaBaseUrl}$p'; }
    final pu = widget.courtRaw['photos_urls']; if (pu is List) for (final p in pu) { final u = b(p.toString()); if (u.isNotEmpty && !urls.contains(u)) urls.add(u); }
    final ph = widget.courtRaw['photos']; if (ph is List) for (final p in ph) { if (p is Map) { final u = b(p['url']?.toString()); if (u.isNotEmpty && !urls.contains(u)) urls.add(u); } }
    _urls = urls;
  }
  void _open(int i) => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero, child: Stack(children: [
    PageView.builder(controller: PageController(initialPage: i), itemCount: _urls.length, itemBuilder: (_, idx) => GestureDetector(onTap: () => Navigator.pop(context), child: Container(color: Colors.black, child: Center(child: InteractiveViewer(child: Image.network(_urls[idx], fit: BoxFit.contain, loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: kPrimary)))))))),
    Positioned(top: 40, right: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 24)))),
  ])));
  @override Widget build(BuildContext context) {
    if (_urls.length < 2) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.photo_library_rounded, size: 14, color: kPrimary)),
        const SizedBox(width: 10),
        const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('${_urls.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary))),
      ]),
      const SizedBox(height: 12),
      SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _urls.length, physics: const BouncingScrollPhysics(), itemBuilder: (_, i) => GestureDetector(onTap: () => _open(i), child: Padding(padding: EdgeInsets.only(right: i == _urls.length - 1 ? 0 : 12), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [
        Image.network(_urls[i], width: 280, height: 200, fit: BoxFit.cover, loadingBuilder: (_, child, p) => p == null ? child : Container(width: 280, height: 200, color: _bg, child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)))), errorBuilder: (_, __, ___) => Container(width: 280, height: 200, color: _bg, child: Icon(Icons.broken_image, size: 32, color: _textLight))),
        Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.tap_and_play, size: 12, color: Colors.white), SizedBox(width: 4), Text('Tap to view', style: TextStyle(fontSize: 10, color: Colors.white))]))),
      ])))))),
    ]);
  }
}

class _InfoPill extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _InfoPill(this.label, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.15))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))]));
}

class _DateCard extends StatelessWidget {
  final DateTime date; final VoidCallback onTap;
  const _DateCard({required this.date, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]), child: Row(children: [
    Container(width: 52, height: 52, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)), Text('${date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1))])),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('EEEE').format(date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)), const SizedBox(height: 2), Text(DateFormat('d MMMM yyyy').format(date), style: const TextStyle(fontSize: 12, color: _textMid))])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_calendar_rounded, size: 13, color: kPrimary), SizedBox(width: 5), Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary))])),
  ])));
}

class _SlotsPanel extends StatelessWidget {
  final bool loading, hasToken; final String? error; final DayAvailability? availability; final AvailabilitySlot? selected; final ValueChanged<AvailabilitySlot> onSelect; final VoidCallback onRetry;
  const _SlotsPanel({required this.loading, required this.error, required this.availability, required this.selected, required this.hasToken, required this.onSelect, required this.onRetry});
  @override Widget build(BuildContext context) {
    if (!hasToken) return _card(Icons.lock_outline_rounded, 'Sign in to see available slots', isInfo: true);
    if (loading) return const _SlotsShimmer();
    if (error != null) return _card(Icons.wifi_off_rounded, error!, isError: true, retry: onRetry);
    if (availability == null) return _card(Icons.event_busy_rounded, 'No schedule found for this date');
    if (availability!.dayType == 'day_off') return _card(Icons.beach_access_rounded, 'Day off — venue is closed');
    final all = availability!.slots;
    if (all.isEmpty) return _card(Icons.access_time_rounded, 'No time slots configured for this day');
    if (availability!.dayType == 'urgent_only') return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _kAmber.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kAmber.withOpacity(0.3))), child: const Row(children: [Icon(Icons.warning_amber_rounded, size: 16, color: _kAmber), SizedBox(width: 10), Expanded(child: Text('Urgent bookings only today', style: TextStyle(fontSize: 13, color: _kAmber, fontWeight: FontWeight.w600)))]));
    final avail = all.where((s) => s.isAvailable).toList(); final booked = all.where((s) => !s.isAvailable).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (avail.isNotEmpty) ...[Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)), const SizedBox(width: 7), Text('${avail.length} slot${avail.length == 1 ? '' : 's'} available', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen))]), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: avail.map((s) => _SlotTile(slot: s, selected: selected?.id == s.id, onTap: () => onSelect(s))).toList())],
      if (booked.isNotEmpty) ...[const SizedBox(height: 18), Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: _textLight, shape: BoxShape.circle)), const SizedBox(width: 7), const Text('Already booked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMid))]), const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: booked.map((s) => _SlotTile(slot: s, selected: false, onTap: null)).toList())],
    ]);
  }
  Widget _card(IconData icon, String text, {bool isError = false, bool isInfo = false, VoidCallback? retry}) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isError ? _kRed.withOpacity(0.25) : _border)), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: (isError ? _kRed : kPrimary).withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isError ? _kRed : _textMid, size: 17)), const SizedBox(width: 12), Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isError ? _kRed : _textMid))), if (retry != null) GestureDetector(onTap: retry, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)), child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))))]));
}

class _SlotTile extends StatelessWidget {
  final AvailabilitySlot slot; final bool selected; final VoidCallback? onTap;
  const _SlotTile({required this.slot, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) {
    final a = slot.isAvailable;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(color: selected ? kPrimary : a ? _white : _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? kPrimary : a ? _border : _border.withOpacity(0.5), width: selected ? 1.5 : 1), boxShadow: selected ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))] : a ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)] : []),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(slot.startTime, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? Colors.white : a ? _ink : _textLight)),
        const SizedBox(height: 1),
        Text('→ ${slot.endTime}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: selected ? Colors.white70 : a ? _textMid : _textLight.withOpacity(0.6))),
        if (!a) ...[const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Taken', style: TextStyle(fontSize: 8, color: _kRed, fontWeight: FontWeight.w700)))],
        if (selected) ...[const SizedBox(height: 4), const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white)],
      ])));
  }
}

class _SlotsShimmer extends StatefulWidget { const _SlotsShimmer(); @override State<_SlotsShimmer> createState() => _SlotsShimmerState(); }
class _SlotsShimmerState extends State<_SlotsShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => Wrap(spacing: 10, runSpacing: 10, children: List.generate(6, (_) => Container(width: 80, height: 58, decoration: BoxDecoration(color: Color.lerp(_white, _border, _c.value), borderRadius: BorderRadius.circular(14))))));
}

class _PriceBanner extends StatelessWidget {
  final CourtModel court; final AvailabilitySlot slot;
  const _PriceBanner({required this.court, required this.slot});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPrimary.withOpacity(0.18))),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: kPrimary, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _textMid, letterSpacing: 1.5)), Text('${court.pricePerHour.toInt()} DT', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kPrimary, height: 1.1))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)), child: Text('${slot.startTime} – ${slot.endTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))), const SizedBox(height: 4), const Text('1 hour · 1 court', style: TextStyle(fontSize: 10, color: _textMid))]),
    ]));
}

class _BookCTA extends StatelessWidget {
  final bool canBook, booking; final double price; final VoidCallback onTap;
  const _BookCTA({required this.canBook, required this.booking, required this.price, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: canBook ? onTap : null,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 56,
      decoration: BoxDecoration(color: canBook ? kPrimary : _border, borderRadius: BorderRadius.circular(16), boxShadow: canBook ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 5))] : []),
      child: Center(child: booking ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(canBook ? Icons.check_circle_rounded : Icons.touch_app_rounded, size: 18, color: canBook ? Colors.white : _textMid),
              const SizedBox(width: 9),
              Text(canBook ? 'Book Now · ${price.toInt()} DT' : 'Select a time slot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: canBook ? Colors.white : _textMid)),
            ]))));
}

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader(this.title, this.icon);
  @override Widget build(BuildContext context) => Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: kPrimary)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2))]);
}

class _AnnouncementSheet extends StatefulWidget {
  final LocalBooking booking; final CourtModel court; final String? playerToken;
  const _AnnouncementSheet({required this.booking, required this.court, this.playerToken});
  @override State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}
class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  int _playersNeeded = 2; final _descCtrl = TextEditingController(); bool _posting = false;
  late AnnouncementService _announcementService;
  @override void initState() { super.initState(); if (widget.playerToken != null) _announcementService = AnnouncementService(token: widget.playerToken!); }
  @override void dispose() { _descCtrl.dispose(); super.dispose(); }
  Future<void> _post() async {
    if (_descCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description'), behavior: SnackBarBehavior.floating)); return; }
    if (widget.playerToken == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post'), behavior: SnackBarBehavior.floating)); return; }
    setState(() => _posting = true);
    try {
      await _announcementService.create(reservationId: widget.booking.id, description: _descCtrl.text.trim(), playersNeeded: _playersNeeded);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.campaign_rounded, color: Colors.white, size: 16), SizedBox(width: 8), Expanded(child: Text('Announcement posted!', style: TextStyle(fontWeight: FontWeight.w600)))]), backgroundColor: kPrimary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    } catch (e) { setState(() => _posting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: _kRed, behavior: SnackBarBehavior.floating)); }
  }
  @override Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(initialChildSize: 0.82, minChildSize: 0.5, maxChildSize: 0.92, expand: false,
      builder: (_, ctrl) => Container(decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: Column(children: [
        const SizedBox(height: 12), Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 18),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.campaign_rounded, color: kPrimary, size: 20)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Make an Announcement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)), Text('Find teammates for your session', style: TextStyle(fontSize: 12, color: _textMid))]))])),
        const SizedBox(height: 16), Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: _border),
        Expanded(child: ListView(controller: ctrl, padding: EdgeInsets.fromLTRB(20, 18, 20, bot + 20), children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPrimary.withOpacity(0.15))), child: Row(children: [Icon(widget.court.sport.icon, size: 16, color: kPrimary), const SizedBox(width: 10), Expanded(child: Text('${widget.booking.courtName}  ·  ${widget.booking.date}  ·  ${widget.booking.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)))])),
          const SizedBox(height: 22),
          Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Players needed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)), SizedBox(height: 2), Text('How many more players?', style: TextStyle(fontSize: 11, color: _textMid))])),
            Container(decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)), child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(onTap: () { if (_playersNeeded > 1) setState(() => _playersNeeded--); }, child: Container(width: 40, height: 40, child: Icon(Icons.remove_rounded, size: 16, color: _playersNeeded > 1 ? kPrimary : _textLight))),
              Text('$_playersNeeded', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              GestureDetector(onTap: () { if (_playersNeeded < 20) setState(() => _playersNeeded++); }, child: Container(width: 40, height: 40, child: const Icon(Icons.add_rounded, size: 16, color: kPrimary))),
            ]))]),
          const SizedBox(height: 22),
          const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)), const SizedBox(height: 8),
          Container(decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)), child: TextField(controller: _descCtrl, maxLines: 4, minLines: 4, style: const TextStyle(fontSize: 14, color: _ink, height: 1.5), decoration: const InputDecoration(hintText: 'e.g. Friendly match, all welcome!', hintStyle: TextStyle(color: _textLight, fontSize: 13), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.all(16)))),
          const SizedBox(height: 24),
          GestureDetector(onTap: _posting ? null : _post, child: Container(height: 54, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))]), child: Center(child: _posting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.campaign_rounded, size: 18, color: Colors.white), SizedBox(width: 8), Text('Post Announcement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))])))),
        ])),
      ])));
  }
}

class _PerforationPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFEAEDF3)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-10, size.height/2), 14, fill); canvas.drawCircle(Offset(size.width+10, size.height/2), 14, fill);
    final dash = Paint()..color = const Color(0xFFE8EDF3)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path()..moveTo(14, size.height/2)..lineTo(size.width-14, size.height/2);
    for (final m in path.computeMetrics()) { double s=0; while(s<m.length){ final e=(s+6).clamp(0,m.length); canvas.drawPath(m.extractPath(s,e.toDouble()),dash); s+=11; } }
  }
  @override bool shouldRepaint(_) => false;
}
















/*
// Views/Player/court_detail_page.dart
// Premium court detail + booking flow
// pay_now → confirmed | pay_at_venue → pending
// Post-booking: announcement sheet + store update (Home + HomeSettings)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/announcement_service.dart';

// 
// PALETTE
// 
const _bg        = Color(0xFFF2F4F7);
const _white     = Colors.white;
const _ink       = Color(0xFF0A0E1A);
const _textMid   = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border    = Color(0xFFE8EDF3);
const _kGreen    = Color(0xFF16A34A);
const _kRed      = Color(0xFFDC2626);
const _kAmber    = Color(0xFFF59E0B);

// 
// PAGE
// 
class CourtDetailPage extends StatefulWidget {
  final CourtModel court;
  final VenueModel venue;
  final Map<String, dynamic> courtRaw;
  final String? playerToken;

  const CourtDetailPage({super.key, required this.court, required this.venue, required this.courtRaw, required this.playerToken});

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  List<DayPlanSummary> _dayPlans = [];
  DayAvailability? _availability;
  AvailabilitySlot? _selected;
  bool _loadingSlots = false;
  String? _slotsError;
  bool _booking = false;
  late final ReservationService _svc;

  @override
  void initState() {
    super.initState();
    _svc = ReservationService(token: widget.playerToken ?? '');
    if (widget.playerToken?.isNotEmpty == true) _loadDayPlans();
  }

  Future<void> _loadDayPlans() async {
    setState(() { _loadingSlots = true; _slotsError = null; });
    try {
      final plans = await _svc.fetchDayPlansForCourt(widget.venue.id);
      setState(() { _dayPlans = plans; _loadingSlots = false; });
      _loadSlotsForDate(_date);
    } catch (e) {
      setState(() { _slotsError = e.toString().replaceAll('Exception: ', ''); _loadingSlots = false; });
    }
  }

  void _loadSlotsForDate(DateTime date) async {
    final ds = DateFormat('yyyy-MM-dd').format(date);
    final plan = _dayPlans.firstWhere((p) => p.date == ds,
        orElse: () => DayPlanSummary(id: -1, date: '', dayOfWeek: '', dayType: ''));
    if (plan.id == -1) { setState(() { _availability = null; _selected = null; }); return; }
    if (plan.dayType == 'day_off') {
      setState(() { _availability = DayAvailability(date: ds, dayType: 'day_off', slots: []); _selected = null; });
      return;
    }
    setState(() { _loadingSlots = true; _slotsError = null; _selected = null; });
    try {
      final a = await _svc.fetchAvailability(plan.id);
      setState(() { _availability = a; _loadingSlots = false; });
    } catch (e) {
      setState(() { _slotsError = e.toString().replaceAll('Exception: ', ''); _loadingSlots = false; });
    }
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimary, onPrimary: Colors.white),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: kPrimary)),
        ),
        child: child!,
      ),
    );
    if (p != null) { setState(() { _date = p; _selected = null; }); _loadSlotsForDate(p); }
  }

  void _showPaySheet() {
    if (_selected == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaySheet(court: widget.court, slot: _selected!, date: _date, onConfirm: _book),
    );
  }

  Future<void> _book(String method) async {
    Navigator.pop(context);
    setState(() => _booking = true);
    try {
      final courtId = int.tryParse(widget.courtRaw['id']?.toString() ?? '') ?? 0;
      final result = await _svc.createReservation(
        timeSlotId: _selected!.id,
        courtId: courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(_date),
        startTime: _selected!.startTime,
        endTime: _selected!.endTime,
        durationHours: 1.0,
        totalPrice: widget.court.pricePerHour,
        paymentMethod: method,
      );
      if (!mounted) return;
      setState(() => _booking = false);

      final effectiveStatus = method == 'pay_now' ? 'confirmed' : 'pending';
      final displayDate = DateFormat('EEE, d MMM').format(_date);

      final localBooking = LocalBooking(
        id: result.reservationId.toString(),
        courtName: widget.court.name,
        venueName: widget.venue.name,
        courtImageUrl: widget.court.imageUrl ?? '',
        sport: widget.court.sport.label,
        date: displayDate,
        dateRaw: DateFormat('yyyy-MM-dd').format(_date),
        time: '${result.startTime} – ${result.endTime}',
        price: result.totalPrice.toInt(),
        status: effectiveStatus,
        reference: result.bookingReference,
        paymentMethod: method,
      );
      BookingStore.instance.addBooking(localBooking);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _SuccessPage(
          court: widget.court,
          venue: widget.venue,
          result: result,
          date: _date,
          paymentMethod: method,
          effectiveStatus: effectiveStatus,
          localBooking: localBooking,
          playerToken: widget.playerToken,
        )),
      );
    } catch (e) {
      setState(() => _booking = false);
      if (!mounted) return;
      _showErr(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16), const SizedBox(width: 8), Expanded(child: Text(msg, style: const TextStyle(fontSize: 13)))]),
    backgroundColor: _kRed,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    final canBook = _selected != null && !_booking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Court Hero with main image only (no chips)
            _CourtHero(
              court: widget.court,
              venue: widget.venue,
              courtRaw: widget.courtRaw,
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 100),
                children: [
                  // Info chips (outside hero, above photos)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _InfoPill(widget.court.sport.label, widget.court.sport.icon, widget.court.color),
                        const SizedBox(width: 8),
                        _InfoPill(widget.venue.location.split(',').first, Icons.location_on_rounded, _textMid),
                        const SizedBox(width: 8),
                        _InfoPill('Open until ${widget.venue.openUntil}', Icons.schedule_rounded, _textMid),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photos section with header like Select Date
                  _PhotoGallery(courtRaw: widget.courtRaw),
                  const SizedBox(height: 24),

                  _SectionHeader('Select Date', Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  _DateCard(date: _date, onTap: _pickDate),
                  const SizedBox(height: 24),

                  _SectionHeader('Available Slots', Icons.access_time_rounded),
                  const SizedBox(height: 10),
                  _SlotsPanel(
                    loading: _loadingSlots,
                    error: _slotsError,
                    availability: _availability,
                    selected: _selected,
                    hasToken: widget.playerToken?.isNotEmpty == true,
                    onSelect: (s) => setState(() => _selected = s),
                    onRetry: () => _loadSlotsForDate(_date),
                  ),

                  if (_selected != null) ...[
                    const SizedBox(height: 24),
                    _PriceBanner(court: widget.court, slot: _selected!),
                  ],
                ],
              ),
            ),

            // Bottom CTA
            Container(
              color: _white,
              padding: EdgeInsets.fromLTRB(20, 14, 20, navH + 14),
              child: _BookCTA(canBook: canBook, booking: _booking, price: widget.court.pricePerHour, onTap: _showPaySheet),
            ),
          ],
        ),
      ),
    );
  }
}

// 
// COURT HERO - Main cover image only (no chips)
// 
class _CourtHero extends StatelessWidget {
  final CourtModel court;
  final VenueModel venue;
  final Map<String, dynamic> courtRaw;
  const _CourtHero({required this.court, required this.venue, required this.courtRaw});

  String _getMainImageUrl() {
    if (courtRaw['court_img_url'] != null && courtRaw['court_img_url'].toString().isNotEmpty) {
      String url = courtRaw['court_img_url'].toString();
      if (url.startsWith('http')) return url;
      return 'http://10.0.2.2:1337$url';
    }
    
    final courtImg = courtRaw['court_img'];
    if (courtImg != null && courtImg is Map) {
      String url = courtImg['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        if (url.startsWith('http')) return url;
        return 'http://10.0.2.2:1337$url';
      }
    }
    
    final photos = courtRaw['photos'];
    if (photos != null && photos is List && photos.isNotEmpty) {
      if (photos[0] is Map) {
        String url = photos[0]['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          if (url.startsWith('http')) return url;
          return 'http://10.0.2.2:1337$url';
        }
      }
    }
    
    return court.imageUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final mainImageUrl = _getMainImageUrl();
    
    return Stack(
      children: [
        // Main cover image
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: court.color,
            image: mainImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(mainImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: mainImageUrl.isEmpty
              ? Center(
                  child: Icon(
                    court.sport.icon,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                )
              : null,
        ),
        
        // Dark gradient overlay
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xB3000000)],
              stops: [0.3, 0.7],
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
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        
        // Court info overlay at bottom
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        court.sport.label,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      court.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venue.name,
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text(
                      '${court.pricePerHour.toInt()}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                    ),
                    const Text('DT / h', style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 
// PHOTO GALLERY - With header matching Select Date style
// 
class _PhotoGallery extends StatefulWidget {
  final Map<String, dynamic> courtRaw;
  const _PhotoGallery({required this.courtRaw});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  List<String> _photoUrls = [];

  @override
  void initState() {
    super.initState();
    _extractPhotoUrls();
  }

  void _extractPhotoUrls() {
    final urls = <String>[];
    
    String buildUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return 'http://10.0.2.2:1337$path';
    }

    final photosUrls = widget.courtRaw['photos_urls'];
    if (photosUrls != null && photosUrls is List) {
      for (final p in photosUrls) {
        final url = buildUrl(p.toString());
        if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
      }
    }

    final photos = widget.courtRaw['photos'];
    if (photos != null && photos is List) {
      for (final p in photos) {
        if (p is Map) {
          final url = buildUrl(p['url']?.toString());
          if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
        }
      }
    }

    _photoUrls = urls;
  }

  void _openPhotoViewer(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: index),
              itemCount: _photoUrls.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        _photoUrls[i],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: kPrimary),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1} / ${_photoUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_photoUrls.isEmpty || _photoUrls.length < 2) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.photo_library_rounded, size: 14, color: kPrimary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_photoUrls.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photoUrls.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openPhotoViewer(i),
              child: Padding(
                padding: EdgeInsets.only(right: i == _photoUrls.length - 1 ? 0 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 280,
                    height: 200,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          _photoUrls[i],
                          width: 280,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 280,
                              height: 200,
                              color: _bg,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 280,
                              height: 200,
                              color: _bg,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 32, color: _textLight),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load',
                                    style: TextStyle(fontSize: 11, color: _textLight),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tap_and_play, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 
// INFO PILL
// 
class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoPill(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ],
    ),
  );
}

// 
// DATE CARD
// 
class _DateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateCard({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('EEEE').format(date);
    final dateStr = DateFormat('d MMMM yyyy').format(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1),
                  ),
                  Text(
                    '${date.day}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: _textMid)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_calendar_rounded, size: 13, color: kPrimary),
                  SizedBox(width: 5),
                  Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
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
// SLOTS PANEL
// 
class _SlotsPanel extends StatelessWidget {
  final bool loading, hasToken;
  final String? error;
  final DayAvailability? availability;
  final AvailabilitySlot? selected;
  final ValueChanged<AvailabilitySlot> onSelect;
  final VoidCallback onRetry;

  const _SlotsPanel({
    required this.loading,
    required this.error,
    required this.availability,
    required this.selected,
    required this.hasToken,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasToken) return _statusCard(Icons.lock_outline_rounded, 'Sign in to see available slots', isInfo: true);
    if (loading) return const _SlotsShimmer();
    if (error != null) return _statusCard(Icons.wifi_off_rounded, error!, isError: true, retry: onRetry);
    if (availability == null) return _statusCard(Icons.event_busy_rounded, 'No schedule found for this date');
    if (availability!.dayType == 'day_off') return _statusCard(Icons.beach_access_rounded, 'Day off — venue is closed');

    final all = availability!.slots;
    if (all.isEmpty) return _statusCard(Icons.access_time_rounded, 'No time slots configured for this day');

    if (availability!.dayType == 'urgent_only') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAmber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAmber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: _kAmber),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Urgent bookings only today',
                style: TextStyle(fontSize: 13, color: _kAmber, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final avail = all.where((s) => s.isAvailable).toList();
    final booked = all.where((s) => !s.isAvailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avail.isNotEmpty) ...[
          Row(
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(
                '${avail.length} slot${avail.length == 1 ? '' : 's'} available',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: avail.map((s) => _SlotTile(slot: s, selected: selected?.id == s.id, onTap: () => onSelect(s))).toList(),
          ),
        ],
        if (booked.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: _textLight, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('Already booked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMid)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: booked.map((s) => _SlotTile(slot: s, selected: false, onTap: null)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _statusCard(IconData icon, String text, {bool isError = false, bool isInfo = false, VoidCallback? retry}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? _kRed.withOpacity(0.25) : _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isError ? _kRed : kPrimary).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isError ? _kRed : _textMid, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isError ? _kRed : _textMid))),
          if (retry != null)
            GestureDetector(
              onTap: retry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final AvailabilitySlot slot;
  final bool selected;
  final VoidCallback? onTap;
  const _SlotTile({required this.slot, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = slot.isAvailable;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? kPrimary : a ? _white : _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kPrimary : a ? _border : _border.withOpacity(0.5),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))]
              : a
                  ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]
                  : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.startTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : a ? _ink : _textLight,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '→ ${slot.endTime}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white70 : a ? _textMid : _textLight.withOpacity(0.6),
              ),
            ),
            if (!a) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('Taken', style: TextStyle(fontSize: 8, color: _kRed, fontWeight: FontWeight.w700)),
              ),
            ],
            if (selected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotsShimmer extends StatefulWidget {
  const _SlotsShimmer();
  @override
  State<_SlotsShimmer> createState() => _SlotsShimmerState();
}

class _SlotsShimmerState extends State<_SlotsShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(6, (_) => Container(
          width: 80,
          height: 58,
          decoration: BoxDecoration(
            color: Color.lerp(_white, _border, _c.value),
            borderRadius: BorderRadius.circular(14),
          ),
        )),
      ),
    );
  }
}

// 
// PRICE BANNER
// 
class _PriceBanner extends StatelessWidget {
  final CourtModel court;
  final AvailabilitySlot slot;
  const _PriceBanner({required this.court, required this.slot});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kPrimary.withOpacity(0.18)),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.receipt_long_rounded, color: kPrimary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _textMid, letterSpacing: 1.5)),
              Text('${court.pricePerHour.toInt()} DT', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kPrimary, height: 1.1)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
              child: Text('${slot.startTime} – ${slot.endTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            const Text('1 hour · 1 court', style: TextStyle(fontSize: 10, color: _textMid)),
          ],
        ),
      ],
    ),
  );
}

// 
// BOOK CTA
// 
class _BookCTA extends StatelessWidget {
  final bool canBook, booking;
  final double price;
  final VoidCallback onTap;
  const _BookCTA({required this.canBook, required this.booking, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: canBook ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: canBook ? kPrimary : _border,
        borderRadius: BorderRadius.circular(16),
        boxShadow: canBook ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 5))] : [],
      ),
      child: Center(
        child: booking
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(canBook ? Icons.check_circle_rounded : Icons.touch_app_rounded, size: 18, color: canBook ? Colors.white : _textMid),
                  const SizedBox(width: 9),
                  Text(
                    canBook ? 'Book Now · ${price.toInt()} DT' : 'Select a time slot',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: canBook ? Colors.white : _textMid),
                  ),
                ],
              ),
      ),
    ),
  );
}

// 
// PAYMENT SHEET
// 
class _PaySheet extends StatefulWidget {
  final CourtModel court;
  final AvailabilitySlot slot;
  final DateTime date;
  final Future<void> Function(String) onConfirm;
  const _PaySheet({required this.court, required this.slot, required this.date, required this.onConfirm});
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String _method = 'pay_at_venue';
  bool _paying = false;

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    final isPay = _method == 'pay_now';
    final accent = isPay ? kPrimary : _kAmber;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 24),
      decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: widget.court.imageUrl != null && widget.court.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.court.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: kPrimary.withOpacity(0.08),
                              child: Icon(widget.court.sport.icon, color: kPrimary, size: 22),
                            ),
                          )
                        : Container(
                            color: kPrimary.withOpacity(0.08),
                            child: Icon(widget.court.sport.icon, color: kPrimary, size: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.court.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormat('EEE, d MMM').format(widget.date)}  ·  ${widget.slot.startTime} – ${widget.slot.endTime}',
                        style: const TextStyle(fontSize: 11, color: _textMid),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${widget.court.pricePerHour.toInt()} DT', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Align(alignment: Alignment.centerLeft, child: Text('Choose payment method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink))),
          const SizedBox(height: 12),

          _PayOption(
            icon: Icons.bolt_rounded,
            title: 'Pay Online Now',
            subtitle: 'Instant confirmation — slot secured immediately',
            tag: 'CONFIRMED',
            tagColor: _kGreen,
            color: kPrimary,
            selected: _method == 'pay_now',
            onTap: () => setState(() => _method = 'pay_now'),
          ),
          const SizedBox(height: 10),
          _PayOption(
            icon: Icons.storefront_rounded,
            title: 'Pay at Venue',
            subtitle: 'Pay on arrival — reservation held pending',
            tag: 'PENDING',
            tagColor: _kAmber,
            color: _kAmber,
            selected: _method == 'pay_at_venue',
            onTap: () => setState(() => _method = 'pay_at_venue'),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _paying ? null : () async {
              setState(() => _paying = true);
              await widget.onConfirm(_method);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: _paying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        isPay ? 'Pay ${widget.court.pricePerHour.toInt()} DT & Confirm' : 'Reserve — Pay at Venue',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, tag;
  final Color tagColor, color;
  final bool selected;
  final VoidCallback onTap;
  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.05) : _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? color.withOpacity(0.5) : _border, width: selected ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text(tag, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: tagColor, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: _textMid)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(color: selected ? color : _textLight, width: 1.5),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
          ),
        ],
      ),
    ),
  );
}

// 
// SUCCESS PAGE - No animations, X on top left
// 
class _SuccessPage extends StatelessWidget {
  final CourtModel court;
  final VenueModel venue;
  final BookingResult result;
  final DateTime date;
  final String paymentMethod;
  final String effectiveStatus;
  final LocalBooking localBooking;
  final String? playerToken;

  const _SuccessPage({
    required this.court,
    required this.venue,
    required this.result,
    required this.date,
    required this.paymentMethod,
    required this.effectiveStatus,
    required this.localBooking,
    required this.playerToken,
  });

  void _showAnnouncementSheet(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AnnouncementSheet(
      booking: localBooking,
      court: court,
      playerToken: playerToken,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isPaid = effectiveStatus == 'confirmed';
    final sc = isPaid ? _kGreen : _kAmber;
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            SizedBox(
              height: 320,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  court.imageUrl != null
                      ? Image.network(
                          court.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroBg(),
                        )
                      : _heroBg(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.82)],
                      ),
                    ),
                  ),
                 Positioned(
  top: 0,
  left: 0,
  child: SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
    ),
  ),
),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: sc.withOpacity(0.5), blurRadius: 28, spreadRadius: 6)],
                          ),
                          child: Icon(isPaid ? Icons.check_rounded : Icons.hourglass_top_rounded, color: sc, size: 38),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPaid ? 'Booking Confirmed!' : 'Reservation Pending',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPaid ? 'Payment received — see you on the court!' : 'Pay at the venue when you arrive',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Icon(court.sport.icon, color: Colors.white60, size: 15),
                        const SizedBox(width: 7),
                        Expanded(child: Text(court.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            result.bookingReference,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
                children: [
                  _TicketCard(
                    result: result,
                    date: date,
                    status: effectiveStatus,
                    sc: sc,
                    isPaid: isPaid,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sc.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isPaid ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 16, color: sc),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPaid
                                ? 'Your slot is confirmed and secured. The court is ready for you!'
                                : 'Your slot is reserved. Please arrive 10 minutes early and pay at reception.',
                            style: TextStyle(fontSize: 12, color: sc, height: 1.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!BookingStore.instance.hasAnnouncementForReservation(localBooking.id))
                    GestureDetector(
                      onTap: () => _showAnnouncementSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.04)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Need teammates?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                                  SizedBox(height: 2),
                                  Text('Post an announcement to find players', style: TextStyle(fontSize: 11, color: _textMid)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _textMid),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Back to Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
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

  Widget _heroBg() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(court.color, Colors.black, 0.5)!, court.color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );
}

// Ticket card with perforated divider
class _TicketCard extends StatelessWidget {
  final BookingResult result;
  final DateTime date;
  final String status;
  final Color sc;
  final bool isPaid;
  const _TicketCard({
    required this.result,
    required this.date,
    required this.status,
    required this.sc,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _TicketRow(Icons.calendar_today_rounded, 'Date', DateFormat('EEEE, d MMMM yyyy').format(date), kPrimary),
              const SizedBox(height: 14),
              _TicketRow(Icons.access_time_rounded, 'Time', '${result.startTime} – ${result.endTime}', kPrimary),
              const SizedBox(height: 14),
              _TicketRow(Icons.payments_rounded, 'Payment', isPaid ? '${result.totalPrice.toInt()} DT · Paid online' : '${result.totalPrice.toInt()} DT · Pay at venue', sc),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: CustomPaint(
            painter: _PerforationPainter(),
            size: const Size(double.infinity, 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _TicketRow(Icons.tag_rounded, 'Reference', result.bookingReference, _textMid),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                    child: Icon(isPaid ? Icons.verified_rounded : Icons.pending_rounded, size: 14, color: sc),
                  ),
                  const SizedBox(width: 12),
                  const Text('Status', style: TextStyle(fontSize: 13, color: _textMid)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sc.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sc, letterSpacing: 0.5)),
                      ],
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

class _TicketRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _TicketRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 13, color: _textMid)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

// 
// ANNOUNCEMENT SHEET
// 
class _AnnouncementSheet extends StatefulWidget {
  final LocalBooking booking;
  final CourtModel court;
  final String? playerToken;
  const _AnnouncementSheet({required this.booking, required this.court, this.playerToken});
  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  int _playersNeeded = 2;
  final _descCtrl = TextEditingController();
  bool _posting = false;
  late AnnouncementService _announcementService;

  @override
  void initState() {
    super.initState();
    if (widget.playerToken != null) {
      _announcementService = AnnouncementService(token: widget.playerToken!);
    }
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

    if (widget.playerToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post announcement'), behavior: SnackBarBehavior.floating),
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Announcement posted! It will appear in Community tab.', style: TextStyle(fontWeight: FontWeight.w600)),
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
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: _white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.campaign_rounded, color: kPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Make an Announcement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
                        Text('Find teammates for your session', style: TextStyle(fontSize: 12, color: _textMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: _border),
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
                        Icon(widget.court.sport.icon, size: 16, color: kPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.booking.courtName}  ·  ${widget.booking.date}  ·  ${widget.booking.time}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
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
                            Text('Players needed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                            SizedBox(height: 2),
                            Text('How many more players to join?', style: TextStyle(fontSize: 11, color: _textMid)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
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
                                child: Icon(Icons.remove_rounded, size: 16, color: _playersNeeded > 1 ? kPrimary : _textLight),
                              ),
                            ),
                            Text('$_playersNeeded', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
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

                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(fontSize: 14, color: _ink, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Friendly match, intermediate level. All welcome!',
                        hintStyle: TextStyle(color: _textLight, fontSize: 13),
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
// MISC WIDGETS
// 
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 14, color: kPrimary),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2)),
    ],
  );
}

// 
// PAINTERS
// 
class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEAEDF3)..strokeWidth = 1.5..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-10, size.height / 2), 14, paint);
    canvas.drawCircle(Offset(size.width + 10, size.height / 2), 14, paint);
    final dash = Paint()..color = const Color(0xFFE8EDF3)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path()..moveTo(14, size.height / 2)..lineTo(size.width - 14, size.height / 2);
    _drawDashed(canvas, path, dash, dashWidth: 6, dashSpace: 5);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, {required double dashWidth, required double dashSpace}) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double start = 0;
      while (start < metric.length) {
        final end = (start + dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(start, end.toDouble()), paint);
        start += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
*/