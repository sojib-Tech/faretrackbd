import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/receipt_utils.dart';
import '../../models/trip_model.dart';
import '../../widgets/dashed_divider.dart';
import '../emergency/emergency_screen.dart';

class ReceiptSheet extends StatefulWidget {
  final TripModel trip;

  const ReceiptSheet({super.key, required this.trip});

  @override
  State<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<ReceiptSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.tripComplete,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.fontBengali,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          color: AppConstants.primaryGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.trip.formattedFare,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppConstants.fontEnglish,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.fareLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppConstants.fontBengali,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      DashedDividerPainter.divider(
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.straighten_rounded,
                        AppStrings.distanceLabel,
                        widget.trip.formattedDistance,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.access_time_rounded,
                        AppStrings.durationLabel,
                        widget.trip.formattedDuration,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.warning_amber_rounded,
                        AppStrings.jamTimeLabel,
                        widget.trip.formattedJamTime,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.speed_rounded,
                        AppStrings.avgSpeedLabel,
                        widget.trip.formattedAverageSpeed,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      DashedDividerPainter.divider(
                        color: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  Icons.share_rounded,
                                  AppStrings.shareButton,
                                  AppConstants.primaryAccent,
                                  () => _onShare(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  Icons.picture_as_pdf_rounded,
                                  AppStrings.pdfButton,
                                  AppConstants.errorRed,
                                  () => _onSavePdf(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                                );
                              },
                              icon: const Icon(Icons.emergency_rounded, size: 20),
                              label: Text(
                                AppStrings.emergencyAfterTrip,
                                style: const TextStyle(
                                  fontFamily: AppConstants.fontBengali,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.errorRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    ));
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
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
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.fontBengali,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.shareSuccess,
            style: const TextStyle(fontFamily: AppConstants.fontBengali)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await shareReceiptText(widget.trip);
  }

  Future<void> _onSavePdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await generateReceiptPdf(widget.trip);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.pdfSuccess,
              style: const TextStyle(fontFamily: AppConstants.fontBengali)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'FareTrack BD - ${AppStrings.tripComplete}',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.pdfError,
              style: const TextStyle(fontFamily: AppConstants.fontBengali)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
