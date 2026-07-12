import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bus_database.dart';
import '../data/bus_route_data.dart';
import '../data/ddr_route_data.dart';
import '../services/bus_fare_calculator.dart';
import '../services/route_finder_service.dart';
import '../core/constants/app_constants.dart';

class ChatResult {
  final String text;
  final bool isError;
  const ChatResult(this.text, {this.isError = false});
}

class _LocalFaq {
  static final Map<String, String> _stopAliases = {
    'মিরপুর': 'মিরপুর-১০',
    'মিরপুর-১০': 'মিরপুর-১০',
    'মিরপুর ১০': 'মিরপুর-১০',
    'মিরপুর 1': 'মিরপুর-১০',
    'মিরপুর-১': 'মিরপুর-১',
    'মিরপুর ১': 'মিরপুর-১',
    'মিরপুর-২': 'মিরপুর-২',
    'মিরপুর ২': 'মিরপুর-২',
    'মিরপুর 2': 'মিরপুর-২',
    'মিরপুর-১২': 'মিরপুর-১২',
    'মিরপুর ১২': 'মিরপুর-১২',
    'মতিঝিল': 'মতিঝিল',
    'গুলশান': 'গুলশান',
    'গুলশান ১': 'গুলশান-১',
    'গুলশান 1': 'গুলশান-১',
    'গুলশান ২': 'গুলশান-২',
    'গুলশান 2': 'গুলশান-২',
    'গুলিস্তান': 'গুলিস্তান',
    'ফার্মগেট': 'ফার্মগেট',
    'ফার্মগেইট': 'ফার্মগেট',
    'শাহবাগ': 'শাহবাগ',
    'বনানী': 'বনানী',
    'উত্তরা': 'উত্তরা',
    'এয়ারপোর্ট': 'এয়ারপোর্ট',
    'বিমানবন্দর': 'এয়ারপোর্ট',
    'টেকনিক্যাল': 'টেকনিক্যাল',
    'শ্যামলী': 'শ্যামলী',
    'কাল্যাণপুর': 'কাল্যাণপুর',
    'কালিয়ানপুর': 'কাল্যাণপুর',
    'গাবতলী': 'গাবতলী',
    'গাবতলি': 'গাবতলী',
    'আসলামগেট': 'আসাদগেট',
    'আসাদ গেট': 'আসাদগেট',
    'আসাদগেট': 'আসাদগেট',
    'সায়দাবাদ': 'সায়দাবাদ',
    'যাত্রাবাড়ী': 'যাত্রাবাড়ী',
    'কমলাপুর': 'কমলাপুর',
    'মগবাজার': 'মগবাজার',
    'মৌচাক': 'মৌচাক',
    'মালিবাগ': 'মালিবাগ',
    'রামপুরা': 'রামপুরা',
    'বাড্ডা': 'বাড্ডা',
    'বাসুন্ধরা': 'বাসুন্ধরা',
    'কুড়িল': 'কুড়িল',
    'খিলক্ষেত': 'খিলক্ষেত',
    'নতুন বাজার': 'নতুন বাজার',
    'নতুনবাজার': 'নতুন বাজার',
    'নটন বাজার': 'নতুন বাজার',
    'সাভার': 'সাভার',
    'টঙ্গী': 'টঙ্গী',
    'টঙ্গি': 'টঙ্গী',
    'গাজীপুর': 'গাজীপুর',
    'গাজিপুর': 'গাজীপুর',
    'নারায়ণগঞ্জ': 'নারায়ণগঞ্জ',
    'সিদ্ধিরগঞ্জ': 'সিদ্ধিরগঞ্জ',
    'মানিকগঞ্জ': 'মানিকগঞ্জ',
    'কেরানীগঞ্জ': 'কেরানীগঞ্জ',
    'কেরানিগঞ্জ': 'কেরানীগঞ্জ',
    'পল্টন': 'পল্টন',
    'কাকরাইল': 'কাকরাইল',
    'শান্তিনগর': 'শান্তিনগর',
    'প্রেসক্লাব': 'প্রেসক্লাব',
    'পress club': 'প্রেসক্লাব',
    'মোহাম্মদপুর': 'মোহাম্মদপুর',
    'মহম্মদপুর': 'মোহাম্মদপুর',
    'ধানমন্ডি': 'ধানমন্ডি',
    'ধানমণ্ডি': 'ধানমন্ডি',
    'ধানমন্ডি ৩২': 'ধানমন্ডি ৩২',
    'ধানমন্ডি 27': 'ধানমন্ডি ২৭',
    'ধানমন্ডি ২৭': 'ধানমন্ডি ২৭',
    'নিউমার্কেট': 'নিউমার্কেট',
    'নিউ মার্কেট': 'নিউমার্কেট',
    'কলেজ গেট': 'কলেজ গেট',
    'কলেজগেট': 'কলেজ গেট',
    'সদরঘাট': 'সদরঘাট',
    'বাবুবাজার': 'বাবুবাজার',
    'বাবু বাজার': 'বাবুবাজার',
    'চকবাজার': 'চকবাজার',
    'মিটফোর্ড': 'মিটফোর্ড',
    'হাজারীবাগ': 'হাজারীবাগ',
    'হাজারিবাগ': 'হাজারীবাগ',
    'ডেমরা': 'ডেমরা',
    'কামরাঙ্গীরচর': 'কামরাঙ্গীরচর',
    'কামরাঙ্গিরচর': 'কামরাঙ্গীরচর',
    'পোস্তগোলা': 'পোস্তগোলা',
  };

