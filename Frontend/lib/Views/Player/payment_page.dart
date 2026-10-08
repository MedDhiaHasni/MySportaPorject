/*// lib/Views/Player/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/payment_service.dart';
import 'package:sporta/Services/reservation_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Models/app_models.dart';

class PaymentPage extends StatefulWidget {
  final String courtName;
  final String venueName;
  final String courtImageUrl;
  final String sport;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double price;
  final int courtId;
  final int timeSlotId;
  final String? playerToken;

  const PaymentPage({
    super.key,
    required this.courtName,
    required this.venueName,
    required this.courtImageUrl,
    required this.sport,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.courtId,
    required this.timeSlotId,
    required this.playerToken,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  late ReservationService _reservationService;
  late PaymentService _paymentService;
  BookingResult? _createdReservation;

  @override
  void initState() {
    super.initState();
    _reservationService = ReservationService(token: widget.playerToken ?? '');
    _paymentService = PaymentService(authToken: widget.playerToken);
    _initStripe();
  }

  Future<void> _initStripe() async {
    await PaymentService.initStripe(
      publishableKey: 'pk_test_YOUR_PUBLISHABLE_KEY', // Replace with your actual publishable key
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Step 1: Create reservation FIRST (with pending status)
      final reservation = await _reservationService.createReservation(
        timeSlotId: widget.timeSlotId,
        courtId: widget.courtId,
        bookingDatePlay: DateFormat('yyyy-MM-dd').format(widget.date),
        startTime: widget.startTime,
        endTime: widget.endTime,
        durationHours: 1.0,
        totalPrice: widget.price,
        paymentMethod: 'pay_now',
      );
      
      _createdReservation = reservation;
      print('✅ Reservation created with ID: ${reservation.reservationId}');

      // Step 2: Create payment intent with the REAL reservation ID
      final paymentIntent = await _paymentService.createPaymentIntent(
        reservationId: reservation.reservationId,  // Use REAL reservation ID
        amount: widget.price,
        currency: 'eur',
      );

      if (paymentIntent == null || !paymentIntent['success']) {
        throw Exception(paymentIntent?['error'] ?? 'Failed to initialize payment');
      }

      // Step 3: Present payment sheet
      final paymentResult = await _paymentService.presentPaymentSheet(
        clientSecret: paymentIntent['clientSecret'],
        amount: widget.price,
        currency: 'eur',
      );

      if (!paymentResult['success']) {
        // Payment failed or cancelled - we need to cancel the reservation
        await _reservationService.cancelReservation(reservation.reservationId);
        throw Exception(paymentResult['error'] ?? 'Payment cancelled or failed');
      }

      // Step 4: Confirm payment on backend
      final confirmResult = await _paymentService.confirmPayment(
        paymentIntentId: paymentIntent['paymentIntentId'],
        reservationId: reservation.reservationId,
      );

      if (!confirmResult['success']) {
        throw Exception(confirmResult['error'] ?? 'Payment confirmation failed');
      }

      if (!mounted) return;

      // Step 5: Add to booking store
      final localBooking = LocalBooking(
        id: reservation.reservationId.toString(),
        courtName: widget.courtName,
        venueName: widget.venueName,
        courtImageUrl: widget.courtImageUrl,
        sport: widget.sport,
        date: DateFormat('EEE, d MMM').format(widget.date),
        dateRaw: DateFormat('yyyy-MM-dd').format(widget.date),
        time: '${widget.startTime} – ${widget.endTime}',
        price: reservation.totalPrice.toInt(),
        status: 'confirmed',
        reference: reservation.bookingReference,
        paymentMethod: 'pay_now',
      );
      BookingStore.instance.addBooking(localBooking);

      // Navigate to success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              reservation: reservation,
              courtName: widget.courtName,
              venueName: widget.venueName,
              date: widget.date,
              startTime: widget.startTime,
              endTime: widget.endTime,
              price: widget.price,
              bookingReference: reservation.bookingReference,
            ),
          ),
        );
      }
    } catch (e) {
      // If payment failed and we have a reservation, cancel it
      if (_createdReservation != null) {
        try {
          await _reservationService.cancelReservation(_createdReservation!.reservationId);
        } catch (cancelError) {
          print('Error cancelling reservation: $cancelError');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(widget.date);
    final formattedTime = '${widget.startTime} - ${widget.endTime}';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Booking Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: widget.courtImageUrl.isNotEmpty
                              ? Image.network(
                                  widget.courtImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: kPrimary.withOpacity(0.1),
                                    child: const Icon(Icons.stadium_rounded, color: kPrimary),
                                  ),
                                )
                              : Container(
                                  color: kPrimary.withOpacity(0.1),
                                  child: const Icon(Icons.stadium_rounded, color: kPrimary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.courtName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.venueName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _SummaryRow(Icons.calendar_today_rounded, 'Date', formattedDate),
                  const SizedBox(height: 12),
                  _SummaryRow(Icons.access_time_rounded, 'Time', formattedTime),
                  const SizedBox(height: 12),
                  _SummaryRow(Icons.sports_rounded, 'Sport', widget.sport),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      Text(
                        '${widget.price.toInt()} DT',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment Method Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: kPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: kPrimary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [kPrimary.withOpacity(0.05), Colors.white],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.credit_card, size: 24, color: kPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit / Debit Card',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kTextDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Visa, Mastercard, American Express',
                                style: TextStyle(fontSize: 11, color: kTextMid),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.lock_outline_rounded, color: kPrimary, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 14, color: kTextMid),
                      const SizedBox(width: 6),
                      Text(
                        'Secure payment powered by Stripe',
                        style: TextStyle(fontSize: 11, color: kTextMid),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Pay Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _isProcessing ? null : _processPayment,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, Color(0xFF007B7D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Pay ${widget.price.toInt()} DT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextLight),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: kTextMid),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT SUCCESS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class PaymentSuccessPage extends StatelessWidget {
  final BookingResult reservation;
  final String courtName;
  final String venueName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double price;
  final String bookingReference;

  const PaymentSuccessPage({
    super.key,
    required this.reservation,
    required this.courtName,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.bookingReference,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(date);
    final formattedTime = '$startTime - $endTime';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGreen.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: kGreen,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kTextDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your booking has been confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextMid,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Booking Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SuccessRow('Booking Reference', bookingReference),
                          const Divider(),
                          _SuccessRow('Court', courtName),
                          const Divider(),
                          _SuccessRow('Venue', venueName),
                          const Divider(),
                          _SuccessRow('Date', formattedDate),
                          const Divider(),
                          _SuccessRow('Time', formattedTime),
                          const Divider(),
                          _SuccessRow('Total Paid', '${price.toInt()} DT'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kPrimary.withOpacity(0.3)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kPrimary, Color(0xFF007B7D)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'View My Bookings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: kTextMid,
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
}*/