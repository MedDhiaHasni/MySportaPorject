// lib/Services/payment_service.dart
// Covers:
//   Player  → createIntent, confirmPayment
//   Manager → getAllPayments (with stats + filters), getPaymentByReservation
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class PaymentIntentResult {
  final bool success;
  final String? clientSecret;
  final String? paymentId;         // Our DB Payment record id
  final String? paymentIntentId;   // Stripe PaymentIntent id
  final String? publishableKey;
  final double? amount;
  final String? currency;
  final String? error;

  const PaymentIntentResult({
    required this.success,
    this.clientSecret,
    this.paymentId,
    this.paymentIntentId,
    this.publishableKey,
    this.amount,
    this.currency,
    this.error,
  });
}

class PaymentConfirmResult {
  final bool success;
  final String status;    // 'succeeded' | 'failed' | 'pending' | 'error'
  final String? message;
  final String? error;

  const PaymentConfirmResult({
    required this.success,
    required this.status,
    this.message,
    this.error,
  });
}

/// A payment record returned from GET /payments (manager view)
class ManagerPaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final String status;          // pending | succeeded | failed
  final String? stripeIntentId;
  final DateTime createdAt;

  // Populated from reservation → court / player
  final String reservationId;
  final String courtName;
  final String venueName;
  final String playerName;
  final String courtImageUrl;
  final String bookingDate;

  const ManagerPaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.stripeIntentId,
    required this.createdAt,
    required this.reservationId,
    required this.courtName,
    required this.venueName,
    required this.playerName,
    required this.courtImageUrl,
    required this.bookingDate,
  });

  factory ManagerPaymentRecord.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final id    = json['id']?.toString() ?? '';

    // --- Reservation tree ---
    final resRaw   = attrs['reservation'];
    final resData  = resRaw is Map ? (resRaw['data'] ?? resRaw) as Map? : null;
    final resAttrs = resData != null ? ((resData['attributes'] ?? resData) as Map<String, dynamic>) : <String, dynamic>{};
    final resId    = resData?['id']?.toString() ?? '';
    final dateStr  = resAttrs['booking_date_play']?.toString().split('T')[0] ?? '';

    // Court
    final cRaw    = resAttrs['court'];
    final cData   = cRaw is Map ? (cRaw['data'] ?? cRaw) as Map? : null;
    final cAttrs  = cData != null ? ((cData['attributes'] ?? cData) as Map<String, dynamic>) : <String, dynamic>{};
    final cName   = cAttrs['name']?.toString() ?? '';

    // Venue
    final vRaw   = cAttrs['venue'];
    final vData  = vRaw is Map ? (vRaw['data'] ?? vRaw) as Map? : null;
    final vAttrs = vData != null ? ((vData['attributes'] ?? vData) as Map<String, dynamic>) : <String, dynamic>{};
    final vName  = vAttrs['name']?.toString() ?? '';

    // Court image — tries court_img_url (enriched by backend), then court_img relation
    String imgUrl = cAttrs['court_img_url']?.toString() ?? '';
    if (imgUrl.isEmpty) {
      final imgRaw  = cAttrs['court_img'];
      final imgData = imgRaw is Map ? (imgRaw['data'] ?? imgRaw) as Map? : null;
      if (imgData != null) {
        final ia  = (imgData['attributes'] ?? imgData) as Map;
        final raw = ia['url']?.toString() ?? '';
        if (raw.isNotEmpty) imgUrl = _fixUrl(raw);
      }
    } else {
      imgUrl = _fixUrl(imgUrl);
    }

    // Player
    final pRaw    = resAttrs['player'];
    final pData   = pRaw is Map ? (pRaw['data'] ?? pRaw) as Map? : null;
    final pAttrs  = pData != null ? ((pData['attributes'] ?? pData) as Map<String, dynamic>) : <String, dynamic>{};
    final authRaw = pAttrs['player'];
    final authData = authRaw is Map ? (authRaw['data'] ?? authRaw) as Map? : null;
    final authAttrs = authData != null ? ((authData['attributes'] ?? authData) as Map<String, dynamic>) : <String, dynamic>{};
    final pName  = authAttrs['username']?.toString() ?? pAttrs['nom']?.toString() ?? 'Player';

    // Created at
    DateTime created = DateTime.now();
    try { created = DateTime.parse(attrs['createdAt']?.toString() ?? ''); } catch (_) {}

    return ManagerPaymentRecord(
      id:             id,
      amount:         (attrs['amount'] as num?)?.toDouble() ?? 0,
      currency:       attrs['currency']?.toString() ?? 'eur',
      status:         attrs['status']?.toString() ?? 'pending',
      stripeIntentId: attrs['stripe_payment_intent_id']?.toString(),
      createdAt:      created,
      reservationId:  resId,
      courtName:      cName,
      venueName:      vName,
      playerName:     pName,
      courtImageUrl:  imgUrl,
      bookingDate:    dateStr,
    );
  }

  static String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.mediaBaseUrl}$url';
  }
}

/// Stats returned alongside the payments list
class PaymentStats {
  final int    total;
  final double totalRevenue;
  final int    pending;
  final int    succeeded;
  final int    failed;

