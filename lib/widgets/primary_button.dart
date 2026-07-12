import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double width;
  final IconData? icon;
  final bool hasBreathingAnimation;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onLongPress,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 56,
    this.width = double.infinity,
    this.icon,
    this.hasBreathingAnimation = false,
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
    final btn = SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        onLongPress: widget.isLoading ? null : widget.onLongPress,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.backgroundColor ?? AppConstants.primaryGreen,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.fontBengali,
                    ),
                  ),
                ],
              ),
      ),
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
