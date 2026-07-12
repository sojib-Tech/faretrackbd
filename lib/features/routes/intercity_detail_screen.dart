import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/color_extensions.dart';
import '../../models/bus_route.dart';

class IntercityDetailScreen extends StatelessWidget {
  final DdrRoute route;
  const IntercityDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = route;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.routeNo),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.nameBn,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: AppConstants.fontBengali,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.nameEn,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Chip(
                  icon: Icons.straight_rounded,
                  label: '${r.totalDistanceKm} কিমি',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _Chip(
                  icon: Icons.monetization_on_rounded,
                  label: '${r.farePerKm} টাকা/কিমি',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FareComparisonCard(r: r, isDark: isDark),
            const SizedBox(height: 20),
            _TollDetailsCard(r: r, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _Chip({required this.icon, required this.label, required this.isDark});

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

class _FareComparisonCard extends StatelessWidget {
  final DdrRoute r;
  final bool isDark;
  const _FareComparisonCard({required this.r, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          const Text('ভাড়া (টোলসহ)', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _FareBox(label: '৫১ আসন', fare: r.totalFare51Seat, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _FareBox(label: '৮০ আসন', fare: r.totalFare80Seat, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FareBox extends StatelessWidget {
  final String label;
  final double fare;
  final bool isDark;
  const _FareBox({required this.label, required this.fare, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '৳${fare.toStringAsFixed(fare == fare.roundToDouble() ? 0 : 2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TollDetailsCard extends StatelessWidget {
  final DdrRoute r;
  final bool isDark;
  const _TollDetailsCard({required this.r, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ভাড়া বিবরণ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _DetailRow(label: 'দূরত্ব', value: '${r.totalDistanceKm} কিমি'),
          _DetailRow(label: 'ভাড়ার হার', value: '${r.farePerKm} টাকা/কিমি'),
          _Divider(),
          _DetailRow(label: '৫১ আসন ভাড়া (টোল ছাড়া)', value: '৳${r.fare51SeatWithoutToll.toStringAsFixed(0)}'),
          _DetailRow(label: '৮০ আসন ভাড়া (টোল ছাড়া)', value: '৳${r.fare80SeatWithoutToll.toStringAsFixed(0)}'),
          if (r.toll > 0) ...[
            _Divider(),
            _DetailRow(label: 'টোল (মোট)', value: '৳${r.toll.toStringAsFixed(0)}'),
            _DetailRow(label: '৫১ আসনে যাত্রীপ্রতি টোল', value: '৳${r.tollPerPassenger51Seat.toStringAsFixed(2)}'),
            _DetailRow(label: '৮০ আসনে যাত্রীপ্রতি টোল', value: '৳${r.tollPerPassenger80Seat.toStringAsFixed(2)}'),
          ],
          _Divider(),
          _DetailRow(
            label: '৫১ আসন মোট ভাড়া (টোলসহ)',
            value: '৳${r.totalFare51Seat.toStringAsFixed(0)}',
            bold: true,
          ),
          _DetailRow(
            label: '৮০ আসন মোট ভাড়া (টোলসহ)',
            value: '৳${r.totalFare80Seat.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DetailRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 16, color: Colors.grey.withValues(alpha: 0.2));
  }
}

