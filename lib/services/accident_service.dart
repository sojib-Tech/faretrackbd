import 'package:cloud_firestore/cloud_firestore.dart';

class AccidentReport {
  final String id;
  final double lat;
  final double lng;
  final String location;
  final String severity;
  final String description;
  final DateTime time;
  final int upvotes;

  AccidentReport({
    required this.id,
    required this.lat,
    required this.lng,
    required this.location,
    required this.severity,
    required this.description,
    required this.time,
    required this.upvotes,
  });

  factory AccidentReport.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AccidentReport(
      id: doc.id,
      lat: (d['lat'] as num).toDouble(),
      lng: (d['lng'] as num).toDouble(),
      location: d['location'] ?? '',
      severity: d['severity'] ?? 'Minor',
      description: d['description'] ?? '',
      time: (d['time'] as Timestamp).toDate(),
      upvotes: (d['upvotes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccidentService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'accident_reports';

  static Future<bool> reportAccident({
    required double lat,
    required double lng,
    required String location,
    required String severity,
    required String description,
  }) async {
    try {
      await _db.collection(_col).add({
        'lat': lat,
        'lng': lng,
        'location': location,
        'severity': severity,
        'description': description,
        'time': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'active': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Stream<List<AccidentReport>> getRecentAccidents() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _db
        .collection(_col)
        .where('active', isEqualTo: true)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(AccidentReport.fromFirestore)
            .where((r) => r.time.isAfter(yesterday))
            .toList());
  }

  static Future<bool> upvote(String id) async {
    try {
      await _db.collection(_col).doc(id).update({
        'upvotes': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> expireOldReports() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    final old = await _db
        .collection(_col)
        .where('time', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    for (final doc in old.docs) {
      await doc.reference.update({'active': false});
    }
  }
}
