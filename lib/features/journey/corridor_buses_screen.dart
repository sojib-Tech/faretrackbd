import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/corridor_finder.dart';

class CorridorBusesScreen extends StatefulWidget {
  final String originName;
  final String destName;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  const CorridorBusesScreen({
    super.key,
    required this.originName,
    required this.destName,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<CorridorBusesScreen> createState() => _CorridorBusesScreenState();
}

class _CorridorBusesScreenState extends State<CorridorBusesScreen> {
  List<CorridorBusMatch>? _results;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    try {
      final results = await findAllCorridorBuses(
        widget.originName,
        widget.destName,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'বাস লোড করতে সমস্যা হয়েছে';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.paper,
      appBar: AppBar(
        title: const Text('যাত্রা বিবরণ',
            style: TextStyle(fontFamily: AppConstants.fontBengali)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildRouteHeader(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A3A2A), const Color(0xFF122A1E)]
              : [AppConstants.primaryGreen, AppConstants.pineDeep],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.originName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: AppConstants.fontBengali,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 1,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 1,
                      color: Colors.white38,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.destName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: AppConstants.fontBengali,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_results != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${AppConstants.toBanglaNum("${_results!.length}")} টি বাস',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: AppConstants.fontBengali,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'বাস খুঁজে বের করা হচ্ছে...',
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.inkSoft,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'এই রুটে কোনো বাস পাওয়া যায়নি',
              style: TextStyle(
                fontSize: 15,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ভিন্ন স্থান বেছে নিন',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results!.length,
      itemBuilder: (_, i) => _buildBusCard(_results![i], i, isDark),
    );
  }

  Widget _buildBusCard(CorridorBusMatch bus, int index, bool isDark) {
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final isCheapest = index == 0;

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCheapest
                ? AppConstants.successGreen
                : (isDark ? Colors.white12 : AppConstants.cardLine),
            width: isCheapest ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? []
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bus.isAc
                      ? AppConstants.primaryAccent.withValues(alpha: 0.12)
                      : AppConstants.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  bus.isAc
                      ? Icons.ac_unit_rounded
                      : Icons.directions_bus_rounded,
                  size: 20,
                  color: bus.isAc
                      ? AppConstants.primaryAccent
                      : AppConstants.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bus.bus.nameBn,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppConstants.fontBengali,
                              color: isDark ? Colors.white : AppConstants.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bus.isAc) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AC',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (isCheapest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppConstants.successGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'সস্তা',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppConstants.fontBengali,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bus.bus.nameEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${AppConstants.toBanglaNumFromDouble(bus.distanceKm, decimals: 1)} কিমি',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppConstants.inkSoft,
                            fontFamily: AppConstants.fontBengali,
                          ),
                        ),
                        Text(
                          ' · ${AppConstants.toBanglaNum("${bus.stopsBetween}")} স্টপ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppConstants.inkSoft,
                            fontFamily: AppConstants.fontBengali,
                          ),
                        ),
                        if (bus.originStopName.isNotEmpty) ...[
                          Text(
                            ' · ${bus.originStopName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.grey[400],
                              fontFamily: AppConstants.fontBengali,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.formatFare(bus.fare),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppConstants.primaryGreen,
                  fontFamily: AppConstants.fontBengali,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(
            duration: 280.ms,
            delay: Duration(milliseconds: index * 50),
          ),
    );
  }
}
