import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/road_router.dart';
import '../../data/stop_coordinates.dart';
import '../../data/dhaka_zone_data.dart';
import '../../models/journey/journey_result.dart';
import '../../models/zone_model.dart';

class JourneyMapScreen extends StatefulWidget {
  final JourneyResult result;

  const JourneyMapScreen({super.key, required this.result});

  @override
  State<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _PathSegment {
  final List<LatLng> rawPoints;
  final List<LatLng> roadPoints;
  final List<String> names;
  final Color color;
  final bool isBus;
  final bool isAc;
  final String label;

  _PathSegment({
    required this.rawPoints,
    required this.color,
    required this.isBus,
    required this.isAc,
    required this.label,
    List<String>? names,
    List<LatLng>? roadPoints,
  })  : roadPoints = roadPoints ?? const [],
        names = names ?? const [];

  void setRoad(List<LatLng> pts) {
    roadPoints
      ..clear()
      ..addAll(pts);
  }
}

class _JourneyMapScreenState extends State<JourneyMapScreen> {
  late MapController _mapController;
  final List<_PathSegment> _segments = [];
  LatLng? _origin;
  LatLng? _destination;
  List<DhakaZone> _zones = [];
  bool _loaded = false;

  static const List<Color> _busPalette = [
    AppConstants.primaryGreen,
    AppConstants.primaryAccent,
    AppConstants.fareAmber,
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _extractRouteData();
    _loadZones();
  }

  LatLng? _resolve(String label) {
    if (label.isEmpty) return null;
    final c = StopCoordinates.find(label);
    if (c != null) return LatLng(c.lat, c.lng);
    return null;
  }

  void _extractRouteData() {
    _segments.clear();
    final result = widget.result;

    final firstSeg = result.segments.isNotEmpty ? result.segments.first : null;
    final lastSeg = result.segments.isNotEmpty ? result.segments.last : null;

    final firstBus = result.busSegments.isNotEmpty ? result.busSegments.first : null;
    final lastBus = result.busSegments.isNotEmpty ? result.busSegments.last : null;

    if (firstBus != null) {
      _origin = _resolve(firstBus.boardStop) ?? _resolve(firstBus.busNameBn);
    } else {
      _origin = _resolve(firstSeg?.runtimeType == WalkingSegment
          ? (firstSeg as WalkingSegment).fromLabel
          : '');
    }
    if (lastBus != null) {
      _destination = _resolve(lastBus.alightStop) ?? _resolve(lastBus.busNameBn);
    } else {
      _destination = _resolve(lastSeg?.runtimeType == WalkingSegment
          ? (lastSeg as WalkingSegment).toLabel
          : '');
    }

    int busIndex = 0;
    for (final seg in result.segments) {
      if (seg is BusSegment) {
        final color = _busPalette[busIndex % _busPalette.length];
        busIndex++;
        final built = _busPoints(seg);
        if (built.points.length >= 2) {
          _segments.add(_PathSegment(
            rawPoints: built.points,
            names: built.names,
            color: color,
            isBus: true,
            isAc: seg.isAc,
            label: seg.busNameBn,
          ));
        }
      } else if (seg is WalkingSegment) {
        final built = _walkPoints(seg);
        if (built.points.length >= 2) {
          _segments.add(_PathSegment(
            rawPoints: built.points,
            names: built.names,
            color: Colors.grey.shade500,
            isBus: false,
            isAc: false,
            label: 'হাঁটা',
          ));
        }
      } else if (seg is TransferSegment) {
        final from = _resolve(seg.fromStop);
        final to = _resolve(seg.toStop);
        if (from != null && to != null && from != to) {
          _segments.add(_PathSegment(
            rawPoints: [from, to],
            names: [seg.fromStop, seg.toStop],
            color: AppConstants.fareAmber,
            isBus: false,
            isAc: false,
            label: 'সংযোগ',
          ));
        }
      }
    }

    if (_origin == null) {
      for (final seg in _segments) {
        if (seg.rawPoints.isNotEmpty) {
          _origin = seg.rawPoints.first;
          break;
        }
      }
    }
    if (_destination == null) {
      for (final seg in _segments.reversed) {
        if (seg.rawPoints.isNotEmpty) {
          _destination = seg.rawPoints.last;
          break;
        }
      }
    }
  }

