import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/animated_chip.dart';

class StatusChipsWidget extends StatelessWidget {
  final Duration elapsed;
  final bool isPaused;
  final double accuracy;
  final bool isActive;
  final String statusMessage;

  const StatusChipsWidget({
    super.key,
    required this.elapsed,
    required this.isPaused,
    required this.accuracy,
    required this.isActive,
    this.statusMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = isActive ? _formatDuration(elapsed) : '--:--';
    final statusStr = !isActive
        ? 'প্রস্তুত'
        : isPaused
            ? AppStrings.jam
            : AppStrings.moving;
    final statusColor = !isActive
        ? Colors.grey
        : isPaused
            ? AppConstants.fareAmber
            : AppConstants.successGreen;

    final accuracyColor = !isActive
        ? Colors.grey
        : accuracy <= 0
            ? Colors.grey
            : accuracy <= AppConstants.gpsExcellentAccuracy
                ? AppConstants.successGreen
                : accuracy <= AppConstants.gpsHighAccuracy
                    ? AppConstants.primaryAccent
                    : accuracy <= AppConstants.gpsMaxAccuracy
                        ? AppConstants.fareAmber
                        : AppConstants.errorRed;

    final accuracyStr =
        accuracy > 0 ? '${accuracy.toStringAsFixed(0)}মি' : '--';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedChip(
                label: AppStrings.timeLabel,
                value: timeStr,
                icon: Icons.access_time_rounded,
                color: AppConstants.primaryAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedChip(
                label: AppStrings.statusLabel,
                value: statusStr,
                icon: isPaused
                    ? Icons.warning_amber_rounded
                    : Icons.circle_rounded,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedChip(
                label: AppStrings.gpsLabel,
                value: accuracyStr,
                icon: accuracy > 0 && accuracy <= AppConstants.gpsMaxAccuracy
                    ? Icons.satellite_alt_rounded
                    : Icons.signal_wifi_off_rounded,
                color: accuracyColor,
              ),
            ),
          ],
        ),
        if (isActive && statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                statusMessage,
                key: ValueKey(statusMessage),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppConstants.fontBengali,
                  color: statusMessage.contains('GPS')
                      ? AppConstants.fareAmber
                      : statusMessage.contains('জ্যাম')
                          ? AppConstants.fareAmber
                          : Colors.grey[500],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
