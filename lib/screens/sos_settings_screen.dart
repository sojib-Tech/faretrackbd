import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shake_sos_service.dart';

class SosSettingsScreen extends StatefulWidget {
  const SosSettingsScreen({super.key});

  @override
  State<SosSettingsScreen> createState() => _SosSettingsScreenState();
}

class _SosSettingsScreenState extends State<SosSettingsScreen> {
  bool _shakeEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _shakeEnabled = prefs.getBool('shake_sos') ?? false);
  }

  Future<void> _toggle(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_sos', val);
    if (!mounted) return;
    setState(() => _shakeEnabled = val);

    if (val) {
      ShakeSosService.start(context);
    } else {
      ShakeSosService.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('SOS Settings',
            style: TextStyle(fontSize: 15)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white10, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vibration,
                      color: Colors.redAccent, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shake-to-SOS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(
                            'Phone ৩ বার shake করলে 999 call হবে',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _shakeEnabled,
                    onChanged: _toggle,
                    activeTrackColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1200),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '৫ সেকেন্ড countdown থাকবে। Cancel করার সুযোগ পাবেন।',
                      style:
                          TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
