import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_constants.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> gradient;
  final Color foregroundColor;
  final double height;
  final double? width;
  final IconData? icon;
  final bool hasShimmer;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppConstants.brandGradient,
    this.foregroundColor = Colors.white,
    this.height = 58,
    this.width,
    this.icon,
    this.hasShimmer = false,
    this.borderRadius = 999,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius;
    final child = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AppConstants.gradientBegin,
          end: AppConstants.gradientEnd,
          colors: widget.gradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradient.first.withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: widget.gradient.last.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: widget.isLoading ? null : widget.onPressed,
          splashColor: Colors.white.withValues(alpha: 0.25),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: widget.foregroundColor),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.foregroundColor,
                          fontFamily: AppConstants.fontBengali,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (widget.hasShimmer) {
      return child
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1800.ms, color: Colors.white.withValues(alpha: 0.5));
    }
    return child;
  }
}
