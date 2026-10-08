import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AvailabilitySlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;

  const AvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
  });

  bool get isAvailable => isActive && !isBooked;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
    id:        json['id'] as int,
    startTime: json['startTime']?.toString() ?? '',
    endTime:   json['endTime']?.toString() ?? '',
    isActive:  json['isActive'] == true,
    isBooked:  json['isBooked'] == true,
  );
}

class DayAvailability {
  final String date;
  final String dayType;
  final List<AvailabilitySlot> slots;

  const DayAvailability({
    required this.date,
    required this.dayType,
    required this.slots,
  });

  bool get isBookable => dayType != 'day_off';

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return DayAvailability(
      date:    json['date']?.toString() ?? '',
      dayType: json['dayType']?.toString() ?? 'normal',
      slots:   rawSlots.map((s) => AvailabilitySlot.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class DayPlanSummary {
  final int id;
  final String date;
  final String dayOfWeek;
  final String dayType;

  const DayPlanSummary({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.dayType,
  });

  factory DayPlanSummary.fromJson(Map<String, dynamic> json) => DayPlanSummary(
    id:        (json['id'] as num).toInt(),
    date:      json['date']?.toString() ?? '',
    dayOfWeek: json['dayOfWeek']?.toString() ?? '',
    dayType:   json['dayType']?.toString() ?? 'normal',
  );
}

class BookingResult {
  final int    reservationId;
  final String bookingReference;
  final String status;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String paymentMethod;

  const BookingResult({
    required this.reservationId,
    required this.bookingReference,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.paymentMethod,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    final raw   = json['data'] ?? json;
    final attrs = raw['attributes'] ?? raw;
    return BookingResult(
      reservationId:    (raw['id'] as num?)?.toInt() ?? 0,
      bookingReference: attrs['booking_reference']?.toString() ?? '',
      status:           attrs['booking_status']?.toString() ?? 'pending',
      startTime:        attrs['start_time']?.toString() ?? '',
      endTime:          attrs['end_time']?.toString() ?? '',
      totalPrice:       (attrs['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod:    attrs['payment_method']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ReservationService {
  final String _token;
  ReservationService({required String token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ── Fetch day plans for a court ───────────────────────────────────────────
  Future<List<DayPlanSummary>> fetchDayPlansForCourt(String courtId) async {
    final res = await http.get(
      Uri.parse(ApiConstants.courtDayPlans(courtId)),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load schedule: ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['dayPlans'] as List<dynamic>? ?? [];
    return list.map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>)).toList();
  }

  // ── Fetch availability for a specific day plan ────────────────────────────
  Future<DayAvailability> fetchAvailability(int dayPlanId) async {
    final res = await http.get(
      Uri.parse(ApiConstants.dayPlanAvailability(dayPlanId.toString())),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load slots: ${res.statusCode}');
    }
    return DayAvailability.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  // ── Create a reservation ──────────────────────────────────────────────────
  Future<BookingResult> createReservation({
    required int    timeSlotId,
    required int    courtId,
    required String bookingDatePlay,
    required String startTime,
    required String endTime,
    required double durationHours,
    required double totalPrice,
    required String paymentMethod,
    String? specialRequests,
  }) async {
    // Format time to HH:MM:SS format (backend expects time format)
    String formatTime(String time) {
      if (time.contains(':')) {
        // If time is like "14:30", add ":00" seconds
        final parts = time.split(':');
        if (parts.length == 2) {
          return '${parts[0]}:${parts[1]}:00';
        }
        return time;
      }
      return '$time:00';
    }

    final requestBody = {
      'time_slot': timeSlotId,
      'court': courtId,
      'booking_date_play': bookingDatePlay,
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
    };

    if (specialRequests != null && specialRequests.isNotEmpty) {
      requestBody['special_requests'] = specialRequests;
    }

    print('📡 Creating reservation with body: ${json.encode(requestBody)}');

    final res = await http.post(
      Uri.parse(ApiConstants.reservations),
      headers: _headers,
      body: json.encode({'data': requestBody}),
    );

    print('📡 Response status: ${res.statusCode}');
    print('📡 Response body: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return BookingResult.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }

    String msg = 'Booking failed (${res.statusCode})';
    try {
      final err = json.decode(res.body);
      msg = err['error']?['message'] ?? err['message'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  // ── REQUEST CANCEL (Player only) ───────────────────────────────────────────────
  Future<void> requestCancel(String reservationId, {String? reason}) async {
    final res = await http.put(
      Uri.parse(ApiConstants.requestCancelReservation(reservationId)),
      headers: _headers,
      body: json.encode({'reason': reason?.trim() ?? ''}),
    );

    if (res.statusCode != 200) {
      String msg = 'Failed to request cancellation (${res.statusCode})';
      try {
        final err = json.decode(res.body);
        msg = err['error']?['message'] ?? err['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ── CANCEL (Worker/Manager approves cancel request) ───────────────────────
  Future<void> cancelReservation(String reservationId) async {
    final res = await http.put(
      Uri.parse(ApiConstants.cancelReservation(reservationId)),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to cancel: ${res.statusCode}');
    }
  }

  // ── Get all reservations for current user ─────────────────────────────────
  Future<Map<String, dynamic>?> getUserReservations() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.reservations}'
          '?populate[court][populate][venue]=*'
          '&populate[court][populate][court_img]=*'
          '&populate[time_slot]=*',
        ),
        headers: _headers,
      );
      if (response.statusCode != 200) return null;
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}












/*// lib/Services/reservation_service.dart
// Uses separate announcement system (no announcements stored on reservations)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AvailabilitySlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;

  const AvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
  });

  bool get isAvailable => isActive && !isBooked;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
    id:        json['id'] as int,
    startTime: json['startTime']?.toString() ?? '',
    endTime:   json['endTime']?.toString() ?? '',
    isActive:  json['isActive'] == true,
    isBooked:  json['isBooked'] == true,
  );
}

class DayAvailability {
  final String date;
  final String dayType; // normal | urgent_only | day_off
  final List<AvailabilitySlot> slots;

  const DayAvailability({
    required this.date,
    required this.dayType,
    required this.slots,
  });

  bool get isBookable => dayType != 'day_off';

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return DayAvailability(
      date:    json['date']?.toString() ?? '',
      dayType: json['dayType']?.toString() ?? 'normal',
      slots:   rawSlots.map((s) => AvailabilitySlot.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class DayPlanSummary {
  final int id;
  final String date;
  final String dayOfWeek;
  final String dayType;

  const DayPlanSummary({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.dayType,
  });

  factory DayPlanSummary.fromJson(Map<String, dynamic> json) => DayPlanSummary(
    id:         (json['id'] as num).toInt(),
    date:       json['date']?.toString() ?? '',
    dayOfWeek:  json['dayOfWeek']?.toString() ?? '',
    dayType:    json['dayType']?.toString() ?? 'normal',
  );
}

class BookingResult {
  final int    reservationId;
  final String bookingReference;
  final String status;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String paymentMethod;

  const BookingResult({
    required this.reservationId,
    required this.bookingReference,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.paymentMethod,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    // Handle { data: { id, attributes: {...} } } OR flat object
    final raw   = json['data'] ?? json;
    final attrs = raw['attributes'] ?? raw;
    return BookingResult(
      reservationId:    (raw['id'] as num?)?.toInt() ?? 0,
      bookingReference: attrs['booking_reference']?.toString() ?? '',
      status:           attrs['booking_status']?.toString() ?? 'pending',
      startTime:        attrs['start_time']?.toString() ?? '',
      endTime:          attrs['end_time']?.toString() ?? '',
      totalPrice:       (attrs['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod:    attrs['payment_method']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ReservationService {
  final String _token;

  ReservationService({required String token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ── Fetch day plans for a court ───────────────────────────────────────────
  // Uses GET /week-agendas/court/:courtId  (player-accessible, no isManager)
  // Returns a flat list of DayPlanSummary sorted by date ascending
  Future<List<DayPlanSummary>> fetchDayPlansForCourt(String courtId) async {
    final uri = Uri.parse(ApiConstants.courtDayPlans(courtId));
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load schedule: ${res.statusCode}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final list  = body['dayPlans'] as List<dynamic>? ?? [];

    return list
        .map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch availability for a specific day plan ────────────────────────────
  // GET /day-plans/:id/availability  — policy: authMiddleware only ✓
  Future<DayAvailability> fetchAvailability(int dayPlanId) async {
    final uri = Uri.parse(ApiConstants.dayPlanAvailability(dayPlanId.toString()));
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load slots: ${res.statusCode}');
    }
    return DayAvailability.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  // ── Create a reservation ──────────────────────────────────────────────────
  // POST /reservations  — policy: authMiddleware + isPlayer ✓
  Future<BookingResult> createReservation({
    required int    timeSlotId,
    required int    courtId,
    required String bookingDatePlay,  // yyyy-MM-dd
    required String startTime,        // HH:mm
    required String endTime,          // HH:mm
    required double durationHours,
    required double totalPrice,
    required String paymentMethod,    // pay_now | pay_at_venue
    String? specialRequests,
  }) async {
    final body = json.encode({
      'data': {
        'time_slot':        timeSlotId,
        'court':            courtId,
        'booking_date_play': bookingDatePlay,
        'start_time':       startTime,
        'end_time':         endTime,
        'duration_hours':   durationHours,
        'total_price':      totalPrice,
        'payment_method':   paymentMethod,
        if (specialRequests != null && specialRequests.isNotEmpty)
          'special_requests': specialRequests,
      },
    });

    final res = await http.post(
      Uri.parse(ApiConstants.reservations),
      headers: _headers,
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return BookingResult.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }

    // Parse Strapi error message
    String msg = 'Booking failed (${res.statusCode})';
    try {
      final err = json.decode(res.body);
      msg = err['error']?['message'] ?? err['message'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  // ── Cancel a reservation ──────────────────────────────────────────────────
  // PUT /reservations/:id/cancel  — policy: authMiddleware ✓
  Future<void> cancelReservation(int reservationId) async {
    final res = await http.put(
      Uri.parse(ApiConstants.cancelReservation(reservationId.toString())),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to cancel: ${res.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANNOUNCEMENT METHODS - Uses new separate announcement system
  // Announcements are now a separate collection type, not stored on reservations
  // ─────────────────────────────────────────────────────────────────────────

  // REMOVED: addAnnouncementToReservation() - Use AnnouncementService.create() instead
  // REMOVED: getAllAnnouncements() - Use AnnouncementService.fetchFeed() or fetchMine() instead  
  // REMOVED: deleteAnnouncementFromReservation() - Use AnnouncementService.delete() instead

  // ─────────────────────────────────────────────────────────────────────────
  // Helper method to get all reservations (for other features)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get all reservations for the current user with full population
  Future<Map<String, dynamic>?> getUserReservations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.reservations}?populate[court][populate][venue]=*&populate[court][populate][photo]=*&populate[time_slot]=*'),
        headers: _headers,
      );
      
      if (response.statusCode != 200) {
        print('Failed to get reservations: ${response.statusCode}');
        return null;
      }
      
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting reservations: $e');
      return null;
    }
  }
  
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}
*/















/*// lib/Services/reservation_service.dart
// Fixed: uses GET /week-agendas/court/:courtId (player-accessible, no isManager)
// instead of GET /week-agendas?courtId=... which was returning 403

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AvailabilitySlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;

  const AvailabilitySlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
  });

  bool get isAvailable => isActive && !isBooked;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
    id:        json['id'] as int,
    startTime: json['startTime']?.toString() ?? '',
    endTime:   json['endTime']?.toString() ?? '',
    isActive:  json['isActive'] == true,
    isBooked:  json['isBooked'] == true,
  );
}

class DayAvailability {
  final String date;
  final String dayType; // normal | urgent_only | day_off
  final List<AvailabilitySlot> slots;

  const DayAvailability({
    required this.date,
    required this.dayType,
    required this.slots,
  });

  bool get isBookable => dayType != 'day_off';

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return DayAvailability(
      date:    json['date']?.toString() ?? '',
      dayType: json['dayType']?.toString() ?? 'normal',
      slots:   rawSlots.map((s) => AvailabilitySlot.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class DayPlanSummary {
  final int id;
  final String date;
  final String dayOfWeek;
  final String dayType;

  const DayPlanSummary({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.dayType,
  });

  factory DayPlanSummary.fromJson(Map<String, dynamic> json) => DayPlanSummary(
    id:         (json['id'] as num).toInt(),
    date:       json['date']?.toString() ?? '',
    dayOfWeek:  json['dayOfWeek']?.toString() ?? '',
    dayType:    json['dayType']?.toString() ?? 'normal',
  );
}

class BookingResult {
  final int    reservationId;
  final String bookingReference;
  final String status;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String paymentMethod;

  const BookingResult({
    required this.reservationId,
    required this.bookingReference,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.paymentMethod,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    // Handle { data: { id, attributes: {...} } } OR flat object
    final raw   = json['data'] ?? json;
    final attrs = raw['attributes'] ?? raw;
    return BookingResult(
      reservationId:    (raw['id'] as num?)?.toInt() ?? 0,
      bookingReference: attrs['booking_reference']?.toString() ?? '',
      status:           attrs['booking_status']?.toString() ?? 'pending',
      startTime:        attrs['start_time']?.toString() ?? '',
      endTime:          attrs['end_time']?.toString() ?? '',
      totalPrice:       (attrs['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod:    attrs['payment_method']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ReservationService {
  final String _token;

  ReservationService({required String token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ── Fetch day plans for a court ───────────────────────────────────────────
  // Uses GET /week-agendas/court/:courtId  (player-accessible, no isManager)
  // Returns a flat list of DayPlanSummary sorted by date ascending
  Future<List<DayPlanSummary>> fetchDayPlansForCourt(String courtId) async {
    final uri = Uri.parse(ApiConstants.courtDayPlans(courtId));
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load schedule: ${res.statusCode}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final list  = body['dayPlans'] as List<dynamic>? ?? [];

    return list
        .map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch availability for a specific day plan ────────────────────────────
  // GET /day-plans/:id/availability  — policy: authMiddleware only ✓
  Future<DayAvailability> fetchAvailability(int dayPlanId) async {
    final uri = Uri.parse(ApiConstants.dayPlanAvailability(dayPlanId.toString()));
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load slots: ${res.statusCode}');
    }
    return DayAvailability.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  // ── Create a reservation ──────────────────────────────────────────────────
  // POST /reservations  — policy: authMiddleware + isPlayer ✓
  Future<BookingResult> createReservation({
    required int    timeSlotId,
    required int    courtId,
    required String bookingDatePlay,  // yyyy-MM-dd
    required String startTime,        // HH:mm
    required String endTime,          // HH:mm
    required double durationHours,
    required double totalPrice,
    required String paymentMethod,    // pay_now | pay_at_venue
    String? specialRequests,
  }) async {
    final body = json.encode({
      'data': {
        'time_slot':        timeSlotId,
        'court':            courtId,
        'booking_date_play': bookingDatePlay,
        'start_time':       startTime,
        'end_time':         endTime,
        'duration_hours':   durationHours,
        'total_price':      totalPrice,
        'payment_method':   paymentMethod,
        if (specialRequests != null && specialRequests.isNotEmpty)
          'special_requests': specialRequests,
      },
    });

    final res = await http.post(
      Uri.parse(ApiConstants.reservations),
      headers: _headers,
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return BookingResult.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }

    // Parse Strapi error message
    String msg = 'Booking failed (${res.statusCode})';
    try {
      final err = json.decode(res.body);
      msg = err['error']?['message'] ?? err['message'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  // ── Cancel a reservation ──────────────────────────────────────────────────
  // PUT /reservations/:id/cancel  — policy: authMiddleware ✓
  Future<void> cancelReservation(int reservationId) async {
    final res = await http.put(
      Uri.parse(ApiConstants.cancelReservation(reservationId.toString())),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to cancel: ${res.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD ANNOUNCEMENT TO RESERVATION - Uses new backend endpoint
  // PUT /reservations/:id/needed-players
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addAnnouncementToReservation({
    required String reservationId,
    required String announcementText,
    required int playersNeeded,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.updateNeededPlayers(reservationId)),
        headers: _headers,
        body: json.encode({
          'data': {
            'neededPlayers': playersNeeded,
            'announcementText': announcementText,
          }
        }),
      );
      
      if (response.statusCode != 200) {
        print('Failed to add announcement: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to add announcement');
      }
      
      final responseData = json.decode(response.body);
      print('Announcement added successfully: $responseData');
      
      return {
        'success': true,
        'announcement': responseData['announcement'],
      };
    } catch (e) {
      print('Error adding announcement: $e');
      throw Exception(e.toString());
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL ANNOUNCEMENTS FROM USER'S RESERVATIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllAnnouncements() async {
    try {
      // Get user's reservations with populate
      final response = await http.get(
        Uri.parse('${ApiConstants.reservations}?populate[court][populate][venue]=*&populate[court][populate][photo]=*'),
        headers: _headers,
      );
      
      if (response.statusCode != 200) {
        print('Failed to get reservations: ${response.statusCode}');
        return [];
      }
      
      final responseData = json.decode(response.body);
      final List<dynamic> reservations = responseData['data'] ?? [];
      
      final List<Map<String, dynamic>> allAnnouncements = [];
      
      for (final res in reservations) {
        final attributes = res['attributes'] ?? res;
        final neededPlayers = attributes['needed_players'];
        final specialRequests = attributes['special_requests'] ?? '';
        
        // Check if there's an active announcement
        if (neededPlayers != null && neededPlayers > 0) {
          // Try to get announcement text from special_requests
          String description = '';
          if (specialRequests.isNotEmpty) {
            try {
              final parsed = json.decode(specialRequests);
              if (parsed is List && parsed.isNotEmpty) {
                description = parsed[0]['text'] ?? '';
              }
            } catch (e) {
              description = '';
            }
          }
          
          // Get court and venue info
          final courtData = attributes['court']?['data'] ?? attributes['court'];
          String courtName = '';
          String venueName = '';
          String sport = '';
          String courtImageUrl = '';
          String date = '';
          String time = '';
          
          if (courtData != null) {
            final courtAttrs = courtData['attributes'] ?? courtData;
            courtName = courtAttrs['name'] ?? '';
            sport = courtAttrs['sport'] ?? '';
            
            // Get venue from court
            final venueData = courtAttrs['venue']?['data'] ?? courtAttrs['venue'];
            if (venueData != null) {
              final venueAttrs = venueData['attributes'] ?? venueData;
              venueName = venueAttrs['name'] ?? '';
            }
            
            // Get court image
            final photoData = courtAttrs['photo']?['data'] ?? courtAttrs['photo'];
            if (photoData != null) {
              final photoAttrs = photoData['attributes'] ?? photoData;
              final url = photoAttrs['url'] ?? '';
              if (url.isNotEmpty) {
                courtImageUrl = '${ApiConstants.mediaBaseUrl}$url';
              }
            }
          }
          
          // Format date
          final bookingDate = attributes['booking_date_play'];
          if (bookingDate != null) {
            try {
              final dateObj = DateTime.parse(bookingDate);
              date = _formatDate(dateObj);
            } catch (e) {
              date = bookingDate.toString();
            }
          }
          
          // Format time
          final startTime = attributes['start_time'] ?? '';
          final endTime = attributes['end_time'] ?? '';
          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            time = '$startTime – $endTime';
          }
          
          allAnnouncements.add({
            'id': 'ann_${res['id']}',
            'bookingId': res['id'].toString(),
            'courtName': courtName,
            'venueName': venueName,
            'sport': sport,
            'date': date,
            'time': time,
            'courtImageUrl': courtImageUrl,
            'description': description,
            'playersNeeded': neededPlayers,
            'joined': 0,
            'createdAt': attributes['createdAt'],
            'active': true,
          });
        }
      }
      
      // Sort by newest first
      allAnnouncements.sort((a, b) {
        final aDate = a['createdAt'] ?? '';
        final bDate = b['createdAt'] ?? '';
        return bDate.compareTo(aDate);
      });
      
      print('Found ${allAnnouncements.length} announcements');
      return allAnnouncements;
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // DELETE ANNOUNCEMENT FROM RESERVATION - Uses new backend endpoint
  // DELETE /reservations/:id/announcement
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> deleteAnnouncementFromReservation({
    required String reservationId,
    required String announcementId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.deleteAnnouncement(reservationId)),
        headers: _headers,
        body: json.encode({
          'data': {
            'announcementId': announcementId,
          }
        }),
      );
      
      if (response.statusCode != 200) {
        print('Failed to delete announcement: ${response.statusCode}');
        throw Exception('Failed to delete announcement');
      }
      
      print('Announcement deleted successfully');
    } catch (e) {
      print('Error deleting announcement: $e');
      throw Exception(e.toString());
    }
  }
  
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}*/