  static String _normalize(String s) {
    final t = s.trim().replaceAll(RegExp(r'[?.!,]'), '');
    if (_stopAliases.containsKey(t)) return _stopAliases[t]!;
    return t;
  }

  static String? tryAnswer(String message) {
    final q = message.replaceAll(RegExp(r'[?.!,]'), '').trim();

    if (_q(q, 'হেল্পলাইন') || _q(q, 'অভিযোগ') || _q(q, '১৬৮৬৯') || _q(q, 'সাহায্য')) {
      return 'অতিরিক্ত ভাড়া নিলে বিআরটিএ হেল্পলাইন **১৬৮৬৯**-এ ফোন করুন। রাত ১০টার পর অতিরিক্ত ভাড়া নেওয়া বেআইনি।';
    }

    if (_q(q, 'রাত') && (_q(q, 'ভাড়া') || _q(q, 'বাস'))) {
      return 'রাত ১০টার পর বাস ভাড়া বেশি নেওয়া বেআইনি। বিআরটিএ হেল্পলাইন **১৬৮৬৯**-এ রিপোর্ট করুন।';
    }

    if (_q(q, 'এসি') && (_q(q, 'ভাড়া') || _q(q, 'বাস') || _q(q, 'কত'))) {
      return 'এসি বাসের ভাড়া নন-এসি বাসের **দ্বিগুণ**। যেমন নন-এসি ২০ টাকা হলে এসি হবে ৪০ টাকা।';
    }

    if (_q(q, 'ন্যূনতম') || _q(q, 'নূন্যতম') || _q(q, 'সর্বনিম্ন') || _q(q, 'কম ভাড়া')) {
      return 'বিআরটিএ নিয়ম অনুযায়ী ন্যূনতম বাস ভাড়া **${AppConstants.minimumFare.toStringAsFixed(0)} টাকা** এবং প্রতি কিমি **${AppConstants.fareRatePerKm} টাকা**।';
    }

    if (_q(q, 'সর্বোচ্চ') && (_q(q, 'ভাড়া') || _q(q, 'কত'))) {
      return 'বিআরটিএ নিয়ম অনুযায়ী সর্বোচ্চ ভাড়া **${AppConstants.fareRatePerKm} টাকা/কিমি** এবং ন্যূনতম **${AppConstants.minimumFare.toStringAsFixed(0)} টাকা**।';
    }

    if (_q(q, 'বিআরটিএ') || _q(q, 'ব্রট') || _q(q, 'নিয়ম')) {
      return 'বিআরটিএ নিয়ম:\n• সর্বোচ্চ ভাড়া ${AppConstants.fareRatePerKm} টাকা/কিমি\n• ন্যূনতম ভাড়া ${AppConstants.minimumFare.toStringAsFixed(0)} টাকা\n• এসি ভাড়া দ্বিগুণ\n• রাত ১০টার পর অতিরিক্ত ভাড়া বেআইনি\n• হেল্পলাইন: ১৬৮৬৯';
    }

    if (_q(q, 'মোট বাস') || _q(q, 'কতটি বাস') || _q(q, 'সব বাস') || _q(q, 'মোট রুট') || _q(q, 'কতগুলো বাস')) {
      final busCount = BusDatabase.allBuses.length;
      final routeCount = BusRouteData.allRoutes.length;
      final ddrCount = DdrRouteData.allRoutes.length;
      return 'আমাদের ডাটাবেসে **$busCount**টি বাস, **$routeCount**টি সিটি রুট এবং **$ddrCount**টি আন্তঃজেলা (ডিডিআর) রুট রয়েছে।';
    }

    final routeResult = _tryRouteSearch(q);
    if (routeResult != null) return routeResult;

    final fareResult = _tryFareCalculation(q);
    if (fareResult != null) return fareResult;

    final searchResult = _tryGenericSearch(q);
    if (searchResult != null) return searchResult;

    return null;
  }

