import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'gradient_button.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final List<Color>? gradient;
  final Color? foregroundColor;
  final double height;
  final double width;
  final IconData? icon;
  final bool hasBreathingAnimation;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onLongPress,
    this.isLoading = false,
    this.gradient,
    this.foregroundColor,
    this.height = 56,
    this.width = double.infinity,
    this.icon,
    this.hasBreathingAnimation = false,
    this.borderRadius = 18,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _breathController;

  @override
  void initState() {
    super.initState();
    if (widget.hasBreathingAnimation) {
      _startBreathing();
    }
  }

  @override
  void didUpdateWidget(PrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasBreathingAnimation && _breathController == null) {
      _startBreathing();
    } else if (!widget.hasBreathingAnimation && _breathController != null) {
      _breathController?.stop();
      _breathController?.dispose();
      _breathController = null;
    }
  }

  void _startBreathing() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _breathController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = GradientButton(
      label: widget.label,
      onPressed: widget.onPressed,
      isLoading: widget.isLoading,
      gradient: widget.gradient ?? AppConstants.brandGradient,
      foregroundColor: widget.foregroundColor ?? Colors.white,
      height: widget.height,
      width: widget.width,
      icon: widget.icon,
      borderRadius: widget.borderRadius,
    );

    if (_breathController != null) {
      return AnimatedBuilder(
        animation: _breathController!,
        builder: (context, child) {
          final scale = 1.0 + (0.04 * _breathController!.value);
          return Transform.scale(scale: scale, child: child);
        },
        child: btn,
      );
    }

    return btn;
  }
}
