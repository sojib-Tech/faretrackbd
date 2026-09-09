import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'FareTrack BD';
  static const String tagline = 'ঢাকার বাস ভাড়া এখন আপনার হাতের মুঠোয়';

  static const double fareRatePerKm = 2.53;
  static const double minimumFare = 10.0;
  // Keep usable fixes up to 20m; the filter below rejects implausible jumps.
  static const double gpsMaxAccuracy = 20.0;
  static const double gpsHighAccuracy = 8.0;
  static const double gpsExcellentAccuracy = 5.0;
  static const double speedPauseThreshold = 0.5;
  static const double speedMovingThreshold = 1.0;
  static const double minDistanceDelta = 1.0;
  static const double maxDistanceDelta = 80.0;
  static const double gpsSmoothingAlpha = 0.55;
  static const double speedSmoothingAlpha = 0.35;
  static const double headingSmoothingAlpha = 0.35;

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
  static const String fontDisplay = 'Sora';

  // Brand palette (vibrant gradient / glass) -------------------------------
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryGreen = Color(
    0xFF7C3AED,
  ); // legacy alias -> brand violet
  static const Color primaryDeep = Color(0xFF6D28D9);
  static const Color pineDeep = Color(0xFF6D28D9); // legacy alias
  static const Color primaryAccent = Color(0xFFEC4899);
  static const Color primarySoft = Color(0xFFEDE9FE);
  static const Color pineGlow = Color(0xFFEDE9FE); // legacy alias
  static const Color fareAmber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color ink = Color(0xFF1E1B2E);
  static const Color inkSoft = Color(0xFF6B7280);
  static const Color paper = Color(0xFFF7F6FB);
  static const Color cardLine = Color(0xFFECEAF4);
  static const Color warn = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFF43F5E);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color backgroundLight = Color(0xFFF7F6FB);
  static const Color backgroundDark = Color(0xFF0F0E1A);

  // Gradients ---------------------------------------------------------------
  static const List<Color> brandGradient = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  static const List<Color> brandGradientLong = [
    Color(0xFF7C3AED),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  static const List<Color> heroGradient = [
    Color(0xFF7C3AED),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];
  static const List<Color> accentGradient = [
    Color(0xFF22D3EE),
    Color(0xFF3B82F6),
  ];
  static const List<Color> fareGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFB923C),
  ];
  static const List<Color> successGradient = [
    Color(0xFF34D399),
    Color(0xFF22C55E),
  ];

  static const Alignment gradientBegin = Alignment.topLeft;
  static const Alignment gradientEnd = Alignment.bottomRight;

  static LinearGradient brandLinearGradient({
    Alignment begin = gradientBegin,
    Alignment end = gradientEnd,
  }) => LinearGradient(begin: begin, end: end, colors: brandGradient);

  static LinearGradient heroLinearGradient({
    Alignment begin = gradientBegin,
    Alignment end = gradientEnd,
  }) => LinearGradient(begin: begin, end: end, colors: heroGradient);

  static LinearGradient gradientFrom(
    List<Color> colors, {
    Alignment begin = gradientBegin,
    Alignment end = gradientEnd,
  }) => LinearGradient(begin: begin, end: end, colors: colors);

  // Glass tokens ------------------------------------------------------------
  static const double glassRadius = 24.0;
  static const double glassBlur = 18.0;

  // Kissasian / Figma-exported design tokens --------------------------------
  // Fonts (resolved via google_fonts at point of use)
  static const String fontLobster = 'Lobster';
  static const String fontRoboto = 'Roboto';
  static const String fontInter = 'Inter';
  static const String fontMontserrat = 'Montserrat';

  // Text colors (from design system CSS)
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSoft = Color(0xFFE8E8E8);
  static const Color textGrey = Color(0xFFCAC8C8);
  static const Color textGreyStrong = Color(0xFF434343);
  static const Color textGreyMid = Color(0xFF7E7E7E);
  static const Color textGreyLight = Color(0xFFC5C5C5);
  static const Color textDark = Color(0xFF2F2F2F);
  static const Color textGreySoft = Color(0xFF888888);

  // Glass / surface presets (from rectangle-32, rectangle-77, rectangle-11)
  static const Color glassDarkFill = Color(0x661D1D1D);
  static const Color glassLightFill = Color(0x66FFFFFF);
  static const Color pillWhiteFill = Color(0xFFFFFFFF);
  static const Color solidDarkFill = Color(0xFF2F2F2F);
  static const double kissGlassBlur = 40.0;
  static const double kissGlassRadius = 15.0;
  static const double kissPillRadius = 50.0;
  static const List<Color> kissGlowBlob = [
    Color(0xFFFFFCE4),
    Color(0xFFEC4899),
  ];

  static const double journeySearchRadiusMeters = 1500.0;
  static const double journeyTransferMaxWalkMeters = 500.0;
  static const double journeyWalkingSpeedKmh = 5.0;
  static const double journeyBusSpeedKmh = 20.0;
  static const int journeyMaxCandidates = 15;
  static const int journeyMaxNearbyStops = 10;
  static const double walkOnlyThresholdMeters = 400.0;
  static const double walkOnlySpeedKmh = 5.0;

  static const double scoreTimeWeight = 0.40;
  static const double scoreFareWeight = 0.30;
  static const double scoreWalkWeight = 0.30;

  static String toBanglaNum(String input) {
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? bangla[d] : c;
    }).join();
  }

  static String toBanglaNumFromDouble(double value, {int decimals = 0}) {
    return toBanglaNum(value.toStringAsFixed(decimals));
  }

  static String formatDistanceMeters(double meters) {
    if (meters >= 1000) {
      return '${toBanglaNumFromDouble(meters / 1000, decimals: 1)} কিমি';
    }
    return '${toBanglaNumFromDouble(meters, decimals: 0)}মি';
  }

  static String formatTimeMinutes(double minutes) {
    final h = minutes.floor() ~/ 60;
    final m = minutes.floor() % 60;
    if (h > 0) return '${toBanglaNum('$h')}ঘ ${toBanglaNum('$m')}মি';
    return '${toBanglaNum('$m')}মি';
  }

  static String formatFare(double fare) {
    return '৳${toBanglaNumFromDouble(fare, decimals: 0)}';
  }
}
