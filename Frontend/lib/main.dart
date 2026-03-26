import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_theme.dart';
import 'package:sporta/Views/Admin/admin_login.dart';
import 'package:sporta/Views/Admin/admindashboard.dart';
import 'package:sporta/Views/SplashOnboarding/splash.dart';

void main() {
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
}
