import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/fare_ring.dart';

class FareCircleWidget extends StatelessWidget {
  final bool isActive;
  final bool isJam;
  final double fare;
  final double distance;
  final double progress;
  final double accuracy;

  const FareCircleWidget({
    super.key,
    required this.isActive,
    required this.isJam,
    required this.fare,
    required this.distance,
    required this.progress,
    this.accuracy = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FareRing(
      progress: progress,
      isJam: isJam,
      size: 240,
      child: isActive
          ? _buildActiveContent(context)
          : _buildIdleContent(context),
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions_bus_rounded,
          size: 48,
          color: AppConstants.primaryGreen.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          'যাত্রা শুরু করতে\nনিচের বাটন চাপুন',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[500],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveContent(BuildContext context) {
    final fareColor =
        isJam ? AppConstants.fareAmber : AppConstants.primaryAccent;
    final displayFare = (fare * 100).roundToDouble() / 100;
    final displayDist = (distance * 10).roundToDouble() / 10;
    final weakGps = accuracy > AppConstants.gpsHighAccuracy && accuracy > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ভাড়া',
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Text(
            '৳${displayFare.toStringAsFixed(1)}',
            key: ValueKey(displayFare.toStringAsFixed(1)),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              fontFamily: AppConstants.fontEnglish,
              color: displayFare > 0 ? fareColor : Colors.grey[400],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Text(
            '${displayDist.toStringAsFixed(2)} কিমি',
            key: ValueKey(displayDist.toStringAsFixed(2)),
            style: TextStyle(
              fontSize: 15,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[600],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isJam ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: const SizedBox(height: 6),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isJam ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppConstants.fareAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppStrings.jam,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.fareAmber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        if (weakGps)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'GPS: ${accuracy.toStringAsFixed(0)}মি',
              style: TextStyle(
                fontSize: 10,
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.fareAmber,
              ),
            ),
          ),
      ],
    );
  }
}
