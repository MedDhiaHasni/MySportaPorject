// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sporta/Core/Theme/app_theme.dart';
import 'package:sporta/Views/Admin/admin_login.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sporta/Views/SplashOnboarding/splash.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');
      
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('✅ Anonymous auth successful');
      }
      
      //  Initialize Stripe v11
      const stripePublishableKey = 'pk_test_51TXhSLL0H3CCrj5WoEFvTjovdqIbRIlCGIl8f9rDJKx6zDasEpFUwx2Pi7tbnbmZUIGE9BziNvj34RZT9x1mmZxj00Xi4LX6SN';
      
      try {
        Stripe.publishableKey = stripePublishableKey;
        await Stripe.instance.applySettings();
        print('✅ Stripe v11 initialized successfully');
      } catch (e) {
        print('❌ Stripe initialization error: $e');
      }
      
      await _requestNotificationPermission();
      await _printFcmToken();
      _setupMessageListeners();
      
    } catch (e) {
      print('❌ Firebase error: $e');
    }
  }

  runApp(const SportaApp());
}

Future<void> _requestNotificationPermission() async {
  try {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  } catch (e) {
    print('Error requesting permission: $e');
  }
}

Future<void> _printFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print('');
    // haka 5ir bech todhor
    print('═══════════════════════════════════════════════════════════');
    print('📱 FCM TOKEN:');
    print(token);
    print('═══════════════════════════════════════════════════════════');
  } catch (e) {
    print('❌ Error getting FCM token: $e');
  }
}

void _setupMessageListeners() {
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📱 Received message while app is in foreground');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    
    // Show a snackbar when app is in foreground
    final title = message.notification?.title ?? 'Sporta';
    final body = message.notification?.body ?? 'You have a new notification';
    
    // Use the navigator key to show snackbar
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(body, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF002B2C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  });
  
  // When app is in BACKGROUND and user taps notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 User tapped notification to open app');
    _handleNotificationTap(message.data);
  });
  
  // When app is opened from TERMINATED state by tapping notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('📱 App opened from terminated state by notification');
      _handleNotificationTap(message.data);
    }
  });
}

void _handleNotificationTap(Map<String, dynamic> data) {
  // Navigate based on notification type
  print('Handling notification tap: $data');
  
  // hedhi kifech te5dem 3la 7asb el data li jeyebha mel notifications
  // You can navigate to specific screens here
  // For example:
  // if (data['screen'] == 'bookings') {
  //   navigatorKey.currentState?.pushNamed('/bookings');
  // }
}

class SportaApp extends StatelessWidget {
  const SportaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sporta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,  // ✅ Add this line
      home: kIsWeb ? const AdminLoginPage() : const Splash(),
    );
  }
}





/*// android/build.gradle.kts  (ROOT level — not the app/ one)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}*/










/*// android/app/build.gradle.kts  (APP level)
plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must come after Android + Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // ── THIS is what was missing — generates values.xml from google-services.json ──
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.sporta"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.sporta"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}*/





/*// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sporta/Core/Theme/app_theme.dart';
import 'package:sporta/Views/SplashOnboarding/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign in anonymously ONLY so Firestore security rules pass (request.auth != null).
  // We do NOT use this anonymous uid for anything else — each user's real uid
  // is "sporta_player_{id}" or "sporta_manager_{id}", set in Navigation after login.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('[main] Anonymous auth error: $e');
  }

  runApp(const SportaApp());
}

class SportaApp extends StatelessWidget {
  const SportaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sporta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Splash(),
    );
  }
}*/