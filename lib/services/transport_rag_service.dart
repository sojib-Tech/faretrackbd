import '../data/bus_route_data.dart';
import '../models/bus_route.dart';

class TransportRagService {
  static final List<String> _dhakaAreas = [
    'মিরপুর', 'মিরপুর-১', 'মিরপুর-২', 'মিরপুর-৬', 'মিরপুর-১০',
    'মিরপুর-১১', 'মিরপুর-১২', 'মিরপুর-১৪', 'মিরপুর রূপনগর',
    'ফার্মগেট', 'শাহবাগ', 'মতিঝিল', 'গুলিস্তান', 'পল্টন',
    'শ্যামলী', 'আসাদগেট', 'কল্যাণপুর', 'টেকনিক্যাল', 'গাবতলী',
    'বসিলা', 'বছিলা', 'মোহাম্মদপুর', 'আগারগাঁও', 'শেওড়াপাড়া',
    'কাজীপাড়া', 'মহাখালী', 'বনানী', 'গুলশান', 'গুলশান-১',
    'এয়ারপোর্ট', 'উত্তরা', 'আব্দুল্লাহপুর', 'ধউর', 'কামারপাড়া',
    'কালশী', 'পুরবী', 'ইসিবি চতুর', 'কুড়িল', 'নতুন বাজার',
    'বাড্ডা', 'রামপুরা', 'মালিবাগ', 'মগবাজার', 'কাকলী',
    'বাংলামটর', 'প্রেসক্লাব', 'সায়েদাবাদ', 'যাত্রাবাড়ী',
    'কমলাপুর', 'শনির আখড়া', 'সাইনবোর্ড', 'পোস্তগোলা',
    'সাভার', 'নবীনগর', 'ইপিজেড', 'নন্দনপার্ক', 'হেমায়েতপুর',
    'আমিন বাজার', 'নারায়ণগঞ্জ', 'নারায়নগঞ্জ', 'ডেমরা',
    'টঙ্গী', 'বিমানবন্দর', 'চিড়িয়াখানা', 'সনি সিনেমা হল',
    'বিজয় স্মরণী', 'নিউ মার্কেট', 'আজিমপুর', 'কলাবাগান',
    'সাইন্সল্যাব', 'সাইন্স ল্যাব', 'খিলগাও', 'টিটিপাড়া',
    'মৌচাক', 'কাকরাইল', 'বাবু বাজার', 'সদরঘাট',
    'চানখারপুল', 'বকশিবাজার', 'ঢাকেশ্বরী',
    'মানিকমিয়া', 'খামারবাড়ি',
    'রাসেল স্কয়ার', 'নীলক্ষেত', 'পল্লবী', 'কাফরুল',
    'বিশ্বরোড', 'কাঁচপুর', 'মাওয়া',
  ];

  static String findContext(String userMessage) {
    final query = userMessage.toLowerCase();
    final matchedAreas = <String>{};
    final matchedRoutes = <BusRoute>[];

    for (final area in _dhakaAreas) {
      if (query.contains(area.toLowerCase())) {
        matchedAreas.add(area);
      }
    }

    for (final route in BusRouteData.allRoutes) {
      final routeText =
          '${route.nameBn} ${route.routeNo} ${route.stops.map((s) => s.name).join(' ')}'
              .toLowerCase();
      if (matchedAreas.any((a) => routeText.contains(a.toLowerCase()))) {
        matchedRoutes.add(route);
        if (matchedRoutes.length >= 5) break;
      }
    }

    if (matchedRoutes.isEmpty) return '';

    final buf = StringBuffer('\n[রুট] প্রাসঙ্গিক রুট তথ্য:\n');
    for (final route in matchedRoutes) {
      buf.writeln('► ${route.routeNo} | ${route.nameBn}');
      buf.writeln('  দূরত্ব: ${route.totalDistanceKm} কিমি | থামে: ${route.stopCount}টি');
      final stops = route.stops.take(6).map((s) => s.name).join(' → ');
      buf.writeln('  $stops${route.stops.length > 6 ? ' → ...' : ''}');

      if (matchedAreas.length >= 2) {
        final areaList = matchedAreas.toList();
        final fromStop = route.stops.indexWhere(
            (s) => s.name.toLowerCase().contains(areaList[0].toLowerCase()));
        final toStop = route.stops.indexWhere(
            (s) => s.name.toLowerCase().contains(areaList[1].toLowerCase()));
        if (fromStop >= 0 && toStop >= 0 && fromStop != toStop) {
          final fare = route.getFare(fromStop, toStop);
          final dist = route.getDistanceBetween(fromStop, toStop);
          if (fare != null) {
            buf.writeln('  [ভাড়া] ${areaList[0]}→${areaList[1]}: ${fare.toInt()} টাকা${dist != null ? ' (${dist.toStringAsFixed(1)} কিমি)' : ''}');
          }
        }
      }
    }
    buf.writeln('');
    return buf.toString();
  }

  static String findFareFromQuery(String query) {
    final parts = query.split(RegExp(r'[\s,،>→>=: ]+')).where((s) => s.trim().isNotEmpty).toList();
    for (var i = 0; i < parts.length; i++) {
      for (var j = i + 1; j < parts.length; j++) {
        final a = parts[i].trim();
        final b = parts[j].trim();
        if (_dhakaAreas.any((area) => area.toLowerCase() == a.toLowerCase()) &&
            _dhakaAreas.any((area) => area.toLowerCase() == b.toLowerCase())) {
          final result = findFareBetween(a, b);
          if (result.isNotEmpty) return result;
        }
      }
    }
    return '';
  }

  static String findFareBetween(String from, String to) {
    final f = from.toLowerCase();
    final t = to.toLowerCase();
    final results = <String>[];

    for (final route in BusRouteData.allRoutes) {
      final stopNames = route.stops.map((s) => s.name.toLowerCase()).toList();
      final fromIdx = stopNames.indexWhere((s) => s.contains(f));
      final toIdx = stopNames.indexWhere((s) => s.contains(t));

      if (fromIdx >= 0 && toIdx >= 0 && fromIdx != toIdx) {
        final fare = route.getFare(fromIdx, toIdx);
        final dist = route.getDistanceBetween(fromIdx, toIdx);
        if (fare != null) {
          results.add(
            '► ${route.routeNo} ${route.nameBn}: $from→$to = ${fare.toInt()} টাকা${dist != null ? ' (${dist.toStringAsFixed(1)} কিমি)' : ''}',
          );
        }
        if (results.length >= 3) break;
      }
    }

    if (results.isEmpty) return '';
    return '[ভাড়া] **ভাড়ার তথ্য:**\n${results.join('\n')}\n';
  }
}
