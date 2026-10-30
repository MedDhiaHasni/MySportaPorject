// lib/Views/Player/court_detail_page.dart
// e5er 7aja
// Stripe online payment flow (flutter_stripe v11)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Core/Constants/api_constants.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';
import 'package:sporta/Models/venue_model.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:sporta/Services/payment_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Widgets/booking_components.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/feedback_components.dart';

//
// PALETTE
//
const _bg = Color(0xFFF2F4F7);
const _white = Colors.white;
const _ink = Color(0xFF0A0E1A);
const _textMid = Color(0xFF64748B);
const _textLight = Color(0xFFB0B7C3);
const _border = Color(0xFFE8EDF3);
const _kGreen = Color(0xFF16A34A);
const _kRed = Color(0xFFDC2626);
const _kAmber = Color(0xFFF59E0B);

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

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadDayPlans() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
    });
    try {
      final plans = await _svc.fetchDayPlansForCourt(widget.venue.id);
      setState(() {
        _dayPlans = plans;
        _loadingSlots = false;
      });
      _loadSlotsForDate(_date);
    } catch (e) {
      setState(() {
        _slotsError = e.toString().replaceAll('Exception: ', '');
        _loadingSlots = false;
      });
    }
  }

  void _loadSlotsForDate(DateTime date) async {
    final ds = DateFormat('yyyy-MM-dd').format(date);
    final plan = _dayPlans.firstWhere(
      (p) => p.date == ds,
      orElse: () =>
          DayPlanSummary(id: -1, date: '', dayOfWeek: '', dayType: ''),
    );
    if (plan.id == -1) {
      setState(() {
        _availability = null;
        _selected = null;
      });
      return;
    }
    if (plan.dayType == 'day_off') {
      setState(() {
        _availability = DayAvailability(
          date: ds,
          dayType: 'day_off',
          slots: [],
        );
        _selected = null;
      });
      return;
    }
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _selected = null;
    });
    try {
      final a = await _svc.fetchAvailability(plan.id);
      setState(() {
        _availability = a;
        _loadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _slotsError = e.toString().replaceAll('Exception: ', '');
        _loadingSlots = false;
      });
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
    if (p != null) {
      setState(() {
        _date = p;
        _selected = null;
      });
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
      final courtId =
          int.tryParse(widget.courtRaw['id']?.toString() ?? '') ?? 0;
      final result = await _svc.createReservation(
        timeSlotId: _selected!.id,
        courtId: courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(_date),
        startTime: _selected!.startTime,
        endTime: _selected!.endTime,
        durationHours: 1.0,
        totalPrice: widget.court.pricePerHour,
        paymentMethod: 'pay_at_venue',
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
      final courtId =
          int.tryParse(widget.courtRaw['id']?.toString() ?? '') ?? 0;
      final result = await _svc.createReservation(
        timeSlotId: _selected!.id,
        courtId: courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(_date),
        startTime: _selected!.startTime,
        endTime: _selected!.endTime,
        durationHours: 1.0,
        totalPrice: widget.court.pricePerHour,
        paymentMethod: 'pay_now',
      );

      if (!mounted) return;

      // ── Step 2: Create PaymentIntent via backend ──────────────────────────
      final paymentSvc = PaymentService(token: widget.playerToken ?? '');
      final intentResult = await paymentSvc.createIntent(
        result.reservationId.toString(),
      );

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
                  email: CollectionMode.automatic,
                  name: CollectionMode.automatic,
                  phone: CollectionMode.never,
                ),

            // Light theme
            style: ThemeMode.light,

            // Custom appearance — matches kPrimary green
            appearance: PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primary: const Color(0xFF16A34A),
                background: const Color(0xFFF2F4F7),
                componentBackground: Colors.white,
                placeholderText: const Color(0xFFB0B7C3),
                primaryText: const Color(0xFF0D0D0D),
                secondaryText: const Color(0xFF6B7280),
              ),
              shapes: const PaymentSheetShape(
                borderWidth: 1,
                shadow: PaymentSheetShadowParams(opacity: 0.05),
              ),
              primaryButton: PaymentSheetPrimaryButtonAppearance(
                colors: PaymentSheetPrimaryButtonTheme(
                  light: PaymentSheetPrimaryButtonThemeColors(
                    background: const Color(0xFF16A34A),
                    text: Colors.white,
                    border: const Color(0xFF16A34A),
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
        if (mounted)
          _showErr(
            'Payment failed: ${e.error.localizedMessage ?? e.error.message}',
          );
        return;
      } catch (e) {
        if (mounted) _showErr('Payment failed: ${e.toString().split('\n')[0]}');
        return;
      }

      // ── Step 5: Confirm with backend ──────────────────────────────────────
      if (!mounted) return;
      setState(() => _booking = true);

      final confirmResult = await paymentSvc.confirmPayment(
        intentResult.paymentId!,
      );

      if (!mounted) return;
      setState(() => _booking = false);

      if (confirmResult.success && confirmResult.status == 'succeeded') {
        _goSuccess(result, 'pay_now', 'confirmed');
      } else if (confirmResult.status == 'pending') {
        _showPendingPayment();
      } else {
        _showErr(
          confirmResult.message ??
              confirmResult.error ??
              'Payment confirmation failed',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        _showErr(e.toString().split('\n')[0]);
      }
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goSuccess(
    BookingResult result,
    String paymentMethod,
    String effectiveStatus,
  ) {
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
      paymentMethod: paymentMethod,
    );
    BookingStore.instance.addBooking(localBooking);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _SuccessPage(
          court: widget.court,
          venue: widget.venue,
          result: result,
          date: _date,
          paymentMethod: paymentMethod,
          effectiveStatus: effectiveStatus,
          localBooking: localBooking,
          playerToken: widget.playerToken,
        ),
      ),
    );
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPendingPayment() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment received. Confirmation is taking longer than expected; check My Bookings shortly.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canBook = _selected != null && !_booking;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _CourtHero(
              court: widget.court,
              venue: widget.venue,
              courtRaw: widget.courtRaw,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _InfoPill(
                          widget.court.sport.label,
                          widget.court.sport.icon,
                          Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _InfoPill(
                          widget.venue.location.split(',').first,
                          Icons.location_on_rounded,
                          Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _InfoPill(
                          'Open until ${widget.venue.openUntil}',
                          Icons.schedule_rounded,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                  if (widget.venue.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.venue.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (widget.venue.amenities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(title: 'Amenities'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: widget.venue.amenities
                          .map(
                            (amenity) => SportChip(
                              label: amenity,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (widget.courtRaw['photos_urls'] is List &&
                      (widget.courtRaw['photos_urls'] as List).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _PhotoGallery(courtRaw: widget.courtRaw),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(title: 'Select date'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 88,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              final date = DateUtils.dateOnly(
                                DateTime.now().add(Duration(days: index)),
                              );
                              final selected = DateUtils.isSameDay(date, _date);
                              return DateRailItem(
                                date: date,
                                isToday: index == 0,
                                selected: selected,
                                onTap: () {
                                  if (selected) return;
                                  setState(() {
                                    _date = date;
                                    _selected = null;
                                  });
                                  _loadSlotsForDate(date);
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Choose another date',
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(title: 'Available slots'),
                  const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.lg),
                    _PriceBanner(court: widget.court, slot: _selected!),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: StickyBookingBar(
                priceLabel: '${widget.court.pricePerHour.toInt()} DT',
                // TODO: Show a hold countdown only after the backend supports reservation holds.
                onBook: _showPaySheet,
                enabled: canBook,
                isLoading: _booking,
              ),
            ),
          ],
        ),
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
  const _PaySheet({
    required this.court,
    required this.slot,
    required this.date,
    required this.onConfirm,
  });
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
    final theme = Theme.of(context);
    final accent = isPay
        ? NightMatchColors.actionLime
        : NightMatchColors.brandTeal;
    final accentForeground = isPay
        ? NightMatchColors.onAction
        : NightMatchColors.text;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bot + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: const BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child:
                        widget.court.imageUrl != null &&
                            widget.court.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.court.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _sportIcon(widget.court),
                          )
                        : _sportIcon(widget.court),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.court.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormat('EEE, d MMM').format(widget.date)}  ·  ${widget.slot.startTime} – ${widget.slot.endTime}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: NightMatchColors.actionLime,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Text(
                    '${widget.court.pricePerHour.toInt()} DT',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: NightMatchColors.onAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Choose payment method',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),

          _PayOption(
            icon: Icons.credit_card_rounded,
            title: 'Pay Online Now',
            subtitle: 'Secure card payment via Stripe — instant confirmation',
            tag: 'CONFIRMED',
            tagColor: NightMatchColors.success,
            color: NightMatchColors.actionLime,
            selected: _method == 'pay_now',
            badge: '🔒 Stripe',
            onTap: () => setState(() => _method = 'pay_now'),
          ),
          const SizedBox(height: 10),

          _PayOption(
            icon: Icons.storefront_rounded,
            title: 'Pay at Venue',
            subtitle: 'Reservation held — pay cash on arrival',
            tag: 'PENDING',
            tagColor: NightMatchColors.actionLime,
            color: NightMatchColors.brandTeal,
            selected: _method == 'pay_at_venue',
            badge: null,
            onTap: () => setState(() => _method = 'pay_at_venue'),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _paying
                ? null
                : () async {
                    setState(() => _paying = true);
                    await widget.onConfirm(_method);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _paying
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: accentForeground,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPay
                                ? Icons.credit_card_rounded
                                : Icons.store_rounded,
                            color: accentForeground,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isPay
                                ? 'Pay ${widget.court.pricePerHour.toInt()} DT with Stripe'
                                : 'Reserve — Pay at Venue',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: accentForeground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_method == 'pay_now') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '256-bit SSL encrypted · Powered by Stripe',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sportIcon(CourtModel c) => Container(
    color: kPrimary.withOpacity(0.08),
    child: Icon(c.sport.icon, color: kPrimary, size: 22),
  );
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, tag;
  final String? badge;
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
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final selectedForeground = color == NightMatchColors.actionLime
        ? NightMatchColors.onAction
        : NightMatchColors.text;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: selected ? color : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tagColor,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedContainer(
                duration: duration,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : scheme.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: selectedForeground,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  final CourtModel court;
  final VenueModel venue;
  final BookingResult result;
  final DateTime date;
  final String paymentMethod, effectiveStatus;
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

  bool get _isPaid => effectiveStatus == 'confirmed';
  Color get _sc => _isPaid ? _kGreen : _kAmber;

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
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // Hero
            SizedBox(
              height: 320,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  court.imageUrl != null
                      ? Image.network(
                          court.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _heroBg(),
                        )
                      : _heroBg(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.82),
                        ],
                      ),
                    ),
                  ),
                  // Close
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Status icon
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
                            boxShadow: [
                              BoxShadow(
                                color: _sc.withOpacity(0.5),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPaid
                                ? Icons.check_rounded
                                : Icons.hourglass_top_rounded,
                            color: _sc,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPaid
                              ? 'Booking Confirmed!'
                              : 'Reservation Pending',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isPaid
                              ? 'Payment received — see you on the court!'
                              : 'Pay at the venue when you arrive',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reference
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Icon(court.sport.icon, color: Colors.white60, size: 15),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            court.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            result.bookingReference,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
                children: [
                  // Ticket
                  _TicketCard(
                    result: result,
                    date: date,
                    status: effectiveStatus,
                    sc: _sc,
                    isPaid: _isPaid,
                    paymentMethod: paymentMethod,
                  ),
                  const SizedBox(height: 16),

                  // Status note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _sc.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _sc.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isPaid
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 16,
                          color: _sc,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isPaid
                                ? 'Your slot is confirmed and secured. The court is ready for you!'
                                : 'Your slot is reserved. Please arrive 10 minutes early and pay at reception.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _sc,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teammates
                  if (!BookingStore.instance.hasAnnouncementForReservation(
                    localBooking.id,
                  ))
                    GestureDetector(
                      onTap: () => _showAnnouncementSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.08),
                              kPrimary.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Need teammates?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Post an announcement to find players',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: _textMid,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Home button
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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

//
// TICKET CARD
//
class _TicketCard extends StatelessWidget {
  final BookingResult result;
  final DateTime date;
  final String status, paymentMethod;
  final Color sc;
  final bool isPaid;
  const _TicketCard({
    required this.result,
    required this.date,
    required this.status,
    required this.sc,
    required this.isPaid,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final paymentLabel = isPaid
        ? '${result.totalPrice.toInt()} DT · Paid online via Stripe'
        : '${result.totalPrice.toInt()} DT · Pay at venue';

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _TRow(
                  Icons.calendar_today_rounded,
                  'Date',
                  DateFormat('EEEE, d MMMM yyyy').format(date),
                  kPrimary,
                ),
                const SizedBox(height: 14),
                _TRow(
                  Icons.access_time_rounded,
                  'Time',
                  '${result.startTime} – ${result.endTime}',
                  kPrimary,
                ),
                const SizedBox(height: 14),
                _TRow(Icons.payments_rounded, 'Payment', paymentLabel, sc),
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
                _TRow(
                  Icons.tag_rounded,
                  'Reference',
                  result.bookingReference,
                  _textMid,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        isPaid ? Icons.verified_rounded : Icons.pending_rounded,
                        size: 14,
                        color: sc,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 13, color: _textMid),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sc.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: sc,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: sc,
                              letterSpacing: 0.5,
                            ),
                          ),
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
}

class _TRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _TRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 13, color: _textMid)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

//
// COURT HERO WITH FIXED BACK BUTTON
//
class _CourtHero extends StatelessWidget {
  final CourtModel court;
  final VenueModel venue;
  final Map<String, dynamic> courtRaw;
  const _CourtHero({
    required this.court,
    required this.venue,
    required this.courtRaw,
  });

  String _mainImg() {
    String b(String? p) {
      if (p == null || p.isEmpty) return '';
      if (p.startsWith('http')) return p;
      return '${ApiConstants.mediaBaseUrl}$p';
    }

    final u = courtRaw['court_img_url']?.toString();
    if (u != null && u.isNotEmpty) return b(u);
    if (courtRaw['court_img'] is Map)
      return b(courtRaw['court_img']['url']?.toString());
    if (courtRaw['photos'] is List && (courtRaw['photos'] as List).isNotEmpty) {
      final f = (courtRaw['photos'] as List).first;
      if (f is Map) return b(f['url']?.toString());
    }
    return court.imageUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final img = _mainImg();
    final theme = Theme.of(context);
    return Stack(
      children: [
        SizedBox(
          height: AppLayout.heroHeight,
          width: double.infinity,
          child: img.isNotEmpty
              ? Hero(
                  tag: 'court-image-${court.id}',
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _heroFallback(theme),
                  ),
                )
              : _heroFallback(theme),
        ),
        Container(
          height: AppLayout.heroHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: [
                NightMatchColors.heroScrimTop,
                NightMatchColors.heroScrimBottom,
              ],
              stops: [0.16, 0.82],
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.sm,
                top: AppSpacing.sm,
              ),
              child: IconButton.filledTonal(
                tooltip: 'Back to venue',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: NightMatchColors.onAction.withValues(
                    alpha: 0.68,
                  ),
                  foregroundColor: NightMatchColors.text,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SportChip(label: court.sport.label, icon: court.sport.icon),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      court.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: NightMatchColors.text,
                      ),
                    ),
                    Text(
                      venue.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: NightMatchColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: NightMatchColors.actionLime,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  boxShadow: theme.brightness == Brightness.dark
                      ? AppElevation.nightGlow
                      : const [],
                ),
                child: Column(
                  children: [
                    Text(
                      '${court.pricePerHour.toInt()}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: NightMatchColors.onAction,
                      ),
                    ),
                    Text(
                      'DT / h',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: NightMatchColors.onAction,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroFallback(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        court.sport.icon,
        size: AppSpacing.xxxl,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _PhotoGallery extends StatefulWidget {
  final Map<String, dynamic> courtRaw;
  const _PhotoGallery({required this.courtRaw});
  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  List<String> _urls = [];
  @override
  void initState() {
    super.initState();
    _extract();
  }

  void _extract() {
    final urls = <String>[];
    String b(String? p) {
      if (p == null || p.isEmpty) return '';
      if (p.startsWith('http')) return p;
      return '${ApiConstants.mediaBaseUrl}$p';
    }

    final pu = widget.courtRaw['photos_urls'];
    if (pu is List)
      for (final p in pu) {
        final u = b(p.toString());
        if (u.isNotEmpty && !urls.contains(u)) urls.add(u);
      }
    final ph = widget.courtRaw['photos'];
    if (ph is List)
      for (final p in ph) {
        if (p is Map) {
          final u = b(p['url']?.toString());
          if (u.isNotEmpty && !urls.contains(u)) urls.add(u);
        }
      }
    _urls = urls;
  }

  void _open(int i) => showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: i),
            itemCount: _urls.length,
            itemBuilder: (_, idx) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black,
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      _urls[idx],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(color: kPrimary),
                            ),
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
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (_urls.length < 2) return const SizedBox.shrink();
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
              child: const Icon(
                Icons.photo_library_rounded,
                size: 14,
                color: kPrimary,
              ),
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
                '${_urls.length}',
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
            itemCount: _urls.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _open(i),
              child: Padding(
                padding: EdgeInsets.only(right: i == _urls.length - 1 ? 0 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.network(
                        _urls[i],
                        width: 280,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : Container(
                                width: 280,
                                height: 200,
                                color: _bg,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                        errorBuilder: (_, _, _) => Container(
                          width: 280,
                          height: 200,
                          color: _bg,
                          child: Icon(
                            Icons.broken_image,
                            size: 32,
                            color: _textLight,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tap_and_play,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoPill(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    if (!hasToken)
      return _card(
        context,
        Icons.lock_outline_rounded,
        'Sign in to see available slots',
      );
    if (loading) return const _SlotsShimmer();
    if (error != null)
      return _card(
        context,
        Icons.wifi_off_rounded,
        error!,
        isError: true,
        retry: onRetry,
      );
    if (availability == null)
      return _card(
        context,
        Icons.event_busy_rounded,
        'No schedule found for this date',
      );
    if (availability!.dayType == 'day_off')
      return _card(
        context,
        Icons.beach_access_rounded,
        'Day off — venue is closed',
      );
    final all = availability!.slots;
    if (all.isEmpty)
      return _card(
        context,
        Icons.access_time_rounded,
        'No time slots configured for this day',
      );
    if (availability!.dayType == 'urgent_only')
      return AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Urgent bookings only today',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    final avail = all.where((s) => s.isAvailable).toList();
    final booked = all.where((s) => !s.isAvailable).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avail.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: NightMatchColors.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${avail.length} slot${avail.length == 1 ? '' : 's'} available',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: NightMatchColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: avail
                .map(
                  (slot) => _SlotTile(
                    slot: slot,
                    selected: selected?.id == slot.id,
                    onTap: () => onSelect(slot),
                  ),
                )
                .toList(),
          ),
        ],
        if (booked.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.block_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Already booked',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: booked
                .map(
                  (slot) => _SlotTile(slot: slot, selected: false, onTap: null),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context,
    IconData icon,
    String text, {
    bool isError = false,
    VoidCallback? retry,
  }) => AppCard(
    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(
          icon,
          color: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}

class _SlotTile extends StatelessWidget {
  final AvailabilitySlot slot;
  final bool selected;
  final VoidCallback? onTap;
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => TimeSlotButton(
    label: slot.startTime,
    state: selected
        ? TimeSlotState.selected
        : slot.isAvailable
        ? TimeSlotState.available
        : TimeSlotState.unavailable,
    onPressed: slot.isAvailable ? onTap : null,
  );
}

class _SlotsShimmer extends StatelessWidget {
  const _SlotsShimmer();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: List.generate(
      6,
      (_) => const LoadingSkeleton(
        width: 88,
        height: 52,
        borderRadius: AppRadius.input,
      ),
    ),
  );
}

class _PriceBanner extends StatelessWidget {
  final CourtModel court;
  final AvailabilitySlot slot;
  const _PriceBanner({required this.court, required this.slot});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected slot', style: theme.textTheme.labelMedium),
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: NightMatchColors.actionLime,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Text(
              '${court.pricePerHour.toInt()} DT',
              style: theme.textTheme.titleMedium?.copyWith(
                color: NightMatchColors.onAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementSheet extends StatefulWidget {
  final LocalBooking booking;
  final CourtModel court;
  final String? playerToken;
  const _AnnouncementSheet({
    required this.booking,
    required this.court,
    this.playerToken,
  });
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
    if (widget.playerToken != null)
      _announcementService = AnnouncementService(token: widget.playerToken!);
  }

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
    if (widget.playerToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to post'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      await _announcementService.create(
        reservationId: widget.booking.id,
        description: _descCtrl.text.trim(),
        playersNeeded: _playersNeeded,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Announcement posted!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
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
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
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
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: kPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make an Announcement',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Find teammates for your session',
                          style: TextStyle(fontSize: 12, color: _textMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: _border,
            ),
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
                        Icon(
                          widget.court.sport.icon,
                          size: 16,
                          color: kPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.booking.courtName}  ·  ${widget.booking.date}  ·  ${widget.booking.time}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
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
                            Text(
                              'Players needed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'How many more players?',
                              style: TextStyle(fontSize: 11, color: _textMid),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded > 1)
                                  setState(() => _playersNeeded--);
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 16,
                                  color: _playersNeeded > 1
                                      ? kPrimary
                                      : _textLight,
                                ),
                              ),
                            ),
                            Text(
                              '$_playersNeeded',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_playersNeeded < 20)
                                  setState(() => _playersNeeded++);
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      minLines: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _ink,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Friendly match, all welcome!',
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
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _posting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.campaign_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Post Announcement',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
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

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFEAEDF3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-10, size.height / 2), 14, fill);
    canvas.drawCircle(Offset(size.width + 10, size.height / 2), 14, fill);
    final dash = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(14, size.height / 2)
      ..lineTo(size.width - 14, size.height / 2);
    for (final m in path.computeMetrics()) {
      double s = 0;
      while (s < m.length) {
        final e = (s + 6).clamp(0, m.length);
        canvas.drawPath(m.extractPath(s, e.toDouble()), dash);
        s += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
