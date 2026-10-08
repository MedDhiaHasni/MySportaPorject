// lib/Services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    debugPrint('📱 FCM Token: $token');

    // Listen to messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground notification received');
      final data = message.data;
      final title = message.notification?.title ?? 'Sporta Update';
      final body = message.notification?.body ?? '';
      
      debugPrint('Notification: $title - $body');
      debugPrint('Data: $data');
      
      if (onNotificationTap != null) {
        onNotificationTap!(data);
      }
    });

    // Listen to messages when app is in background/terminated and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification tapped to open app');
      if (onNotificationTap != null) {
        onNotificationTap!(message.data);
      }
    });

    // Handle initial message (app opened from terminated state via notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null && onNotificationTap != null) {
      debugPrint('📱 Initial notification tapped');
      onNotificationTap!(initialMessage.data);
    }
  }

  // Get FCM token (for saving to backend)
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Update FCM token in your backend (call this after login)
  Future<void> syncFcmToken(String authToken, String userId, String userRole) async {
    final fcmToken = await getFcmToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('📱 FCM Token for $userRole: $fcmToken');
      // You can also call your backend to save the token here
    }
  }
}