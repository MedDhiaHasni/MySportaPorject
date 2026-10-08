// lib/Services/schedule_service.dart
// Matches your actual Strapi backend:
//   GET  /week-agendas/court/:courtId   → { dayPlans: [{id, date, dayOfWeek, dayType}] }
//   GET  /day-plans/:id/availability    → { date, dayType, slots: [{id, startTime, endTime, isActive, isBooked}] }
//   POST /day-plans                     → { data: { week_agend, dayOfWeek, dayType, date, openTime?, closeTime? } }
//   PUT  /day-plans/:id                 → { data: { dayOfWeek?, dayType?, date? } }
//   DELETE /day-plans/:id
//   POST /time-slots                    → { data: { day_plan, startTime, endTime, isActive } }
//   POST /time-slots/bulk               → { day_plan, slots: [{startTime, endTime}] }
//   PUT  /time-slots/:id                → { data: { isActive?, startTime?, endTime? } }
//   DELETE /time-slots/:id
//   GET  /week-agendas?courtId=X        → manager list (with day_plans)
//   POST /week-agendas                  → create
//   POST /week-agendas/:id/publish

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sporta/Core/Constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class DayPlanSummary {
  final String id;
  final String? date;
  final String dayOfWeek;
  final String dayType; // normal | day_off | urgent_only | special

  const DayPlanSummary({
    required this.id,
    this.date,
    required this.dayOfWeek,
    required this.dayType,
  });

  factory DayPlanSummary.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    return DayPlanSummary(
      id:         (json['id'] ?? attrs['id'])?.toString() ?? '',
      date:       attrs['date']?.toString(),
      dayOfWeek:  attrs['dayOfWeek']?.toString() ?? '',
      dayType:    attrs['dayType']?.toString()   ?? 'normal',
    );
  }
}

class SlotAvailability {
  final String id;
  final String startTime;
  final String endTime;
  final bool   isActive;
  final bool   isBooked;

  const SlotAvailability({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
  });

  factory SlotAvailability.fromJson(Map<String, dynamic> json) {
    return SlotAvailability(
      id:        json['id']?.toString()          ?? '',
      startTime: json['startTime']?.toString()   ?? '',
      endTime:   json['endTime']?.toString()     ?? '',
      isActive:  json['isActive']  as bool?      ?? true,
      isBooked:  json['isBooked']  as bool?      ?? false,
    );
  }
}

class DayPlanAvailability {
  final String? date;
  final String  dayType;
  final List<SlotAvailability> slots;

  const DayPlanAvailability({this.date, required this.dayType, required this.slots});

  factory DayPlanAvailability.fromJson(Map<String, dynamic> json) {
    return DayPlanAvailability(
      date:    json['date']?.toString(),
      dayType: json['dayType']?.toString() ?? 'normal',
      slots:   (json['slots'] as List? ?? [])
                   .map((s) => SlotAvailability.fromJson(s as Map<String, dynamic>))
                   .toList(),
    );
  }
}

class WeekAgendaSummary {
  final String id;
  final String? weekStartDate;
  final String  statu; // Published | Draft
  final List<DayPlanSummary> dayPlans;

  const WeekAgendaSummary({
    required this.id,
    this.weekStartDate,
    required this.statu,
    required this.dayPlans,
  });

