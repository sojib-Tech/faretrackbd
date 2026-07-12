import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/color_extensions.dart';
import '../../models/bus_route.dart';
import '../../data/bus_route_data.dart';
import '../../services/bus_fare_calculator.dart';
import 'route_detail_screen.dart';

class FareCalculatorScreen extends StatefulWidget {
  const FareCalculatorScreen({super.key});

  @override
  State<FareCalculatorScreen> createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  BusRoute? _selectedRoute;
  BusStop? _fromStop;
  BusStop? _toStop;
  FareCalculationResult? _result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ভাড়া ক্যালকুলেটর'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'রুট নির্বাচন করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _RouteDropdown(
              selectedRoute: _selectedRoute,
              onChanged: (r) => setState(() {
                _selectedRoute = r;
                _fromStop = null;
                _toStop = null;
                _result = null;
              }),
            ),
            if (_selectedRoute != null) ...[
              const SizedBox(height: 20),
              const Text(
                'উৎস স্টপেজ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _StopDropdown(
                stops: _selectedRoute!.stops,
                selectedStop: _fromStop,
                hint: 'কোথান থেকে?',
                onChanged: (s) => setState(() {
                  _fromStop = s;
                  _calculate();
                }),
              ),
              const SizedBox(height: 16),
              Center(
                child: Icon(Icons.arrow_downward_rounded,
                    color: Colors.grey[400], size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'গন্তব্য স্টপেজ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _StopDropdown(
                stops: _selectedRoute!.stops,
                selectedStop: _toStop,
                hint: 'কোথায়?',
                onChanged: (s) => setState(() {
                  _toStop = s;
                  _calculate();
                }),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: _result!, isDark: isDark),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailScreen(route: _result!.route),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                  label: Text('${_result!.route.routeNo} - রুট বিস্তারিত দেখুন'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _calculate() {
    if (_selectedRoute == null || _fromStop == null || _toStop == null) {
      setState(() => _result = null);
      return;
    }
    final result = BusFareCalculator.findFare(
      routeId: _selectedRoute!.id,
      fromStopName: _fromStop!.name,
      toStopName: _toStop!.name,
    );
    setState(() => _result = result);
  }
}

class _RouteDropdown extends StatelessWidget {
  final BusRoute? selectedRoute;
  final ValueChanged<BusRoute?> onChanged;
  const _RouteDropdown({required this.selectedRoute, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BusRoute>(
      initialValue: selectedRoute,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('রুট বাছাই করুন'),
      isExpanded: true,
      items: BusRouteData.allRoutes.map((r) {
        return DropdownMenuItem(value: r, child: Text(r.nameBn));
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _StopDropdown extends StatelessWidget {
  final List<BusStop> stops;
  final BusStop? selectedStop;
  final String hint;
  final ValueChanged<BusStop?> onChanged;
  const _StopDropdown({
    required this.stops,
    required this.selectedStop,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BusStop>(
      initialValue: selectedStop,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: Text(hint),
      isExpanded: true,
      items: stops.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text('${s.name} (${s.distanceFromStartKm} কিমি)'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _ResultCard extends StatelessWidget {
  final FareCalculationResult result;
  final bool isDark;
  const _ResultCard({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppConstants.primaryGreen.darken(0.3), AppConstants.primaryGreen]
              : [AppConstants.primaryGreen, AppConstants.primaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('মোট ভাড়া', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            result.formattedFare,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${result.formattedDistance} • ${result.route.routeNo}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.trip_origin_rounded, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    Text(result.fromStop.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white54),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.flag_rounded, color: Colors.white70, size: 20),
                    const SizedBox(height: 4),
                    Text(result.toStop.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

