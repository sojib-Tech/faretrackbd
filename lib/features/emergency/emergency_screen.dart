import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  String _severity = 'Critical';
  String _locationText = 'Detecting location...';
  String _coordinates = '';
  bool _calling = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _severities = [
    {'label': 'Minor', 'color': const Color(0xFF4ADE80), 'bg': const Color(0xFF1A2A1A)},
    {'label': 'Major', 'color': const Color(0xFFFBBF24), 'bg': const Color(0xFF2A2000)},
    {'label': 'Critical', 'color': const Color(0xFFF87171), 'bg': const Color(0xFF2A0A0A)},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _detectLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(() => _locationText = 'Location permission denied');
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _locationText = 'Dhaka, Bangladesh';
        _coordinates =
            '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
      });
    } catch (e) {
      if (mounted) setState(() => _locationText = 'Could not detect location');
    }
  }

  Future<void> _call999() async {
    HapticFeedback.heavyImpact();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Call 999?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'This will place a real emergency call to Bangladesh Police/Fire/Ambulance.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Call now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _calling = true);
    final Uri uri = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
    if (mounted) setState(() => _calling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Report',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            Text('FareTrack BD • Safety',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white12),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationCard(),
            const SizedBox(height: 16),

            const Text('Severity',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSeverityRow(),
            const SizedBox(height: 28),

            _buildCallButton(),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Opens native dialer — real call to Bangladesh Police',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            Row(children: [
              const Expanded(child: Divider(color: Colors.white12)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('also', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ),
              const Expanded(child: Divider(color: Colors.white12)),
            ]),
            const SizedBox(height: 16),

            _buildSecondaryAction(
              icon: Icons.map_outlined,
              color: const Color(0xFF378ADD),
              label: 'Log accident on map for others',
              onTap: () {
                // TODO: push to map pin screen
              },
            ),
            const SizedBox(height: 8),
            _buildSecondaryAction(
              icon: Icons.share_location_outlined,
              color: const Color(0xFFEF9F27),
              label: 'Share live location with contact',
              onTap: () {
                // TODO: share location sheet
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current location',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(_locationText,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                if (_coordinates.isNotEmpty)
                  Text(_coordinates,
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
          GestureDetector(
            onTap: _detectLocation,
            child: const Icon(Icons.refresh, color: Colors.white24, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityRow() {
    return Row(
      children: _severities.map((s) {
        final isActive = _severity == s['label'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _severity = s['label']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: s['bg'],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? s['color'] : Colors.white12,
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  s['label'],
                  style: TextStyle(
                    color: s['color'],
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCallButton() {
    return Center(
      child: GestureDetector(
        onTap: _calling ? null : _call999,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A0808),
              border: Border.all(color: const Color(0xFF7F1D1D), width: 1.5),
            ),
            child: Center(
              child: _calling
                  ? const CircularProgressIndicator(
                      color: Colors.redAccent, strokeWidth: 2)
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDC2626),
                      ),
                      child: const Icon(Icons.call, color: Colors.white, size: 26),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
