import 'package:intl/intl.dart';
import 'gps_point.dart';

class TripModel {
  final String id;
  final String? userId;
  final DateTime startTime;
  DateTime? endTime;
  double totalDistanceKm;
  double totalFare;
  double jamDistanceKm;
  Duration jamDuration;
  List<GpsPoint> routePoints;
  TripStatus status;

  TripModel({
    required this.id,
    this.userId,
    required this.startTime,
    this.endTime,
    this.totalDistanceKm = 0,
    this.totalFare = 0,
    this.jamDistanceKm = 0,
    this.jamDuration = Duration.zero,
    List<GpsPoint>? routePoints,
    this.status = TripStatus.active,
  }) : routePoints = routePoints ?? [];

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hoursঘ $minutesমি';
    }
    return '$minutes মিনিট';
  }

  String get formattedDistance =>
      '${totalDistanceKm.toStringAsFixed(2)} কিমি';

  String get formattedFare => '৳${totalFare.toStringAsFixed(2)}';

  double get averageSpeed {
    final hours = duration.inSeconds / 3600;
    if (hours == 0 || totalDistanceKm == 0) return 0;
    return (totalDistanceKm / hours * 100).roundToDouble() / 100;
  }

  String get formattedAverageSpeed =>
      '${averageSpeed.toStringAsFixed(1)} কিমি/ঘ';

  String get formattedJamTime {
    final m = jamDuration.inMinutes;
    return '$m মিনিট';
  }

  String get formattedStartTime =>
      DateFormat('hh:mm a').format(startTime);

  String get formattedEndTime {
    if (endTime == null) return '--';
    return DateFormat('hh:mm a').format(endTime!);
  }

  String get formattedDate =>
      DateFormat('MMM dd, yyyy').format(startTime);

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'totalDistanceKm': totalDistanceKm,
        'totalFare': totalFare,
        'jamDistanceKm': jamDistanceKm,
        'jamDuration': jamDuration.inSeconds,
        'status': status.name,
        'routePoints': routePoints
            .map((p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                  'accuracy': p.accuracy,
                  'speed': p.speed,
                  'heading': p.heading,
                  'timestamp': p.timestamp.toIso8601String(),
                })
            .toList(),
      };

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
        totalFare: (json['totalFare'] as num).toDouble(),
        jamDistanceKm: (json['jamDistanceKm'] as num).toDouble(),
        jamDuration: Duration(seconds: json['jamDuration'] as int),
        status: TripStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TripStatus.active,
        ),
        routePoints: (json['routePoints'] as List<dynamic>?)
                ?.map((p) => GpsPoint(
                      latitude: (p['lat'] as num).toDouble(),
                      longitude: (p['lng'] as num).toDouble(),
                      accuracy: (p['accuracy'] as num?)?.toDouble() ?? 0,
                      speed: (p['speed'] as num?)?.toDouble() ?? 0,
                      heading: (p['heading'] as num?)?.toDouble() ?? 0,
                      timestamp: DateTime.parse(p['timestamp'] as String),
                    ))
                .toList() ??
            [],
      );
}

enum TripStatus { active, completed }
