import 'package:flutter/material.dart';

class DashedDividerPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  DashedDividerPainter({
    this.color = Colors.grey,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedDividerPainter oldDelegate) =>
      oldDelegate.color != color;

  static Widget divider({
    Color? color,
    double dashWidth = 6,
    double dashGap = 4,
    double strokeWidth = 1,
    double height = 1,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: CustomPaint(
        painter: DashedDividerPainter(
          color: color ?? Colors.grey[300]!,
          dashWidth: dashWidth,
          dashGap: dashGap,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
