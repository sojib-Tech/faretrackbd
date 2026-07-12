import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';

class StartStopButton extends StatelessWidget {
  final bool isActive;
  final bool isStopping;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const StartStopButton({
    super.key,
    required this.isActive,
    this.isStopping = false,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? AppConstants.errorRed : AppConstants.primaryGreen;
    final icon = isActive ? Icons.stop_circle_rounded : Icons.play_arrow_rounded;
    final label = isActive ? AppStrings.endTrip : AppStrings.startTrip;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isStopping ? 0.7 : 1.0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isStopping ? null : (isActive ? onStop : onStart),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isStopping
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isStopping ? 'থামানো হচ্ছে...' : label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
