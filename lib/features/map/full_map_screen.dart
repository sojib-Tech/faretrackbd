import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dhaka_zone_data.dart';
import '../../models/gps_point.dart';
import '../../models/journey/stop_coordinate.dart';
import '../../models/zone_model.dart';
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
  List<DhakaZone> _zones = [];
  bool _zonesLoaded = false;
  final ValueNotifier<LayerHitResult<DhakaZone>?> _zoneHitNotifier = ValueNotifier(null);

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

    _loadZones();

    _zoneHitNotifier.addListener(_onZoneHit);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapBounds();
    });
  }

  Future<void> _loadZones() async {
    final zones = await DhakaZoneData.getZones();
    if (mounted) {
      setState(() {
        _zones = zones;
        _zonesLoaded = true;
      });
    }
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
    _zoneHitNotifier.removeListener(_onZoneHit);
    _zoneHitNotifier.dispose();
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
              if (_zonesLoaded && _zones.isNotEmpty)
                PolygonLayer(
                  hitNotifier: _zoneHitNotifier,
                  polygons: _zones.map((zone) {
                    final points = zone.coordinates[0]
                        .map((coord) => LatLng(coord[1], coord[0]))
                        .toList();
                    return Polygon(
                      points: points,
                      color: zone.fillColor.withValues(alpha: 0.2),
                      borderColor: zone.borderColor,
                      borderStrokeWidth: 2,
                      hitValue: zone,
                    );
                  }).toList(),
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

  void _onZoneHit() {
    final result = _zoneHitNotifier.value;
    if (result != null && result.hitValues.isNotEmpty) {
      _onZoneTap(result.hitValues.first);
    }
  }

  void _onZoneTap(DhakaZone zone) async {
    final stops = await DhakaZoneData.getStopsInZone(zone);
    if (!mounted) return;
    _showZoneStops(zone, stops);
  }

  void _showZoneStops(DhakaZone zone, List<StopCoordinate> stops) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: zone.fillColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppConstants.fontBengali,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${stops.length} টি স্টপ',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppConstants.fontBengali,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (stops.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'এই এলাকায় কোনো স্টপ পাওয়া যায়নি',
                  style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[500],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: stops.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (_, i) {
                    final stop = stops[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          size: 18,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                      title: Text(
                        stop.nameBn,
                        style: TextStyle(
                          fontFamily: AppConstants.fontBengali,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        stop.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions_rounded, color: AppConstants.primaryAccent),
                        tooltip: 'দিকনির্দেশনা',
                        onPressed: () => _openDirections(stop),
                      ),
                      onTap: () => _openDirections(stop),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDirections(StopCoordinate stop) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${stop.lat},${stop.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
