import 'dart:math';
import 'package:flutter/material.dart';

class BusAnimatedMarker extends StatefulWidget {
  final double heading;
  final double size;

  const BusAnimatedMarker({
    super.key,
    this.heading = 0,
    this.size = 40,
  });

  @override
  State<BusAnimatedMarker> createState() => _BusAnimatedMarkerState();
}

class _BusAnimatedMarkerState extends State<BusAnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.heading * pi / 180,
          child: Transform.translate(
            offset: Offset(0, -2 * sin(_controller.value * pi)),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: const Color(0xFF0B5345),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B5345).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
