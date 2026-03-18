import 'package:flutter/material.dart';

const kPrimary = Color(0xFF005D5E);
const kBg = Color(0xFFF2F2F5);
const kCard = Colors.white;
const kTextDark = Color(0xFF0D1117);
const kTextMid = Color(0xFF6B7280);
const kTextLight = Color(0xFFB0B7C3);
const kGreen = Color(0xFF16A34A);
const kOrange = Color(0xFFF97316);
const kAmber = Color(0xFFD97706);
const kPurple = Color(0xFF6D28D9);
const kRed = Color(0xFFDC2626);
const kBlue = Color(0xFF2563EB);
const kAdminBg = Color(0xFF0A0F0F);

List<BoxShadow> get kElevation => [
  // elevation is the shadow of the card, it gives the card a sense of depth
  BoxShadow(
    color: Colors.black.withOpacity(0.042),
    blurRadius: 18, // blurRadius is the size of the shadow
    offset: const Offset(0, 3),
  ), // offset is the position of the shadow
  BoxShadow(
    color: Colors.black.withOpacity(0.016),
    blurRadius: 4,
    offset: const Offset(
      0,
      1,
    ), // 0, 1 means the shadow is 1 pixel down from the widget
  ),
];

BoxDecoration kCardDeco(double r) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(r),
  boxShadow: kElevation,
);
