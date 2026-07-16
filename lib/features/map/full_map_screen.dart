import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dhaka_zone_data.dart';
import '../../models/gps_point.dart';
import '../../models/journey/stop_coordinate.dart';
import '../../models/zone_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/trip_provider.dart';
import '../home/widgets/bus_animated_marker.dart';

class FullMapScreen extends ConsumerStatefulWidget {
  final List<GpsPoint>? routePoints;

  const FullMapScreen({super.key, this.routePoints});

  @override
  ConsumerState<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends ConsumerState<FullMapScreen> {
  late MapController _mapController;
  List<LatLng> _routeLatLngs = [];
  LatLng? _currentPosition;
  List<DhakaZone> _zones = [];
  bool _zonesLoaded = false;
  final ValueNotifier<LayerHitResult<DhakaZone>?> _zoneHitNotifier =
      ValueNotifier(null);
  Timer? _updateTimer;
  Duration _elapsed = Duration.zero;
  bool _initialCenterDone = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _routeLatLngs = widget.routePoints!
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      _currentPosition = _routeLatLngs.last;
    }

    _loadZones();
    _zoneHitNotifier.addListener(_onZoneHit);

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final tripState = ref.read(tripProvider);
      if (tripState.isActive && tripState.currentTrip != null) {
        setState(() {
          _elapsed =
              DateTime.now().difference(tripState.currentTrip!.startTime);
        });
      }
    });

    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = ref.read(locationServiceProvider);

    final hasPermission = await locationService.hasPermissions();
    if (!hasPermission) {
      final granted = await locationService.requestPermissions();
      if (!granted) {
        _setDefaultPosition();
        return;
      }
    }

    final point = await locationService.getCurrentLocation();
    if (point != null && mounted) {
      final newPos = LatLng(point.latitude, point.longitude);
      setState(() {
        _currentPosition = newPos;
      });
      if (!_initialCenterDone) {
        _initialCenterDone = true;
        try {
          _mapController.move(newPos, 15);
        } catch (_) {}
      }
    } else {
      _setDefaultPosition();
    }

    if (mounted) {
      ref.read(locationProvider.notifier).startListening();
    }
  }

  void _setDefaultPosition() {
    if (_currentPosition == null) {
      setState(() {
        _currentPosition = const LatLng(23.8103, 90.4125);
      });
      if (!_initialCenterDone) {
        _initialCenterDone = true;
        try {
          _mapController.move(_currentPosition!, 15);
        } catch (_) {}
      }
    }
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

  @override
  void dispose() {
    _updateTimer?.cancel();
    _zoneHitNotifier.removeListener(_onZoneHit);
    _zoneHitNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tripState = ref.watch(tripProvider);
    final locationState = ref.watch(locationProvider);
    final isActive = tripState.isActive;

    if (!isActive &&
        locationState.currentPoint != null &&
        _currentPosition == null) {
      final gp = locationState.currentPoint!;
      _currentPosition = LatLng(gp.latitude, gp.longitude);
    }

    if (!isActive && locationState.currentPoint != null) {
      final gp = locationState.currentPoint!;
      final newPos = LatLng(gp.latitude, gp.longitude);
      if (_currentPosition == null ||
          (_currentPosition!.latitude - newPos.latitude).abs() > 0.00001 ||
          (_currentPosition!.longitude - newPos.longitude).abs() > 0.00001) {
        _currentPosition = newPos;
      }
    }

    if (isActive && tripState.routePoints.isNotEmpty) {
      _routeLatLngs = tripState.routePoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      _currentPosition = _routeLatLngs.last;
    }

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
              initialCenter: _currentPosition ??
                  const LatLng(23.8103, 90.4125),
              initialZoom: 15,
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
                      color: AppConstants.primaryAccent
                          .withValues(alpha: 0.8),
                      strokeWidth: 4,
                      borderColor:
                          Colors.white.withValues(alpha: 0.3),
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
                      child: isActive
                          ? BusAnimatedMarker(
                              heading: widget.routePoints != null &&
                                      widget.routePoints!.length > 1
                                  ? _calculateHeading(
                                      widget.routePoints![
                                          widget.routePoints!.length - 2],
                                      widget.routePoints!.last,
                                    )
                                  : 0,
                              size: 44,
                            )
                          : Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),
          if (isActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: _buildMeterCard(tripState, isDark),
            ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: isActive
                ? _buildActiveInfoCard(tripState, isDark)
                : _buildInfoCard(isDark, locationState),
          ),
          if (!isActive)
            Positioned(
              right: 16,
              bottom: 180,
              child: _buildLocateMeButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocateMeButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: () async {
        final locationService = ref.read(locationServiceProvider);
        final point = await locationService.getCurrentLocation();
        if (point != null && mounted) {
          final newPos = LatLng(point.latitude, point.longitude);
          setState(() {
            _currentPosition = newPos;
          });
          _mapController.move(newPos, 15);
        }
      },
      child: const Icon(Icons.my_location, color: AppConstants.primaryAccent),
    );
  }

  Widget _buildMeterCard(TripState tripState, bool isDark) {
    final speed = tripState.currentDistance > 0 && _elapsed.inSeconds > 0
        ? (tripState.currentDistance / (_elapsed.inSeconds / 3600))
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _meterItem(
            Icons.straighten_rounded,
            '${tripState.currentDistance.toStringAsFixed(1)} কিমি',
            'দূরত্ব',
            AppConstants.primaryGreen,
          ),
          Container(
              width: 1, height: 36, color: AppConstants.cardLine),
          _meterItem(
            Icons.access_time_rounded,
            _formatDuration(_elapsed),
            'সময়',
            AppConstants.primaryAccent,
          ),
          Container(
              width: 1, height: 36, color: AppConstants.cardLine),
          _meterItem(
            Icons.payments_outlined,
            '৳${tripState.currentFare.toStringAsFixed(0)}',
            'ভাড়া',
            AppConstants.fareAmber,
          ),
          Container(
              width: 1, height: 36, color: AppConstants.cardLine),
          _meterItem(
            Icons.speed_rounded,
            '${speed.toStringAsFixed(0)} km/h',
            'গতি',
            tripState.isJam
                ? AppConstants.warn
                : AppConstants.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _meterItem(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontEnglish,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildActiveInfoCard(TripState tripState, bool isDark) {
    final maxFare = 100.0;
    final progress = (tripState.currentFare / maxFare).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppConstants.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.successGreen
                          .withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tripState.isJam ? 'জ্যাম এলাকায়' : 'চলছে',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: tripState.isJam
                      ? AppConstants.warn
                      : AppConstants.primaryGreen,
                ),
              ),
              const Spacer(),
              Text(
                '${_routeLatLngs.length} পয়েন্ট',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppConstants.fontBengali,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppConstants.cardLine,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.3
                    ? AppConstants.primaryGreen
                    : progress < 0.6
                        ? AppConstants.fareAmber
                        : AppConstants.errorRed,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ভাড়া: ৳${tripState.currentFare.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: AppConstants.fareAmber,
                ),
              ),
              Text(
                'সর্বোচ্চ: ৳${maxFare.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppConstants.fontBengali,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, LocationState locationState) {
    final hasLocation = _currentPosition != null;
    final isDefault =
        _currentPosition?.latitude == 23.8103 &&
        _currentPosition?.longitude == 90.4125;

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
                hasLocation && !isDefault
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                size: 20,
                color: hasLocation && !isDefault
                    ? AppConstants.primaryGreen
                    : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasLocation && !isDefault
                      ? 'আপনার অবস্থান'
                      : 'লোকেশন পাওয়া যায়নি',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasLocation && !isDefault)
            Text(
              '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppConstants.fontEnglish,
                color: Colors.grey[500],
              ),
            )
          else
            Text(
              'বাস খুঁজতে উপরের সার্চ ব্যবহার করুন',
              style: TextStyle(
                fontSize: 13,
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
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
                            color:
                                isDark ? Colors.white : Colors.black87,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: stops.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (_, i) {
                    final stop = stops[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen
                              .withValues(alpha: 0.1),
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
                          color:
                              isDark ? Colors.white : Colors.black87,
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
                        icon: const Icon(Icons.directions_rounded,
                            color: AppConstants.primaryAccent),
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