  ({List<LatLng> points, List<String> names}) _busPoints(BusSegment seg) {
    final route = seg.route;
    final start = seg.boardStopIndex < seg.alightStopIndex
        ? seg.boardStopIndex
        : seg.alightStopIndex;
    final end = seg.boardStopIndex < seg.alightStopIndex
        ? seg.alightStopIndex
        : seg.boardStopIndex;
    final pts = <LatLng>[];
    final names = <String>[];
    for (int i = start; i <= end && i < route.stops.length; i++) {
      final c = StopCoordinates.find(route.stops[i].name);
      if (c != null) {
        pts.add(LatLng(c.lat, c.lng));
        names.add(route.stops[i].name);
      }
    }
    return (points: pts, names: names);
  }

  ({List<LatLng> points, List<String> names}) _walkPoints(WalkingSegment seg) {
    final from = _resolve(seg.fromLabel);
    final to = _resolve(seg.toLabel);
    if (from != null && to != null) {
      return (
        points: [from, to],
        names: [seg.fromLabel, seg.toLabel],
      );
    }
    if (from != null) return (points: [from], names: [seg.fromLabel]);
    if (to != null) return (points: [to], names: [seg.toLabel]);
    return (points: const [], names: const []);
  }

  Future<void> _loadZones() async {
    final zones = await DhakaZoneData.getZones();
    if (mounted) {
      setState(() {
        _zones = zones;
        _loaded = true;
      });
      _fitBounds();
      unawaited(_fetchRoadRoutes());
    }
  }

  Future<void> _fetchRoadRoutes() async {
    for (final seg in _segments) {
      if (seg.rawPoints.length < 2) continue;
      final pts = await RoadRouter.getRoadRoute(seg.rawPoints);
      if (!mounted) return;
      if (pts.length > seg.rawPoints.length) {
        setState(() => seg.setRoad(pts));
      }
    }
  }

  void _fitBounds() {
    final allPoints = <LatLng>[
      ?_origin,
      ?_destination,
      ..._segments.expand((s) => s.rawPoints),
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
              PolylineLayer(
                polylines: _buildRoadPolylines(),
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
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
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
                        child: const Center(
                          child: Text(
                            'B',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_segments.length > 1)
                MarkerLayer(
                  markers: _buildTransferMarkers(),
                ),
              MarkerLayer(
                markers: _buildStopMarkers(),
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

  List<Polyline> _buildRoadPolylines() {
    final lines = <Polyline>[];
    for (final s in _segments.where((s) => s.rawPoints.length > 1)) {
      final pts = s.roadPoints.length > s.rawPoints.length
          ? s.roadPoints
          : s.rawPoints;
      if (s.isBus) {
        lines.add(Polyline(
          points: pts,
          color: Colors.white,
          strokeWidth: s.isAc ? 11 : 9,
        ));
        lines.add(Polyline(
          points: pts,
          color: s.color,
          strokeWidth: s.isAc ? 6 : 5,
          pattern: const StrokePattern.solid(),
        ));
      } else {
        lines.add(Polyline(
          points: pts,
          color: s.color,
          strokeWidth: 3,
          pattern: StrokePattern.dashed(segments: const [6, 4]),
        ));
      }
    }
    return lines;
  }

  List<Marker> _buildTransferMarkers() {
    final markers = <Marker>[];
    for (int i = 1; i < _segments.length; i++) {
      final prev = _segments[i - 1];
      final curr = _segments[i];
      if (prev.rawPoints.isEmpty || curr.rawPoints.isEmpty) continue;
      if (prev.isBus && curr.isBus) {
        final pt = prev.rawPoints.last;
        markers.add(Marker(
          point: pt,
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.fareAmber,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.transfer_within_a_station_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ));
      }
    }
    return markers;
  }

  List<Marker> _buildStopMarkers() {
    final markers = <Marker>[];
    for (final seg in _segments) {
      for (int i = 0; i < seg.rawPoints.length; i++) {
        final pt = seg.rawPoints[i];
        if (_origin != null && pt == _origin) continue;
        if (_destination != null && pt == _destination) continue;
        final name = i < seg.names.length ? seg.names[i] : '';
        markers.add(Marker(
          point: pt,
          width: 14,
          height: 14,
          child: GestureDetector(
            onTap: () {
              if (name.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      name,
                      style: const TextStyle(fontFamily: AppConstants.fontBengali),
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: seg.color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }
    return markers;
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
            final i = e.key;
            final seg = e.value;
            final color = _busPalette[i % _busPalette.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${seg.busNameBn}',
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