  const PaymentStats({
    required this.total,
    required this.totalRevenue,
    required this.pending,
    required this.succeeded,
    required this.failed,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) => PaymentStats(
    total:        (json['total']        as num?)?.toInt()    ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    pending:      (json['pending']      as num?)?.toInt()    ?? 0,
    succeeded:    (json['succeeded']    as num?)?.toInt()    ?? 0,
    failed:       (json['failed']       as num?)?.toInt()    ?? 0,
  );

  factory PaymentStats.empty() => const PaymentStats(total: 0, totalRevenue: 0, pending: 0, succeeded: 0, failed: 0);
}

/// Result of getAllPayments
class PaymentListResult {
  final bool success;
  final List<ManagerPaymentRecord> payments;
  final PaymentStats stats;
  final int total;
  final String? error;

  const PaymentListResult({
    required this.success,
    required this.payments,
    required this.stats,
    required this.total,
    this.error,
  });

  factory PaymentListResult.error(String msg) => PaymentListResult(
    success: false, payments: [], stats: PaymentStats.empty(), total: 0, error: msg);
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class PaymentService {
  final String token;
  PaymentService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Player: POST /payments/create-intent ──────────────────────────────────
  /// Creates a Stripe PaymentIntent.
  /// Returns [clientSecret] to pass to flutter_stripe.
  Future<PaymentIntentResult> createIntent(String reservationId) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConstants.createPaymentIntent),
        headers: _headers,
        body: json.encode({'reservationId': reservationId}),
      ).timeout(const Duration(seconds: 20));

      final data = json.decode(r.body) as Map<String, dynamic>;

      if (r.statusCode == 200 && data['success'] == true) {
        return PaymentIntentResult(
          success:         true,
          clientSecret:    data['clientSecret']    as String?,
          paymentId:       data['paymentId']?.toString(),
          paymentIntentId: data['paymentIntentId'] as String?,
          publishableKey:  data['publishableKey']  as String?,
          amount:          (data['amount'] as num?)?.toDouble(),
          currency:        data['currency']        as String?,
        );
      }
      return PaymentIntentResult(
        success: false,
        error:   data['error']?['message']?.toString() ?? data['message']?.toString() ?? 'Failed to create payment',
      );
    } catch (e) {
      return PaymentIntentResult(success: false, error: e.toString());
    }
  }

  // ── Player: POST /payments/:id/confirm ────────────────────────────────────
  /// Verifies the payment with Stripe server-side and confirms the reservation.
  /// Call this AFTER flutter_stripe presents the payment sheet successfully.
  Future<PaymentConfirmResult> confirmPayment(String paymentId) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConstants.confirmPayment(paymentId)),
        headers: _headers,
      ).timeout(const Duration(seconds: 20));

      final data = json.decode(r.body) as Map<String, dynamic>;

      if (r.statusCode == 200) {
        return PaymentConfirmResult(
          success: data['success'] == true,
          status:  data['status']  as String? ?? 'unknown',
          message: data['message'] as String?,
        );
      }
      return PaymentConfirmResult(
        success: false, status: 'failed',
        error: data['error']?['message']?.toString() ?? data['message']?.toString() ?? 'Confirmation failed',
      );
    } catch (e) {
      return PaymentConfirmResult(success: false, status: 'error', error: e.toString());
    }
  }

  // ── Manager / Admin: GET /payments ────────────────────────────────────────
  /// Returns all payments for the manager's courts with stats.
  ///
  /// [status] — optional filter: 'pending' | 'succeeded' | 'failed'
  /// [limit]  — page size (default 100)
  /// [page]   — 1-based page number (default 1)
  Future<PaymentListResult> getAllPayments({
    String? status,
    int limit = 100,
    int page  = 1,
  }) async {
    try {
      final url = ApiConstants.paymentsFiltered(status: status, limit: limit, page: page);
      final r   = await http.get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (r.statusCode == 200) {
        final body     = json.decode(r.body) as Map<String, dynamic>;
        final rawList  = (body['payments'] as List<dynamic>? ?? []);
        final rawStats = body['stats']     as Map<String, dynamic>? ?? {};

        return PaymentListResult(
          success:  true,
          payments: rawList.map((j) => ManagerPaymentRecord.fromJson(j as Map<String, dynamic>)).toList(),
          stats:    PaymentStats.fromJson(rawStats),
          total:    (body['total'] as num?)?.toInt() ?? rawList.length,
        );
      }

      final err = _decodeError(r.body);
      return PaymentListResult.error(err ?? 'Failed to load payments (${r.statusCode})');
    } catch (e) {
      return PaymentListResult.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Player / Manager: GET /payments/reservation/:id ───────────────────────
  /// Returns the latest payment record for a given reservation id.
  /// Returns null if no payment exists yet.
  Future<Map<String, dynamic>?> getPaymentByReservation(String reservationId) async {
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.paymentByReservation(reservationId)),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final body = json.decode(r.body) as Map<String, dynamic>;
        return body['payment'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _decodeError(String body) {
    try {
      final m = json.decode(body) as Map<String, dynamic>;
      return m['error']?['message']?.toString() ?? m['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}