  static bool _q(String q, String keyword) => q.contains(keyword);

  static String? _tryRouteSearch(String message) {
    final routeMatch = RegExp(
      r'([\w\u0980-\u09FF\s.-]+?)\s*(থেকে|হতে|->|→)\s*([\w\u0980-\u09FF\s.-]+?)(?:\s*[?।!,]?\s*$|\s+(ভাড়া|বাস|রুট|কত|টাকা))',
      caseSensitive: false,
    ).firstMatch(message);
    if (routeMatch == null) return null;

    final fromRaw = routeMatch.group(1)!.trim().replaceAll(RegExp(r'[?.!,]$'), '');
    final toRaw = routeMatch.group(3)!.trim().replaceAll(RegExp(r'[?.!,]$'), '');
    final from = _normalize(fromRaw);
    final to = _normalize(toRaw);

    final parts = <String>[];

    for (final result in BusFareCalculator.findFaresBetweenStops(fromStop: from, toStop: to)) {
      parts.add(
        '**${result.route.nameBn}** (${result.route.routeNo})\n'
        '• ${result.fromStop.name} → ${result.toStop.name}: **${result.formattedFare}**\n'
        '• দূরত্ব: ${result.formattedDistance}',
      );
    }

    final suggestions = RouteFinderService.findRoutes(fromRaw, toRaw);
    for (final s in suggestions) {
      if (s.isDirect) {
        parts.add(
          '**${s.bus.nameBn}**\n'
          '• ${s.bus.stops[s.startIndex]} → ${s.bus.stops[s.endIndex]} (${s.stopCount} স্টপ)\n'
          '• সরাসরি বাস',
        );
      } else {
        parts.add(
          '**${s.bus.nameBn}** → **${s.connectingBus}**\n'
          '• ${s.midStop}-এ নামবেন, তারপর পরবর্তী বাস ধরবেন',
        );
      }
    }

    if (parts.isEmpty) {
      final estimated = _estimateFare(from, to);
      if (estimated != null) {
        parts.add(estimated);
      }
    }

    if (parts.isEmpty) {
      final foundFrom = BusDatabase.searchByName(fromRaw);
      final foundTo = BusDatabase.searchByName(toRaw);
      if (foundFrom.isNotEmpty || foundTo.isNotEmpty) {
        return '"$fromRaw" → "$toRaw" এই রুটে সরাসরি কোনো বাস খুঁজে পাইনি। তবে নিচের বাসগুলো এই এলাকায় চলে:\n'
            '${foundFrom.take(3).map((b) => '• ${b.nameBn}').join('\n')}'
            '${foundFrom.length > 3 ? ' (+আরও ${foundFrom.length - 3})' : ''}'
            '${foundTo.isNotEmpty ? '\n\n"$toRaw"-এ যাওয়া বাস:\n${foundTo.take(3).map((b) => '• ${b.nameBn}').join('\n')}' : ''}';
      }
      return null;
    }

    return parts.take(3).join('\n\n');
  }

