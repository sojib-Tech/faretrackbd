import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'FareTrack BD';
  static const String tagline = 'ঢাকার বাস ভাড়া এখন আপনার হাতের মুঠোয়';

  static const double fareRatePerKm = 2.53;
  static const double minimumFare = 10.0;
  static const double gpsMaxAccuracy = 10.0;
  static const double gpsHighAccuracy = 8.0;
  static const double gpsExcellentAccuracy = 5.0;
  static const double speedPauseThreshold = 0.5;
  static const double speedMovingThreshold = 1.0;
  static const double minDistanceDelta = 1.0;
  static const double maxDistanceDelta = 30.0;
  static const double gpsSmoothingAlpha = 0.35;
  static const double speedSmoothingAlpha = 0.3;
  static const double headingSmoothingAlpha = 0.25;

  static const String tileUrl =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static const String defaultMapCenter = '23.8103,90.4125';
  static const double defaultMapZoom = 13.0;

  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationMedium = Duration(milliseconds: 500);
  static const Duration animationFast = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 800);

  static const String fontBengali = 'HindSiliguri';
  static const String fontEnglish = 'Poppins';

  static const Color primaryGreen = Color(0xFF0B5345);
  static const Color pineDeep = Color(0xFF0A4536);
  static const Color pineGlow = Color(0xFFC9E8DD);
  static const Color primaryAccent = Color(0xFF1ABC9C);
  static const Color fareAmber = Color(0xFFF39C12);
  static const Color amberSoft = Color(0xFFFBEED7);
  static const Color ink = Color(0xFF12231F);
  static const Color inkSoft = Color(0xFF4B615C);
  static const Color paper = Color(0xFFF3F2EC);
  static const Color cardLine = Color(0xFFE2E0D6);
  static const Color warn = Color(0xFFC78A1F);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color backgroundLight = Color(0xFFF4F6F5);
  static const Color backgroundDark = Color(0xFF121212);
}
