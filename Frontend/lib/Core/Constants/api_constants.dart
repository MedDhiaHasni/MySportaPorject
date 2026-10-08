// lib/Core/Constants/api_constants.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:1337/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:1337/api';
    if (Platform.isIOS) return 'http://localhost:1337/api';
    return 'http://192.168.1.100:1337/api';
  }

  static String get mediaBaseUrl {
    final url = baseUrl;
    return url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
  static String get login       => '$baseUrl/auth/login';
  static String get register    => '$baseUrl/auth/register';
  static String get forgot      => '$baseUrl/auth/forgot';
  static String get reset       => '$baseUrl/auth/reset';
  static String get change      => '$baseUrl/auth/change';
  static String get me          => '$baseUrl/auth/me';
  static String get update      => '$baseUrl/auth/update';
  static String get uploadPhoto => '$baseUrl/auth/upload-photo';

  // ── Admin ───────────────────────────────────────────────────────────────────
  static String get adminManagers        => '$baseUrl/admin/managers';
  static String get adminPlayers         => '$baseUrl/admin/players';
  static String adminManager(String id)  => '$baseUrl/admin/manager/$id';
  static String get adminRegisterManager => '$baseUrl/admin/register-manager';

  // ── Admin Worker Management ──────────────────────────────────────────────────
  static String get adminRegisterWorker => '$baseUrl/admin/register-worker';
  static String get adminWorkers        => '$baseUrl/admin/workers';
  static String adminWorker(String id)  => '$baseUrl/admin/workers/$id';

  // ── Manager Worker Management ────────────────────────────────────────────────
  static String get managerMyWorkers          => '$baseUrl/managers/me/workers';
  static String managerWorker(String id)      => '$baseUrl/managers/workers/$id';
  static String assignWorkerCourts(String id) => '$baseUrl/managers/workers/$id/assign-courts';
  static String removeWorkerFromCourt(String workerId, String courtId)
      => '$baseUrl/managers/workers/$workerId/courts/$courtId';

  // ── User Photos ─────────────────────────────────────────────────────────────
  static String get managerUserPhoto => '$baseUrl/managers/user';
  static String get playerUserPhoto  => '$baseUrl/players/user';
  static String get workerUserPhoto  => '$baseUrl/workers/user';

  // ── Worker Self-Service ──────────────────────────────────────────────────────
  static String get workerMe                   => '$baseUrl/workers/me';
  static String get workerUpdateProfile        => '$baseUrl/workers/me/profile';
  static String get workerMyCourts             => '$baseUrl/workers/me/courts';
  static String get workerMyReservations       => '$baseUrl/workers/me/reservations';
  static String get workerUpcomingReservations => '$baseUrl/workers/me/reservations/upcoming';
  static String workerConfirmReservation(String id) => '$baseUrl/workers/me/reservations/$id/confirm';
  static String workerCancelReservation(String id)  => '$baseUrl/workers/me/reservations/$id/cancel';
  static String get workerMyTimeSlots          => '$baseUrl/workers/me/time-slots';
  static String workerTimeSlot(String id)      => '$baseUrl/workers/me/time-slots/$id';
  static String get workerUpdateFirebase       => '$baseUrl/workers/me/firebase';

  // ── Upload ──────────────────────────────────────────────────────────────────
  static String get upload => '$mediaBaseUrl/api/upload';

  // ── Venues ──────────────────────────────────────────────────────────────────
  static String get managerVenues                  => '$baseUrl/venues';
  static String managerVenue(String id)            => '$baseUrl/venues/$id';
  static String managerVenueCourts(String venueId) => '$baseUrl/venues/$venueId/courts';
  static String get publicVenues                   => '$baseUrl/public/venues';

  // ── Courts ──────────────────────────────────────────────────────────────────
  static String get managerCourts       => '$baseUrl/courts';
  static String managerCourt(String id) => '$baseUrl/courts/$id';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$mediaBaseUrl$path';
  }

  // ── Week Agendas ─────────────────────────────────────────────────────────────
  static String get weekAgendas                    => '$baseUrl/week-agendas';
  static String weekAgenda(String id)              => '$baseUrl/week-agendas/$id';
  static String publishWeekAgenda(String id)       => '$baseUrl/week-agendas/$id/publish';
  static String weekAgendasByCourt(String courtId) => '$baseUrl/week-agendas?courtId=$courtId';
  static String courtDayPlans(String courtId)      => '$baseUrl/week-agendas/court/$courtId';

  // ── Day Plans ────────────────────────────────────────────────────────────────
  static String get dayPlans                          => '$baseUrl/day-plans';
  static String dayPlan(String id)                    => '$baseUrl/day-plans/$id';
  static String dayPlanAvailability(String id)        => '$baseUrl/day-plans/$id/availability';
  static String dayPlansByWeekAgenda(String agendaId) => '$baseUrl/day-plans?weekAgendaId=$agendaId';

  // ── Time Slots ───────────────────────────────────────────────────────────────
  static String get timeSlots                        => '$baseUrl/time-slots';
  static String timeSlot(String id)                  => '$baseUrl/time-slots/$id';
  static String get timeSlotsBulk                    => '$baseUrl/time-slots/bulk';
  static String timeSlotsByDayPlan(String dayPlanId) => '$baseUrl/time-slots?dayPlanId=$dayPlanId';
  static String activeTimeSlotsByDayPlan(String id)  => '$baseUrl/time-slots?dayPlanId=$id&isActive=true';

  // ── Reservations ─────────────────────────────────────────────────────────────
  static String get reservations                  => '$baseUrl/reservations';
  static String reservation(String id)            => '$baseUrl/reservations/$id';
  // Player: submit cancellation request with a reason
  static String requestCancelReservation(String id) => '$baseUrl/reservations/$id/request-cancel';
  // Worker/Manager: approve the cancel (or direct cancel)
  static String cancelReservation(String id)      => '$baseUrl/reservations/$id/cancel';
  static String confirmReservation(String id)     => '$baseUrl/reservations/$id/confirm';
  static String rejectReservation(String id)      => '$baseUrl/reservations/$id/reject';
  static String completeReservation(String id)    => '$baseUrl/reservations/$id/complete';

  // ── Announcements ────────────────────────────────────────────────────────────
  static String get announcements                => '$baseUrl/announcements';
  static String get myAnnouncements              => '$baseUrl/announcements/mine';
  static String get myRequests                   => '$baseUrl/announcements/my-requests';
  static String announcement(String id)          => '$baseUrl/announcements/$id';
  static String announcementRequests(String id)  => '$baseUrl/announcements/$id/requests';
  static String announcementRequest(String annId, String reqId)
      => '$baseUrl/announcements/$annId/requests/$reqId';

  // ── Ratings ──────────────────────────────────────────────────────────────────
  static String get submitRating                => '$baseUrl/ratings/submit';
  static String ratingById(String id)           => '$baseUrl/ratings/$id';
  static String getUserRating(String venueId)   => '$baseUrl/ratings/user/venue/$venueId';
  static String getVenueRatings(String venueId) => '$baseUrl/ratings/venue/$venueId';

  // ── AI Assistant ─────────────────────────────────────────────────────────────
  static String get aiChat                       => '$baseUrl/ai-agent/chat';
  static String aiHistory(String sessionId)      => '$baseUrl/ai-agent/history/$sessionId';
  static String aiClearHistory(String sessionId) => '$baseUrl/ai-agent/history/$sessionId';

 // ── Payments (Stripe) ────────────────────────────────────────────────────────
/// Player: create a Stripe PaymentIntent → returns clientSecret + paymentId
static String get createPaymentIntent => '$baseUrl/payments/create-intent';

/// Player: verify with Stripe server-side and confirm the reservation
static String confirmPayment(String paymentId) => '$baseUrl/payments/$paymentId/confirm';

/// Player / Manager: get the latest payment for a specific reservation
static String paymentByReservation(String resId) => '$baseUrl/payments/reservation/$resId';

/// Manager / Admin: list all payments for their courts
static String get payments => '$baseUrl/payments';

static String paymentsFiltered({String? status, int limit = 100, int page = 1}) {
  final params = <String>['limit=$limit', 'page=$page'];
  if (status != null && status.isNotEmpty) params.add('status=$status');
  return '$baseUrl/payments?${params.join("&")}';
}
}

