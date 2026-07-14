import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/accident_service.dart';

class AccidentMapScreen extends StatefulWidget {
  const AccidentMapScreen({super.key});

  @override
  State<AccidentMapScreen> createState() => _AccidentMapScreenState();
}

class _AccidentMapScreenState extends State<AccidentMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  StreamSubscription? _sub;
  String _filter = 'All';

  final List<String> _filters = ['All', 'Critical', 'Major', 'Minor'];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _listenAccidents();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _getLocation() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() => _currentPosition = pos);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
    );
  }

  void _listenAccidents() {
    _sub?.cancel();
    _sub = AccidentService.getRecentAccidents().listen((reports) {
      _buildMarkers(reports);
    });
  }

  void _buildMarkers(List<AccidentReport> reports) {
    final filtered = _filter == 'All'
        ? reports
        : reports.where((r) => r.severity == _filter).toList();

    final markers = filtered.map((r) {
      final hue = r.severity == 'Critical'
          ? BitmapDescriptor.hueRed
          : r.severity == 'Major'
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueYellow;

      return Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.lat, r.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: '${r.severity} — ${r.location}',
          snippet: _timeAgo(r.time),
          onTap: () => _showAccidentDetail(r),
        ),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    return '${diff.inHours} ঘণ্টা আগে';
  }

  void _showAccidentDetail(AccidentReport r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.severity == 'Critical'
                      ? const Color(0xFF2A0808)
                      : r.severity == 'Major'
                          ? const Color(0xFF2A2000)
                          : const Color(0xFF1A2A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.severity,
                    style: TextStyle(
                      color: r.severity == 'Critical'
                          ? Colors.redAccent
                          : r.severity == 'Major'
                              ? Colors.amber
                              : Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              const Spacer(),
              Text(_timeAgo(r.time),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Text(r.location,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.description,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AccidentService.upvote(r.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Report verified করলেন, ধন্যবাদ')),
                    );
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Verify (${r.upvotes})'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    if (_currentPosition == null) return;
    final descController = TextEditingController();
    String severity = 'Major';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accident Report করুন',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              const Text('Severity',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: ['Minor', 'Major', 'Critical'].map((s) {
                  final active = severity == s;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => severity = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF2A0808)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? Colors.redAccent
                                : Colors.white12,
                          ),
                        ),
                        child: Center(
                          child: Text(s,
                              style: TextStyle(
                                color: active
                                    ? Colors.redAccent
                                    : Colors.grey,
                                fontSize: 12,
                              )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'সংক্ষেপে বর্ণনা করুন (optional)',
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await AccidentService.reportAccident(
                      lat: _currentPosition!.latitude,
                      lng: _currentPosition!.longitude,
                      location: 'Current location',
                      severity: severity,
                      description: descController.text,
                    );
                    if (mounted) {
                      descController.dispose();
                      Navigator.pop(context);
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            success ? 'Accident report করা হয়েছে' : 'Report ব্যর্থ হয়েছে'),
                        backgroundColor: success ? Colors.red : Colors.grey,
                      ),
                    );
                  },
                  child: const Text('Report করুন',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Accident Map',
            style: TextStyle(fontSize: 15)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              children: _filters.map((f) {
                final active = _filter == f;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filter = f);
                    _listenAccidents();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.red
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.8041, 90.4152),
          zoom: 12,
        ),
        onMapCreated: (c) => _mapController = c,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'locate',
            backgroundColor: const Color(0xFF1A1A1A),
            onPressed: _getLocation,
            child: const Icon(Icons.my_location,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'report',
            backgroundColor: Colors.red,
            onPressed: _showReportDialog,
            icon: const Icon(Icons.add_location_alt,
                color: Colors.white, size: 20),
            label: const Text('Report',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
