import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// A full-bleed gradient background. When [vibe] is true it paints the bold
/// brand hero gradient with soft floating blobs (for intro/hero screens);
/// otherwise it paints a calm lavender-tinted surface for content screens.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool vibe;
  final List<Color>? gradient;
  final Widget? floating;

  const AppBackground({
    super.key,
    required this.child,
    this.vibe = false,
    this.gradient,
    this.floating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColors = gradient ??
        (vibe
            ? AppConstants.heroGradient
            : (isDark
                ? const [Color(0xFF140F22), Color(0xFF1B1430)]
                : const [Color(0xFFFBF9FF), Color(0xFFF1ECFB)]));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AppConstants.gradientBegin,
          end: AppConstants.gradientEnd,
          colors: baseColors,
        ),
      ),
      child: vibe
          ? Stack(
              children: [
                _Blob(
                  color: AppConstants.primaryAccent.withValues(alpha: 0.45),
                  top: -80,
                  left: -60,
                  size: 260,
                ),
                _Blob(
                  color: AppConstants.primary.withValues(alpha: 0.4),
                  bottom: -90,
                  right: -70,
                  size: 300,
                ),
                _Blob(
                  color: Colors.cyanAccent.withValues(alpha: 0.18),
                  top: MediaQuery.of(context).size.height * 0.45,
                  left: -40,
                  size: 200,
                ),
                if (floating != null) floating!,
                child,
              ],
            )
          : child,
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  const _Blob({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient text used for display headings.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;
  final TextAlign textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.colors = AppConstants.brandGradient,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: AppConstants.gradientBegin,
        end: AppConstants.gradientEnd,
        colors: colors,
      ).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// A small gradient pill/section title.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white : AppConstants.ink,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: GradientText(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
