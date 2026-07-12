import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../models/trip_model.dart';
import '../../widgets/dashed_divider.dart';

class HistoryDetailScreen extends StatelessWidget {
  final TripModel trip;

  const HistoryDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'যাত্রার বিবরণ',
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'fare_${trip.id}',
                    child: Text(
                      trip.formattedFare,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppConstants.fontEnglish,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.fareLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppConstants.fontBengali,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _buildRow(
                    Icons.calendar_today_rounded,
                    'তারিখ',
                    trip.formattedDate,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    Icons.access_time_rounded,
                    'সময়',
                    '${trip.formattedStartTime} - ${trip.formattedEndTime}',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    Icons.straighten_rounded,
                    AppStrings.distanceLabel,
                    trip.formattedDistance,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    Icons.timer_rounded,
                    AppStrings.durationLabel,
                    trip.formattedDuration,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    Icons.warning_amber_rounded,
                    AppStrings.jamTimeLabel,
                    trip.formattedJamTime,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRow(
                    Icons.speed_rounded,
                    AppStrings.avgSpeedLabel,
                    trip.formattedAverageSpeed,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  DashedDividerPainter.divider(
                    color: Colors.grey[300]!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('শীঘ্রই আসছে')),
                              );
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              AppStrings.shareButton,
                              style: const TextStyle(
                                fontFamily: AppConstants.fontBengali,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.primaryAccent,
                              side: BorderSide(
                                color: AppConstants.primaryAccent.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[500],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: AppConstants.fontBengali,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
