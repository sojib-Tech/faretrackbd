import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class GlassCardVariant {
  static const String darkGlass = 'darkGlass';
  static const String lightGlass = 'lightGlass';
  static const String solidDark = 'solidDark';
  static const String pillWhite = 'pillWhite';
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final LinearGradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String? variant;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.glassRadius,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.blur = AppConstants.glassBlur,
    this.opacity = 0.16,
    this.gradient,
    this.boxShadow,
    this.onTap,
    this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LinearGradient resolvedGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.72),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.5),
          ],
        );
    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.55);
    double borderWidth = 1.2;
    List<BoxShadow> resolvedShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: blur,
            offset: const Offset(0, 8),
          ),
        ];
    double resolvedRadius = borderRadius;

    switch (variant) {
      case GlassCardVariant.darkGlass:
        // rectangle-32: dark blurred glass
        resolvedGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.glassDarkFill,
            AppConstants.glassDarkFill,
          ],
        );
        borderColor = Colors.white.withValues(alpha: 0.12);
        resolvedShadow = const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 9,
            offset: Offset(0, 5),
          ),
        ];
        resolvedRadius = AppConstants.kissGlassRadius;
        break;
      case GlassCardVariant.lightGlass:
        // rectangle-77: white 40% glass pill-ish card
        resolvedGradient = LinearGradient(
          colors: [AppConstants.glassLightFill, AppConstants.glassLightFill],
        );
        borderColor = Colors.white.withValues(alpha: 0.4);
        resolvedShadow = const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 26,
            spreadRadius: -2,
            offset: Offset(0, 13),
          ),
        ];
        resolvedRadius = 20;
        break;
      case GlassCardVariant.solidDark:
        // rectangle-11: solid dark pill
        resolvedGradient = const LinearGradient(
          colors: [AppConstants.solidDarkFill, AppConstants.solidDarkFill],
        );
        borderColor = Colors.transparent;
        resolvedShadow = const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 19,
            offset: Offset(0, 9),
          ),
        ];
        resolvedRadius = 20;
        break;
      case GlassCardVariant.pillWhite:
        resolvedGradient = const LinearGradient(
          colors: [AppConstants.pillWhiteFill, AppConstants.pillWhiteFill],
        );
        borderColor = Colors.transparent;
        resolvedRadius = AppConstants.kissPillRadius;
        break;
      default:
        break;
    }

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(resolvedRadius),
      gradient: resolvedGradient,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: resolvedShadow,
    );

    final container = Container(
      margin: margin,
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: container,
        ),
      );
    }
    return container;
  }
}
