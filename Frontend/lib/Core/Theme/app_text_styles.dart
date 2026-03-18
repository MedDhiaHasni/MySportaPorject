import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Headings ──────────────────────────────────────────────────────────
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.6);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.5);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark, letterSpacing: -0.4);
  static const h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: -0.3); 

  // ── Body ──────────────────────────────────────────────────────────────
  static const bodyLg  = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: kTextDark, height: 1.5);
  static const bodyMd  = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kTextDark, height: 1.45);
  static const bodySm  = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kTextDark, height: 1.4);
  static const bodyXs  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: kTextMid,  height: 1.4);

  // ── Labels ────────────────────────────────────────────────────────────
  static const labelLg = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark);
  static const labelMd = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMid);
  static const labelSm = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextMid);
  static const labelXs = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextMid);

  // ── Caption ───────────────────────────────────────────────────────────
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: kTextLight);

  // ── Button ────────────────────────────────────────────────────────────
  static const buttonPrimary = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white);
  static const buttonOutline = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMid); 

  // ── Nav ───────────────────────────────────────────────────────────────
  static const navLabel = TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70);
}
