import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../models/gps_point.dart';
import '../home/widgets/bus_animated_marker.dart';

class FullMapScreen extends StatefulWidget {
  final List<GpsPoint>? routePoints;

  const FullMapScreen({super.key, this.routePoints});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late MapController _mapController;
  List<LatLng> _routeLatLngs = [];
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _routeLatLngs = widget.routePoints!
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      _currentPosition = _routeLatLngs.last;
    } else {
      _currentPosition = const LatLng(23.8103, 90.4125);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapBounds();
    });
  }

  void _fitMapBounds() {
    if (_routeLatLngs.length < 2) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_routeLatLngs),
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition ?? const LatLng(23.8103, 90.4125),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.tileUrl,
                userAgentPackageName: 'com.faretrackbd.app',
              ),
              if (_routeLatLngs.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeLatLngs,
                      color: AppConstants.primaryAccent.withValues(alpha: 0.8),
                      strokeWidth: 4,
                      borderColor: Colors.white.withValues(alpha: 0.3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 48,
                      height: 48,
                      child: BusAnimatedMarker(
                        heading: widget.routePoints != null &&
                                widget.routePoints!.length > 1
                            ? _calculateHeading(
                                widget
                                    .routePoints![widget.routePoints!.length - 2],
                                widget.routePoints!.last,
                              )
                            : 0,
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: _buildInfoCard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            .withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 20,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'যাত্রাপথ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_routeLatLngs.isNotEmpty)
            Text(
              '${_routeLatLngs.length} টি পয়েন্ট · শেষ অবস্থান: ${_currentPosition?.latitude.toStringAsFixed(4)}, ${_currentPosition?.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  double _calculateHeading(GpsPoint from, GpsPoint to) {
    final dLon = (to.longitude - from.longitude) * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final heading = atan2(y, x) * 180 / pi;
    return (heading + 360) % 360;
  }
}
