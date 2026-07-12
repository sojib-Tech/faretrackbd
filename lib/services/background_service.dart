import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_strings.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance =
      BackgroundServiceManager._();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._();

  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _notifications!.initialize(initSettings);
    _initialized = true;
  }

  Future<void> configureBackgroundService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'faretrack_channel',
      'FareTrack Location Service',
      description: 'Shows current trip status',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    final flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'faretrack_channel',
        initialNotificationTitle: AppStrings.notifTitle,
        initialNotificationContent: 'প্রস্তুত...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    final plugin = FlutterLocalNotificationsPlugin();

    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    service.on('updateLocation').listen((event) async {
      if (event == null) return;
      final data = event;

      final distance = (data['distance'] as num?)?.toDouble() ?? 0;
      final fare = (data['fare'] as num?)?.toDouble() ?? 0;

      final notifBody =
          'দূরত্ব: ${distance.toStringAsFixed(2)} কিমি • ভাড়া: ৳${fare.toStringAsFixed(2)}';

      try {
        await plugin.show(
          888,
          AppStrings.notifTitle,
          notifBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'faretrack_channel',
              'FareTrack Location Service',
              ongoing: true,
              autoCancel: false,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'stopService',
                  AppStrings.notifStopAction,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ],
            ),
          ),
        );
      } catch (_) {}
    });

    try {
      await plugin.show(
        888,
        AppStrings.notifTitle,
        'প্রস্তুত...',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'faretrack_channel',
            'FareTrack Location Service',
            ongoing: true,
            autoCancel: false,
          ),
        ),
      );
    } catch (_) {}
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  Future<void> updateLocation({
    required double distance,
    required double fare,
  }) async {
    final service = FlutterBackgroundService();
    service.invoke('updateLocation', {
      'distance': distance,
      'fare': fare,
    });
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
