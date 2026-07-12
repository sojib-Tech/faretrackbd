import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FareProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final bool isJam;

  FareProgressRingPainter({
    required this.progress,
    this.strokeWidth = 8,
    this.color,
    this.backgroundColor,
    this.isJam = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor ?? Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressColor = color ?? _getProgressColor(progress);
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isJam) {
        // Dashed ring for jam state
        _drawDashedArc(
          canvas,
          center,
          radius,
          -pi / 2,
          -pi / 2 + 2 * pi * progress,
          progressPaint,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * progress,
          false,
          progressPaint,
        );
      }
    }
  }

  void _drawDashedArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    Paint paint,
  ) {
    const dashLength = 8.0;
    const gapLength = 5.0;
    final totalAngle = endAngle - startAngle;
    final arcLength = radius * totalAngle;
    final dashCount = (arcLength / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final start = startAngle +
          (i * (dashLength + gapLength)) / radius;
      final end = start + dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return AppConstants.successGreen;
    if (progress < 0.6) return AppConstants.fareAmber;
    return AppConstants.errorRed;
  }

  @override
  bool shouldRepaint(covariant FareProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isJam != isJam;
}

class FareRing extends StatelessWidget {
  final double progress;
  final double size;
  final bool isJam;
  final Widget child;

  const FareRing({
    super.key,
    required this.progress,
    this.size = 240,
    this.isJam = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FareProgressRingPainter(
          progress: progress,
          isJam: isJam,
          strokeWidth: 6,
        ),
        child: Center(child: child),
      ),
    );
  }
}
