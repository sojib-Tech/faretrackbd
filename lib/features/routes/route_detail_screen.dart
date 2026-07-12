import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/color_extensions.dart';
import '../../models/bus_route.dart';

class RouteDetailScreen extends StatefulWidget {
  final BusRoute route;
  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  int? _selectedFrom;
  int? _selectedTo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final route = widget.route;

    return Scaffold(
      appBar: AppBar(
        title: Text(route.routeNo),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.nameBn,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: AppConstants.fontBengali,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              route.nameEn,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.straight_rounded,
                  label: '${route.totalDistanceKm} কিমি',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.alt_route_rounded,
                  label: '${route.stopCount}টি স্টপেজ',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.monetization_on_rounded,
                  label: '২.৫৩ টাকা/কিমি',
                  isDark: isDark,
                ),
              ],
            ),
            if (_selectedFrom != null && _selectedTo != null) ...[
              const SizedBox(height: 16),
              _FareResultCard(
                route: route,
                fromIdx: _selectedFrom!,
                toIdx: _selectedTo!,
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'স্টপেজ তালিকা',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(route.stops.length, (i) {
              final stop = route.stops[i];
              final isSelected = i == _selectedFrom || i == _selectedTo;
              return GestureDetector(
                onTap: () => _selectStop(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppConstants.primaryAccent.withValues(alpha: 0.2) : AppConstants.primaryGreen.withValues(alpha: 0.1))
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppConstants.primaryAccent.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: i == 0 || i == route.stops.length - 1
                              ? AppConstants.primaryAccent
                              : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: i == 0 || i == route.stops.length - 1
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stop.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: AppConstants.fontBengali,
                          ),
                        ),
                      ),
                      Text(
                        '${stop.distanceFromStartKm} কিমি',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      if (i == _selectedFrom || i == _selectedTo) ...[
                        const SizedBox(width: 8),
                        Icon(
                          i == _selectedFrom ? Icons.trip_origin_rounded : Icons.flag_rounded,
                          size: 18,
                          color: AppConstants.primaryAccent,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'ভাড়া টেবিল',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _FareTableView(route: route),
          ],
        ),
      ),
    );
  }

  void _selectStop(int index) {
    setState(() {
      if (_selectedFrom == null || (_selectedFrom != null && _selectedTo != null)) {
        _selectedFrom = index;
        _selectedTo = null;
      } else if (index != _selectedFrom) {
        _selectedTo = index;
      } else {
        _selectedFrom = index;
        _selectedTo = null;
      }
    });
  }
}

class _FareResultCard extends StatelessWidget {
  final BusRoute route;
  final int fromIdx;
  final int toIdx;
  const _FareResultCard({
    required this.route,
    required this.fromIdx,
    required this.toIdx,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final from = route.stops[fromIdx];
    final to = route.stops[toIdx];
    final fare = route.getFare(fromIdx, toIdx) ?? 0;
    final dist = route.getDistanceBetween(fromIdx, toIdx) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppConstants.primaryGreen.darken(0.3), AppConstants.primaryGreen]
              : [AppConstants.primaryGreen, AppConstants.primaryAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ভাড়া', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '৳$fare',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dist.toStringAsFixed(1)} কিমি দূরত্ব',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(from.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              const Icon(Icons.arrow_downward_rounded, color: Colors.white54, size: 20),
              Text(to.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FareTableView extends StatelessWidget {
  final BusRoute route;
  const _FareTableView({required this.route});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 36,
        headingRowHeight: 40,
        border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
        columns: [
          const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.w600))),
          ...route.stops.map((s) => DataColumn(
                label: Text(
                  s.distanceFromStartKm.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                ),
              )),
        ],
        rows: List.generate(route.stops.length, (i) {
          return DataRow(
            cells: [
              DataCell(Text(route.stops[i].name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
              ...List.generate(route.stops.length, (j) {
                if (i == j) {
                  return const DataCell(Text('-', style: TextStyle(fontSize: 11)));
                }
                final fare = route.getFare(i, j);
                return DataCell(Text(
                  fare != null ? '$fare' : '',
                  style: const TextStyle(fontSize: 11),
                ));
              }),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryAccent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

