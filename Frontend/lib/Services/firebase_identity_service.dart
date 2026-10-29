// lib/Services/firebase_identity_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Core/Utils/app_logger.dart';

class FirebaseIdentityService {
  FirebaseIdentityService._();
  static final FirebaseIdentityService instance = FirebaseIdentityService._();

  String? _firebaseUid;
  String? _fcmToken;

  String? get firebaseUid => _firebaseUid;
  String? get fcmToken => _fcmToken;

  // ── Called from main() — just init Firebase so Firestore works ───────────

  Future<void> initAnonymous() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      AppLogger.error('[FirebaseIdentity] initAnonymous error: $e');
    }
  }

  // ── Called from Navigation after Strapi login ────────────────────────────
  // Builds a deterministic uid: "sporta_player_3" or "sporta_manager_1"
  // This is unique per user account and never changes.
  Future<void> initForUser({
    required String strapiToken,
    required String strapiUserId,
    required String role, // 'player' or 'manager'
  }) async {
    try {
      // Build deterministic uid — unique per Strapi user, consistent across devices
      _firebaseUid = 'sporta_${role}_$strapiUserId';

      // Fetch FCM token
      await _fetchFcmToken();

      // Save both to Strapi
      await _syncToStrapi(strapiToken);
    } catch (e) {
      AppLogger.error('[FirebaseIdentity] initForUser error: $e');
    }
  }

  // ── Fetch FCM token ───────────────────────────────────────────────────────
  Future<void> _fetchFcmToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _fcmToken = await FirebaseMessaging.instance.getToken();
      // Refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _fcmToken = t;
      });
    } catch (e) {
      AppLogger.error('[FirebaseIdentity] FCM error: $e');
    }
  }

  // ── Save firebaseUid + fcmToken to Strapi ─────────────────────────────────
  Future<void> _syncToStrapi(String token) async {
    final uid = _firebaseUid;
    if (uid == null || uid.isEmpty || token.isEmpty) return;
    try {
      await PlayerManagerAuthService.updateFirebaseUid(
        token: token,
        firebaseUid: uid,
        fcmToken: _fcmToken,
      );
    } catch (e) {
      AppLogger.error('[FirebaseIdentity] Strapi sync failed (non-fatal): $e');
    }
  }

  Future<void> signOut() async {
    _firebaseUid = null;
    _fcmToken = null;
  }
}
