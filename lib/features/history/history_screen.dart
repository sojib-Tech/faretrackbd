import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _sortBy = 'date';
  bool _isRefreshing = false;

  List<TripModel> _sortTrips(List<TripModel> trips) {
    final sorted = List<TripModel>.from(trips);
    switch (_sortBy) {
      case 'date':
        sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 'fare':
        sorted.sort((a, b) => b.totalFare.compareTo(a.totalFare));
        break;
      case 'distance':
        sorted.sort((a, b) => b.totalDistanceKm.compareTo(a.totalDistanceKm));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final trips = _sortTrips(tripState.trips);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.historyTitle,
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (trips.isNotEmpty)
            PopupMenuButton<String>(
              initialValue: _sortBy,
              icon: Icon(
                Icons.filter_list_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onSelected: (value) {
                setState(() => _sortBy = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      if (_sortBy == 'date')
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text('তারিখ',
                          style: TextStyle(
                              fontFamily: AppConstants.fontBengali)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'fare',
                  child: Row(
                    children: [
                      if (_sortBy == 'fare')
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text('ভাড়া',
                          style: TextStyle(
                              fontFamily: AppConstants.fontBengali)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'distance',
                  child: Row(
                    children: [
                      if (_sortBy == 'distance')
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text('দূরত্ব',
                          style: TextStyle(
                              fontFamily: AppConstants.fontBengali)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: tripState.isLoading && !_isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _isRefreshing = true);
                    await ref.read(tripProvider.notifier).refreshTrips();
                    if (mounted) setState(() => _isRefreshing = false);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: trips.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildDeleteAllButton(isDark, trips.length);
                      }
                      final tripIndex = index - 1;
                      return _TripCard(
                        trip: trips[tripIndex],
                        index: tripIndex,
                        onDelete: () =>
                            _deleteTrip(context, trips[tripIndex].id),
                        onTap: () => context.push('/history/detail',
                            extra: trips[tripIndex]),
                      ).animate().slideX(
                            begin: 0.3,
                            end: 0,
                            duration: 400.ms,
                            delay: (tripIndex * 80).ms,
                            curve: Curves.easeOutCubic,
                          ).fadeIn(
                            duration: 400.ms,
                            delay: (tripIndex * 80).ms,
                          );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: (isDark ? Colors.grey[800] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              size: 56,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.emptyHistory,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আপনার প্রথম যাত্রা শুরু করুন',
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAllButton(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'মোট $count টি যাত্রা',
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _confirmDeleteAll(context, count),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 14, color: AppConstants.errorRed),
                  const SizedBox(width: 4),
                  Text(
                    'সব মুছুন',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppConstants.fontBengali,
                      color: AppConstants.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'সব মুছে ফেলবেন?',
          style: const TextStyle(fontFamily: AppConstants.fontBengali),
        ),
        content: Text(
          '$count টি যাত্রার সকল তথ্য স্থায়ীভাবে মুছে যাবে।',
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.deleteNo,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripProvider.notifier).deleteAllTrips();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('সব যাত্রা মুছে ফেলা হয়েছে',
                      style: TextStyle(fontFamily: AppConstants.fontBengali)),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Text(
              'হ্যাঁ, সব মুছুন',
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTrip(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppStrings.deleteConfirm,
          style: const TextStyle(fontFamily: AppConstants.fontBengali),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.deleteNo,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripProvider.notifier).deleteTrip(tripId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('মুছে ফেলা হয়েছে',
                      style: TextStyle(fontFamily: AppConstants.fontBengali)),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Text(
              AppStrings.deleteYes,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.index,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              AppStrings.deleteConfirm,
              style: const TextStyle(fontFamily: AppConstants.fontBengali),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppStrings.deleteNo,
                  style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppStrings.deleteYes,
                  style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    color: AppConstants.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppConstants.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppConstants.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.fontEnglish,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.formattedStartTime} - ${trip.formattedEndTime}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppConstants.fontEnglish,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: 'fare_${trip.id}',
                    child: Text(
                      trip.formattedFare,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppConstants.fontEnglish,
                        color: AppConstants.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.formattedDistance,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: AppConstants.fontBengali,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
