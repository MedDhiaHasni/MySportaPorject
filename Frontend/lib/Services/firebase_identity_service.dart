// lib/Services/firebase_identity_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  Future<bool> signInWithStrapiToken(
    String strapiToken, {
    bool force = false,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (!force && currentUser != null && !currentUser.isAnonymous) {
        final needsSync = _firebaseUid != currentUser.uid;
        _firebaseUid = currentUser.uid;
        if (needsSync) {
          await _fetchFcmToken();
          await _syncToStrapi(strapiToken);
        }
        return true;
      }

      if (currentUser != null) await auth.signOut();

      final tokenResponse =
          await PlayerManagerAuthService.createFirebaseToken(strapiToken);
      final customToken = tokenResponse['customToken']?.toString();
      final expectedUid = tokenResponse['firebaseUid']?.toString();
      if (customToken == null ||
          customToken.isEmpty ||
          expectedUid == null ||
          expectedUid.isEmpty) {
        throw StateError('The secure chat sign-in response was incomplete');
      }

      final credential = await auth.signInWithCustomToken(customToken);
      final user = credential.user;
      if (user == null || user.uid != expectedUid) {
        await auth.signOut();
        throw StateError('The secure chat identity did not match');
      }

      _firebaseUid = user.uid;
      await _fetchFcmToken();
      await _syncToStrapi(strapiToken);
      return true;
    } catch (e) {
      _firebaseUid = null;
      AppLogger.error('[FirebaseIdentity] custom-token sign-in failed: $e');
      return false;
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
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } finally {
      _firebaseUid = null;
      _fcmToken = null;
    }
  }
}
