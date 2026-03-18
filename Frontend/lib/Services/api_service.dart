// api_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Placeholder — all API calls will be implemented here when backend is ready.
// ─────────────────────────────────────────────────────────────────────────────

class ApiService {
  ApiService._();

  static const String baseUrl = 'https://api.sporta.tn/v1'; // TODO: update with real URL

  // ── Auth ──────────────────────────────────────────────────────────────
  // static Future<UserModel> login(String email, String password) async {}
  // static Future<UserModel> signUp(String name, String email, String password) async {}
  // static Future<void> forgotPassword(String email) async {}

  // ── Courts ────────────────────────────────────────────────────────────
  // static Future<List<CourtModel>> getCourts() async {}
  // static Future<CourtModel> getCourtById(String id) async {}

  // ── Bookings ──────────────────────────────────────────────────────────
  // static Future<CourtReservation> createBooking(CourtReservation reservation) async {}
  // static Future<List<CourtReservation>> getMyBookings() async {}

  // ── Announcements ─────────────────────────────────────────────────────
  // static Future<List<AnnouncementModel>> getAnnouncements() async {}
  // static Future<AnnouncementModel> postAnnouncement(AnnouncementModel ann) async {}
  // static Future<JoinRequest> sendJoinRequest(String announcementId, String message) async {}
  // static Future<void> respondToRequest(String requestId, bool accepted) async {}
}
