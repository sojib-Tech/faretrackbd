import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ShakeSosService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription? _subscription;
  static bool _isActive = false;
  static DateTime? _lastShake;
  static int _shakeCount = 0;

  static const double _threshold = 25.0;
  static const int _requiredShakes = 3;
  static const int _windowSeconds = 2;

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notif.initialize(settings);
  }

  static void start(BuildContext context) {
    if (_isActive) return;
    _isActive = true;

    _subscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude > _threshold) {
        final now = DateTime.now();

        if (_lastShake == null ||
            now.difference(_lastShake!).inSeconds > _windowSeconds) {
          _shakeCount = 0;
        }

        _shakeCount++;
        _lastShake = now;

        if (_shakeCount >= _requiredShakes) {
          _shakeCount = 0;
          _triggerSos(context);
        }
      }
    });
  }

  static void stop() {
    _subscription?.cancel();
    _isActive = false;
    _shakeCount = 0;
  }

  static bool get isActive => _isActive;

  static Future<void> _triggerSos(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    if (context.mounted) {
      _showCountdownDialog(context);
    }
  }

  static void _showCountdownDialog(BuildContext context) {
    int countdown = 5;
    Timer? timer;
    bool cancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (cancelled) return;
          if (countdown <= 1) {
            timer?.cancel();
            Navigator.pop(ctx);
            _dial999();
          } else {
            setS(() => countdown--);
          }
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF1A0A0A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text('SOS Detected!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '$countdown সেকেন্ডের মধ্যে 999-এ call যাবে',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: countdown / 5,
                      color: Colors.redAccent,
                      strokeWidth: 4,
                    ),
                    Text('$countdown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  cancelled = true;
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('বাতিল করুন',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        );
      }),
    );
  }

  static Future<void> _dial999() async {
    final uri = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
