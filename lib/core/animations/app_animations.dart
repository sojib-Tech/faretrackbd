import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration spring = Duration(milliseconds: 600);

  static List<Effect<dynamic>> get fadeIn => [
        FadeEffect(
          duration: fast,
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect<dynamic>> get slideUp => [
        SlideEffect(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
          duration: medium,
          curve: Curves.easeOutCubic,
        ),
        FadeEffect(
          duration: medium,
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect<dynamic>> get scaleIn => [
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: Offset.zero,
          duration: medium,
          curve: Curves.easeOutBack,
        ),
        FadeEffect(
          duration: medium,
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect<dynamic>> get staggerList => [
        SlideEffect(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
          duration: spring,
          curve: Curves.easeOutCubic,
        ),
        FadeEffect(
          duration: spring,
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect<dynamic>> get springReveal => [
        ScaleEffect(
          begin: const Offset(0.5, 0.5),
          end: Offset.zero,
          duration: spring,
          curve: Curves.elasticOut,
        ),
        FadeEffect(
          duration: const Duration(milliseconds: 200),
        ),
      ];
}
