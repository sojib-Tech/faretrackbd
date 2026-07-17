import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/bus_database.dart';

class BusDetailScreen extends StatelessWidget {
  final BusInfo bus;
  const BusDetailScreen({super.key, required this.bus});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(bus.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (bus.nameBn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bus.nameBn,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppConstants.fontBengali,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (bus.type.isNotEmpty) ...[
                    _infoChip(Icons.info_outline_rounded, bus.type, isDark),
                    const SizedBox(height: 8),
                  ],
                  if (bus.time != null && bus.time!.isNotEmpty) ...[
                    _infoChip(Icons.access_time_rounded, bus.time!, isDark),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'রুট (${bus.stops.length}টি স্টপেজ)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.fontBengali,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: bus.stops.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 44, endIndent: 16),
              itemBuilder: (_, i) {
                final isFirst = i == 0;
                final isLast = i == bus.stops.length - 1;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppConstants.successGreen.withValues(alpha: 0.15)
                          : isLast
                              ? AppConstants.errorRed.withValues(alpha: 0.15)
                              : AppConstants.primaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFirst
                              ? AppConstants.successGreen
                              : isLast
                                  ? AppConstants.errorRed
                                  : AppConstants.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    bus.stops[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isFirst || isLast ? FontWeight.w600 : FontWeight.normal,
                      fontFamily: AppConstants.fontBengali,
                      color: isFirst
                          ? AppConstants.successGreen
                          : isLast
                              ? AppConstants.errorRed
                              : null,
                    ),
                  ),
                  subtitle: isFirst
                      ? const Text('যাত্রা শুরু',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppConstants.fontBengali,
                            color: AppConstants.successGreen,
                          ))
                      : isLast
                          ? const Text('গন্তব্য',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: AppConstants.fontBengali,
                                color: AppConstants.errorRed,
                              ))
                          : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.primaryAccent),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppConstants.fontBengali,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