  factory WeekAgendaSummary.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] ?? json) as Map<String, dynamic>;
    final rawDp  = attrs['day_plans'];
    List<DayPlanSummary> plans = [];
    if (rawDp is List) {
      plans = rawDp.map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>)).toList();
    } else if (rawDp is Map && rawDp['data'] is List) {
      plans = (rawDp['data'] as List).map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>)).toList();
    }
    return WeekAgendaSummary(
      id:            (json['id'] ?? attrs['id'])?.toString()         ?? '',
      weekStartDate: attrs['weekStartDate']?.toString(),
      statu:         attrs['statu']?.toString()                      ?? 'Draft',
      dayPlans:      plans,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleService {

  // ── Week agendas ────────────────────────────────────────────────────────────

  /// GET /week-agendas/court/:courtId
  /// Player-accessible. Returns flat list of day plan summaries.
  static Future<List<DayPlanSummary>> fetchDayPlansByCourt(String token, String courtId) async {
    final res = await http.get(
      Uri.parse(ApiConstants.courtDayPlans(courtId)),
      headers: _headers(token),
    );
    _check(res, 'fetchDayPlansByCourt');
    final body = json.decode(res.body);
    final raw  = body['dayPlans'] as List? ?? [];
    return raw.map((d) => DayPlanSummary.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// GET /week-agendas?courtId=X  (manager)
  static Future<List<WeekAgendaSummary>> fetchWeekAgendasByCourt(String token, String courtId) async {
    final res = await http.get(
      Uri.parse(ApiConstants.weekAgendasByCourt(courtId)),
      headers: _headers(token),
    );
    _check(res, 'fetchWeekAgendasByCourt');
    final body = json.decode(res.body);
    final raw  = _extractList(body);
    return raw.map((d) => WeekAgendaSummary.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// POST /week-agendas
  static Future<WeekAgendaSummary> createWeekAgenda(String token, {
    required String courtId,
    required String weekStartDate,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.weekAgendas),
      headers: _jsonHeaders(token),
      body: json.encode({'data': {'court': courtId, 'weekStartDate': weekStartDate, 'statu': 'Draft'}}),
    );
    _check(res, 'createWeekAgenda');
    final body = json.decode(res.body);
    return WeekAgendaSummary.fromJson((body['data'] ?? body) as Map<String, dynamic>);
  }

  /// POST /week-agendas/:id/publish
  static Future<void> publishWeekAgenda(String token, String agendaId) async {
    final res = await http.post(
      Uri.parse(ApiConstants.publishWeekAgenda(agendaId)),
      headers: _jsonHeaders(token),
    );
    _check(res, 'publishWeekAgenda');
  }

  // ── Day plans ───────────────────────────────────────────────────────────────

  /// GET /day-plans/:id/availability
  static Future<DayPlanAvailability> fetchAvailability(String token, String dayPlanId) async {
    final res = await http.get(
      Uri.parse(ApiConstants.dayPlanAvailability(dayPlanId)),
      headers: _headers(token),
    );
    _check(res, 'fetchAvailability');
    final body = json.decode(res.body);
    return DayPlanAvailability.fromJson(body as Map<String, dynamic>);
  }

  /// POST /day-plans
  static Future<DayPlanSummary> createDayPlan(String token, {
    required String weekAgendaId,
    required String dayOfWeek,
    required String dayType,
    String? date,
    String? openTime,
    String? closeTime,
  }) async {
    final payload = <String, dynamic>{
      'week_agend': weekAgendaId,
      'dayOfWeek':  dayOfWeek,
      'dayType':    dayType,
      if (date      != null) 'date':      date,
      if (openTime  != null) 'openTime':  openTime,
      if (closeTime != null) 'closeTime': closeTime,
    };
    final res = await http.post(
      Uri.parse(ApiConstants.dayPlans),
      headers: _jsonHeaders(token),
      body:    json.encode({'data': payload}),
    );
    _check(res, 'createDayPlan');
    final body = json.decode(res.body);
    return DayPlanSummary.fromJson((body['data'] ?? body) as Map<String, dynamic>);
  }

  /// PUT /day-plans/:id
  static Future<DayPlanSummary> updateDayPlan(String token, String id, {
    String? dayOfWeek,
    String? dayType,
    String? date,
    String? openTime,
    String? closeTime,
  }) async {
    final payload = <String, dynamic>{
      if (dayOfWeek  != null) 'dayOfWeek':  dayOfWeek,
      if (dayType    != null) 'dayType':    dayType,
      if (date       != null) 'date':       date,
      if (openTime   != null) 'openTime':   openTime,
      if (closeTime  != null) 'closeTime':  closeTime,
    };
    final res = await http.put(
      Uri.parse(ApiConstants.dayPlan(id)),
      headers: _jsonHeaders(token),
      body:    json.encode({'data': payload}),
    );
    _check(res, 'updateDayPlan');
    final body = json.decode(res.body);
    return DayPlanSummary.fromJson((body['data'] ?? body) as Map<String, dynamic>);
  }

  /// DELETE /day-plans/:id
  static Future<void> deleteDayPlan(String token, String id) async {
    final res = await http.delete(
      Uri.parse(ApiConstants.dayPlan(id)),
      headers: _headers(token),
    );
    _check(res, 'deleteDayPlan');
  }

  // ── Time slots ──────────────────────────────────────────────────────────────

  /// POST /time-slots
  static Future<SlotAvailability> createTimeSlot(String token, {
    required String dayPlanId,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.timeSlots),
      headers: _jsonHeaders(token),
      body: json.encode({'data': {
        'day_plan':  dayPlanId,
        'startTime': startTime,
        'endTime':   endTime,
        'isActive':  isActive,
      }}),
    );
    _check(res, 'createTimeSlot');
    final body = json.decode(res.body);
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    final attrs = data['attributes'] ?? data;
    return SlotAvailability(
      id:        data['id']?.toString()        ?? '',
      startTime: (attrs['startTime'] ?? '')    .toString(),
      endTime:   (attrs['endTime']   ?? '')    .toString(),
      isActive:  attrs['isActive']  as bool?   ?? true,
      isBooked:  false,
    );
  }

  /// POST /time-slots/bulk
  static Future<List<SlotAvailability>> bulkCreateTimeSlots(String token, {
    required String dayPlanId,
    required List<Map<String, String>> slots, // [{startTime, endTime}]
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.timeSlotsBulk),
      headers: _jsonHeaders(token),
      body: json.encode({'day_plan': dayPlanId, 'slots': slots}),
    );
    _check(res, 'bulkCreateTimeSlots');
    final body  = json.decode(res.body);
    final raw   = body['data'] as List? ?? [];
    return raw.map((s) {
      final attrs = (s as Map<String, dynamic>)['attributes'] ?? s;
      return SlotAvailability(
        id:        s['id']?.toString()         ?? '',
        startTime: (attrs['startTime'] ?? '')  .toString(),
        endTime:   (attrs['endTime']   ?? '')  .toString(),
        isActive:  attrs['isActive']   as bool? ?? true,
        isBooked:  false,
      );
    }).toList();
  }

  /// PUT /time-slots/:id
  static Future<void> updateTimeSlot(String token, String id, {
    bool? isActive, String? startTime, String? endTime,
  }) async {
    final payload = <String, dynamic>{
      if (isActive  != null) 'isActive':  isActive,
      if (startTime != null) 'startTime': startTime,
      if (endTime   != null) 'endTime':   endTime,
    };
    final res = await http.put(
      Uri.parse(ApiConstants.timeSlot(id)),
      headers: _jsonHeaders(token),
      body:    json.encode({'data': payload}),
    );
    _check(res, 'updateTimeSlot');
  }

  /// DELETE /time-slots/:id
  static Future<void> deleteTimeSlot(String token, String id) async {
    final res = await http.delete(
      Uri.parse(ApiConstants.timeSlot(id)),
      headers: _headers(token),
    );
    _check(res, 'deleteTimeSlot');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> _jsonHeaders(String token) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $token',
  };

  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'] as List;
      if (body['data'] is Map)  return [body['data']];
    }
    return [];
  }

  static void _check(http.Response res, String method) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[$method] ${res.statusCode}: ${res.body}');
    }
  }
}