  static String? _estimateFare(String from, String to) {
    double? bestKm;
    String? via;

    for (final route in BusRouteData.allRoutes) {
      int? fi;
      int? ti;
      for (int i = 0; i < route.stops.length; i++) {
        if (route.stops[i].name.contains(from)) fi = i;
        if (route.stops[i].name.contains(to)) ti = i;
      }
      if (fi != null && ti != null) {
        final d = route.getDistanceBetween(fi, ti);
        if (d != null && (bestKm == null || d < bestKm)) {
          bestKm = d;
          via = route.nameBn;
        }
      }
    }

    if (bestKm == null) return null;

    final fare = BusFareCalculator.calculateFareByDistance(bestKm);
    final acFare = fare * 2;
    return '**$from → $to** (আনুমানিক)\n'
        '• দূরত্ব: ~${bestKm.toStringAsFixed(1)} কিমি\n'
        '• ভাড়া (নন-এসি): **~৳${fare.toStringAsFixed(0)}**\n'
        '• ভাড়া (এসি): **~৳${acFare.toStringAsFixed(0)}**\n'
        '${via != null ? '• রুট: $via' : ''}\n'
        '_*এটি একটি আনুমানিক ভাড়া। সঠিক ভাড়ার জন্য বাস কাউন্টারে যোগাযোগ করুন।_';
  }

  static String? _tryFareCalculation(String q) {
    final kmMatch = RegExp(r'(\d+(?:\.\d+)?)\s*কিমি', caseSensitive: false).firstMatch(q);
    if (kmMatch != null) {
      final km = double.parse(kmMatch.group(1)!);
      final fare = BusFareCalculator.calculateFareByDistance(km);
      final acFare = fare * 2;
      return '~$km কিমি দূরত্বের জন্য:\n• নন-এসি ভাড়া: **৳${fare.toStringAsFixed(0)}**\n• এসি ভাড়া: **৳${acFare.toStringAsFixed(0)}**\n\n*বিআরটিএ নিয়ম: ${AppConstants.fareRatePerKm} টাকা/কিমি, ন্যূনতম ${AppConstants.minimumFare.toStringAsFixed(0)} টাকা*';
    }
    return null;
  }

  static String? _tryGenericSearch(String q) {
    if (q.length < 2) return null;

    final buses = BusDatabase.searchByName(q);
    if (buses.isNotEmpty) {
      final names = buses.take(10).map((b) => '• **${b.nameBn}** (${b.name}) — ${b.type}').join('\n');
      final more = buses.length > 10 ? '\n\nএবং আরও ${buses.length - 10}টি বাস...' : '';
      return '"$q" এর সাথে যুক্ত বাস:\n$names$more';
    }

    final routes = BusRouteData.search(q);
    if (routes.isNotEmpty) {
      final names = routes.take(5).map((r) => '• **${r.nameBn}** (${r.routeNo}) — ${r.totalDistanceKm.toStringAsFixed(0)} কিমি').join('\n');
      return '"$q" এর সাথে যুক্ত রুট:\n$names';
    }

    return null;
  }

