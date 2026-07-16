import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dhaka_zone_data.dart';
import '../../data/stop_coordinates.dart';
import '../../models/journey/journey_result.dart';
import '../../models/zone_model.dart';

class JourneyMapScreen extends StatefulWidget {
  final JourneyResult result;

  const JourneyMapScreen({super.key, required this.result});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  late MapController _mapController;
  List<LatLng> _busRoutePoints = [];
  LatLng? _origin;
  LatLng? _destination;
  List<DhakaZone> _zones = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _extractRouteData();
    _loadZones();
  }

  void _extractRouteData() {
    final result = widget.result;
    final allPoints = <LatLng>[];

    for (final seg in result.busSegments) {
      final route = seg.route;
      final start = seg.boardStopIndex < seg.alightStopIndex
          ? seg.boardStopIndex
          : seg.alightStopIndex;
      final end = seg.boardStopIndex < seg.alightStopIndex
          ? seg.alightStopIndex
          : seg.boardStopIndex;

      for (int i = start; i <= end && i < route.stops.length; i++) {
        final stopName = route.stops[i].name;
        final coord = StopCoordinates.find(stopName);
        if (coord != null) {
          final point = LatLng(coord.lat, coord.lng);
          if (allPoints.isEmpty || allPoints.last != point) {
            allPoints.add(point);
          }
        }
      }
    }

    if (allPoints.isNotEmpty) {
      _origin = allPoints.first;
      _destination = allPoints.last;
    }

    _busRoutePoints = allPoints;
  }

  Future<void> _loadZones() async {
    final zones = await DhakaZoneData.getZones();
    if (mounted) {
      setState(() {
        _zones = zones;
        _loaded = true;
      });
      _fitBounds();
    }
  }

  void _fitBounds() {
    final allPoints = <LatLng>[
      ?_origin,
      ?_destination,
      ..._busRoutePoints,
    ];
    if (allPoints.length < 2) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(allPoints),
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
    final result = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'যাত্রাপথ মানচিত্র',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppConstants.fontBengali,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _origin ?? const LatLng(23.8103, 90.4125),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.tileUrl,
                userAgentPackageName: 'com.faretrackbd.app',
              ),
              if (_loaded)
                PolygonLayer(
                  polygons: _zones.map((zone) {
                    final points = zone.coordinates[0]
                        .map((coord) => LatLng(coord[1], coord[0]))
                        .toList();
                    return Polygon(
                      points: points,
                      color: zone.fillColor.withValues(alpha: 0.15),
                      borderColor: zone.borderColor.withValues(alpha: 0.5),
                      borderStrokeWidth: 1.5,
                    );
                  }).toList(),
                ),
              if (_busRoutePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _busRoutePoints,
                      color: AppConstants.primaryGreen,
                      strokeWidth: 5,
                      borderColor: Colors.white.withValues(alpha: 0.6),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_origin != null && _destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _origin!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.errorRed.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: _buildInfoBar(result, isDark),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _buildBottomCard(result, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(JourneyResult result, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _infoChip(
            Icons.straighten_rounded,
            result.totalDistanceFormatted,
            AppConstants.primaryGreen,
          ),
          const SizedBox(width: 10),
          _infoChip(
            Icons.access_time_rounded,
            result.totalTimeFormatted,
            AppConstants.primaryAccent,
          ),
          const SizedBox(width: 10),
          _infoChip(
            Icons.payments_outlined,
            '৳${result.totalFare.toStringAsFixed(0)}',
            AppConstants.fareAmber,
          ),
          const Spacer(),
          Text(
            '${result.busSegments.length} বাস',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppConstants.fontBengali,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppConstants.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.fontBengali,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(JourneyResult result, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...result.busSegments.asMap().entries.map((e) {
            final seg = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seg.isAc ? AppConstants.primaryAccent : AppConstants.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seg.busNameBn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppConstants.fontBengali,
                            color: isDark ? Colors.white : AppConstants.ink,
                          ),
                        ),
                        Text(
                          '${seg.boardStop} → ${seg.alightStop} · ${seg.distanceKm.toStringAsFixed(1)} কিমি',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppConstants.fontBengali,
                            color: isDark ? Colors.white54 : AppConstants.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '৳${seg.fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.fareAmber,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