  static String searchContext(String message) {
    final q = message.replaceAll(RegExp(r'[?.!,]'), '').trim();
    final words = q.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    final foundRoutes = <String>{};
    final foundBuses = <String>{};

    for (final w in words) {
      for (final r in BusRouteData.search(w)) {
        foundRoutes.add('${r.nameBn} (${r.routeNo}): ${r.totalDistanceKm.toStringAsFixed(0)} কিমি');
      }
      for (final b in BusDatabase.searchByName(w)) {
        foundBuses.add('${b.nameBn}: ${b.stops.length} স্টপ');
      }
    }

    final buf = StringBuffer();
    if (foundRoutes.isNotEmpty) {
      buf.writeln('মিলে যাওয়া রুট:');
      for (final r in foundRoutes.take(5)) buf.writeln('• $r');
    }
    if (foundBuses.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln('');
      buf.writeln('মিলে যাওয়া বাস:');
      for (final b in foundBuses.take(5)) buf.writeln('• $b');
    }
    return buf.toString();
  }
}

class GeminiService {
  static String _apiKey = '';
  static GenerativeModel? _model;
  static const String _prefsKey = 'gemini_api_key';
  static const Duration _timeout = Duration(seconds: 15);

  static const String _defaultApiKey = '';

  static String _buildSystemPrompt() {
    final buf = StringBuffer();

    buf.writeln('You are Trakky (ট্র্যাকি), a bus fare assistant for FareTrack BD app.');
    buf.writeln('Always respond in Bangla (বাংলা). Be friendly, concise, and accurate.');
    buf.writeln('');
    buf.writeln('RULES:');
    buf.writeln('1. Answer ONLY about Dhaka bus routes, fares, and transport.');
    buf.writeln('2. BRTA max fare: ${AppConstants.fareRatePerKm} TK/km, minimum ${AppConstants.minimumFare.toStringAsFixed(0)} TK.');
    buf.writeln('3. AC bus fare is double of non-AC.');
    buf.writeln('4. After 10PM, extra charges are illegal. Report to BRTA helpline 16869.');
    buf.writeln('5. Keep answers within 2-3 lines. Short and to the point.');
    buf.writeln('6. If asked something else, say: "আমি শুধু বাসের ভাড়া ও রুট নিয়ে সাহায্য করতে পারি।"');
    buf.writeln('7. When you don\'t have exact fare data, estimate using: distance × ${AppConstants.fareRatePerKm} TK (min ${AppConstants.minimumFare.toStringAsFixed(0)} TK) and mark as approximate.');
    buf.writeln('8. For AC buses, multiply non-AC fare by 2.');
    buf.writeln('');

    // BusDatabase summary
    final allBuses = BusDatabase.allBuses;
    final typeCounts = <String, int>{};
    for (final b in allBuses) {
      final t = b.type.isEmpty ? 'Unknown' : b.type;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    buf.writeln('=== BUS COMPANIES (${allBuses.length} total) ===');
    for (final e in typeCounts.entries) {
      buf.writeln('- ${e.key}: ${e.value}');
    }
    buf.writeln('');

    // City routes compact table
    final allRoutes = BusRouteData.allRoutes;
    buf.writeln('=== CITY BUS ROUTES (${allRoutes.length} total) ===');
    buf.writeln('Format: RouteNo | BanglaName | Distance | StopCount | FareRange');
    for (final r in allRoutes) {
      final from = r.stops.first.name;
      final to = r.stops.last.name;
      final fareMin = r.fareData.isNotEmpty && r.fareData.last.isNotEmpty
          ? r.fareData.last.first.toStringAsFixed(0)
          : '?';
      final fareMax = r.fareData.isNotEmpty && r.fareData.last.isNotEmpty
          ? r.fareData.last.last.toStringAsFixed(0)
          : '?';
      buf.writeln('${r.routeNo} | ${r.nameBn} | ${r.totalDistanceKm.toStringAsFixed(0)}km | ${r.stops.length} stops | $from→$to | $fareMin~$fareMax TK');
    }
    buf.writeln('');

    // DDR routes compact table
    final ddrRoutes = DdrRouteData.allRoutes;
    buf.writeln('=== DDR (INTER-DISTRICT) ROUTES (${ddrRoutes.length} total) ===');
    buf.writeln('Format: RouteNo | Name | Distance | Fare/km | Fare51Seat | Fare80Seat');
    for (final r in ddrRoutes) {
      buf.writeln('${r.routeNo} | ${r.nameBn} | ${r.totalDistanceKm.toStringAsFixed(0)}km | ${r.farePerKm} TK/km | ${r.totalFare51Seat.toStringAsFixed(0)} TK (51 seat) | ${r.totalFare80Seat.toStringAsFixed(0)} TK (80 seat)');
    }

    return buf.toString();
  }

  static String get apiKey => _apiKey;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_prefsKey) ?? '';
    final envKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final key = savedKey.isNotEmpty
        ? savedKey
        : envKey.isNotEmpty
            ? envKey
            : _defaultApiKey;
    await setApiKey(key);
  }

  static Future<void> setApiKey(String key) async {
    _apiKey = key;
    if (key.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, key);
      final prompt = _buildSystemPrompt();
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: key,
        systemInstruction: Content.system(prompt),
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 300,
          topP: 0.85,
        ),
      );
    } else {
      _model = null;
    }
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static Future<void> clearApiKey() async {
    _apiKey = '';
    _model = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<ChatResult> chat({
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    if (_apiKey.isEmpty || _model == null) {
      final local = _LocalFaq.tryAnswer(userMessage);
      if (local != null) return ChatResult(local);
      return ChatResult('দুঃখিত, API key সেট করা হয়নি। প্রোফাইল > AI API Key থেকে key বসান।', isError: true);
    }

    try {
      final localResult = _LocalFaq.tryAnswer(userMessage);
      final dbContext = _LocalFaq.searchContext(userMessage);

      final List<Content> contents = [];

      if (dbContext.isNotEmpty) {
        contents.add(Content.text(
          'Database context for this query:\n$dbContext',
        ));
      }

      if (localResult != null) {
        contents.add(Content.text(
          'Our database has this exact answer. Read it carefully and use it to respond naturally in Bangla:\n$localResult',
        ));
      }

      for (final msg in history) {
        final text = msg['text'] ?? '';
        if (text.isEmpty) continue;
        if (msg['role'] == 'user') {
          contents.add(Content.text(text));
        } else {
          contents.add(Content.model([TextPart(text)]));
        }
      }

      contents.add(Content.text(userMessage));

      final response = await _model!.generateContent(contents).timeout(_timeout);
      final text = response.text;
      if (text == null || text.isEmpty) {
        return ChatResult(localResult ?? 'কোনো উত্তর পাওয়া যায়নি।');
      }
      return ChatResult(text);
    } on TimeoutException {
      debugPrint('Gemini Timeout');
      return ChatResult('অনুরোধের সময় শেষ (১৫ সেকেন্ড)। আবার চেষ্টা করুন।', isError: true);
    } on InvalidApiKey catch (e) {
      debugPrint('Gemini InvalidApiKey: ${e.message}');
      _model = null;
      _apiKey = '';
      return ChatResult('API key ভুল বা নিষ্ক্রিয়। প্রোফাইল > AI API Key থেকে নতুন key বসান।', isError: true);
    } on UnsupportedUserLocation {
      debugPrint('Gemini UnsupportedUserLocation');
      return ChatResult('আপনার লোকেশন থেকে Gemini API ব্যবহার করা যায় না। VPN চালু করে দেখুন।', isError: true);
    } on ServerException catch (e) {
      debugPrint('Gemini ServerException: ${e.message}');
      return ChatResult('Gemini সার্ভার সমস্যা:\n${e.message}', isError: true);
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini GenerativeAIException: ${e.message}');
      return ChatResult('Gemini API ত্রুটি:\n${e.message}', isError: true);
    } catch (e) {
      debugPrint('Gemini unknown error: $e');
      return ChatResult('দুঃখিত, কিছু সমস্যা হয়েছে।\n$e', isError: true);
    }
  }
}
