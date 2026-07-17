import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/shake_sos_service.dart';
import '../../widgets/bus_search_delegate.dart';
import '../../widgets/guest_badge.dart';
import '../../widgets/guest_guard.dart';
import '../journey/journey_planner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  Timer? _elapsedTimer;
  Duration _displayElapsed = Duration.zero;
  int _searchMode = 0;
  int _bottomNavIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
    _initSos();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener(_onHoldComplete);
  }

  void _onHoldComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final tripState = ref.read(tripProvider);
      final isActive = tripState.isActive;
      _holdController.reset();
      setState(() => _isHolding = false);
      HapticFeedback.heavyImpact();
      if (isActive) {
        _handleStopTrip();
      } else {
        ref.read(tripProvider.notifier).startTrip();
        context.push('/map', extra: <dynamic>[]);
      }
    }
  }

  void _startHold() {
    if (_isHolding) return;
    final tripState = ref.read(tripProvider);
    if (tripState.isLoading) return;
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_isHolding) return;
    _holdController.stop();
    _holdController.reset();
    setState(() => _isHolding = false);
  }

  Future<void> _initSos() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool('shake_sos') ?? false) {
      ShakeSosService.start(context);
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _elapsedTimer?.cancel();
        return;
      }
      final tripState = ref.read(tripProvider);
      if (tripState.isActive && tripState.currentTrip != null) {
        setState(() {
          _displayElapsed = DateTime.now().difference(tripState.currentTrip!.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final locationState = ref.watch(locationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final elapsed = tripState.isActive && tripState.currentTrip != null
        ? _displayElapsed
        : Duration.zero;

    final maxFare = 100.0;
    final progress = tripState.isActive
        ? (tripState.currentFare / maxFare).clamp(0.0, 1.0)
        : 0.0;

    final showGpsWarning = tripState.isActive &&
        locationState.accuracy > AppConstants.gpsMaxAccuracy &&
        locationState.accuracy > 0;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            if (showGpsWarning) _buildGpsWarning(locationState.accuracy),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _buildSearchCard(isDark),
                    const SizedBox(height: 20),
                    _buildDial(isDark, tripState, progress),
                    const SizedBox(height: 20),
                    _buildStatusPills(isDark, elapsed, tripState, locationState),
                    const SizedBox(height: 24),
                    _buildCtaButton(isDark, tripState),
                    const SizedBox(height: 18),
                    _buildMapPreview(isDark, tripState),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Icon(Icons.directions_bus_rounded, color: Colors.white, size: 18)),
          ),
          const SizedBox(width: 8),
          Text(
            'FareTrack',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppConstants.ink,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            ' BD',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppConstants.inkSoft,
            ),
          ),
          const SizedBox(width: 8),
          const GuestBadge(),
          const Spacer(),
          _topIcon(Icons.history_rounded, () {
            guardRestrictedAction(context, ref);
            if (!ref.read(authProvider).isGuestMode) {
              context.push('/history');
            }
          }),
          _topIcon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              () => ref.read(themeProvider.notifier).toggleTheme(),
              isDark ? AppConstants.fareAmber : AppConstants.inkSoft),
          GestureDetector(
            onTap: () => context.push('/sos-settings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.errorRed.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _topIcon(IconData icon, VoidCallback onTap, [Color? color]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18,
            color: color ?? (isDark ? Colors.white70 : AppConstants.inkSoft)),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ── GPS WARNING ──
  Widget _buildGpsWarning(double accuracy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      color: AppConstants.amberSoft,
      child: Row(
        children: [
          Icon(Icons.signal_wifi_off_rounded, size: 14, color: AppConstants.warn),
          const SizedBox(width: 6),
          Text(
            'GPS সংকেত দুর্বল: ${accuracy.toStringAsFixed(0)}মি',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: AppConstants.fontBengali,
              color: AppConstants.warn,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── MERGED SEARCH CARD ──
  Widget _buildSearchCard(bool isDark) {
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : AppConstants.cardLine,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 2),
              )],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildModeToggle(),
            const SizedBox(height: 12),
            _searchMode == 0
                ? _buildSingleSearch(isDark)
                : _buildRouteSearch(isDark),
            const SizedBox(height: 10),
            _buildRecentChips(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _searchMode = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _searchMode == 0 ? AppConstants.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _searchMode == 0
                      ? [BoxShadow(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: -3,
                        )]
                      : [],
                ),
                child: Text(
                  'খুঁজুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _searchMode == 0 ? Colors.white : AppConstants.inkSoft,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _searchMode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _searchMode == 1 ? AppConstants.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _searchMode == 1
                      ? [BoxShadow(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: -3,
                        )]
                      : [],
                ),
                child: Text(
                  'যাত্রা পরিকল্পনা',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.fontBengali,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _searchMode == 1 ? Colors.white : AppConstants.inkSoft,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSearch(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => showSearch(context: context, delegate: BusSearchDelegate()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : AppConstants.paper,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 15, color: AppConstants.inkSoft),
                  const SizedBox(width: 10),
                  Text(
                    'বাস বা লোকেশন খুঁজুন...',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppConstants.fontBengali,
                      color: AppConstants.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => showSearch(context: context, delegate: BusSearchDelegate()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(
              'খুঁজুন',
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSearch(bool isDark) {
    final inputBg = isDark ? Colors.grey[800]! : AppConstants.paper;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                const SizedBox(width: 14),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.fareAmber, shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1.5, height: 22,
                      color: AppConstants.cardLine,
                    ),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryGreen, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JourneyPlannerScreen(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'যাত্রা শুরু',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppConstants.fontBengali,
                              color: AppConstants.inkSoft,
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : AppConstants.cardLine),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JourneyPlannerScreen(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'গন্তব্য',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppConstants.fontBengali,
                              color: AppConstants.inkSoft,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppConstants.amberSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Text('⇅', style: TextStyle(color: AppConstants.fareAmber, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JourneyPlannerScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(
              'বাস খুঁজুন',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChips(bool isDark) {
    final chipBg = isDark ? Colors.grey[800]! : AppConstants.backgroundLight;
    final chipColor = isDark ? Colors.white54 : AppConstants.inkSoft;
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(chipBg, chipColor, Icons.access_time_rounded, 'মিরপুর → মতিঝিল'),
          const SizedBox(width: 6),
          _chip(chipBg, chipColor, Icons.star_rounded, 'বাড্ডা লিংক'),
          const SizedBox(width: 6),
          _chip(chipBg, chipColor, Icons.access_time_rounded, 'উত্তরা → ফার্মগেট'),
        ],
      ),
    );
  }

  Widget _chip(Color bg, Color textColor, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppConstants.cardLine.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppConstants.fontBengali,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── LIVE DIAL ──
  Widget _buildDial(bool isDark, TripState tripState, double progress) {
    final isActive = tripState.isActive;
    final isStopping = tripState.isLoading;
    final dialSize = 230.0;

    return GestureDetector(
      onLongPressStart: isStopping ? null : (_) => _startHold(),
      onLongPressEnd: isStopping ? null : (_) => _cancelHold(),
      onLongPressCancel: _isHolding ? () => _cancelHold() : null,
      child: Container(
        height: dialSize,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: AnimatedBuilder(
            animation: _isHolding ? _holdController : const AlwaysStoppedAnimation(0),
            builder: (context, _) {
              return SizedBox(
                width: dialSize,
                height: dialSize,
                child: CustomPaint(
                  painter: _DialPainter(
                    progress: progress,
                    isActive: isActive,
                    isDark: isDark,
                    holdProgress: _isHolding ? _holdController.value : 0,
                    holdColor: isActive ? AppConstants.errorRed : AppConstants.primaryGreen,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        Positioned(
                          top: 20,
                          right: 36,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppConstants.successGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.successGreen.withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppConstants.primaryAccent
                                  : AppConstants.primaryGreen,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive
                                          ? AppConstants.primaryAccent
                                          : AppConstants.primaryGreen)
                                      .withValues(alpha: _isHolding ? 0.8 : 0.5),
                                  blurRadius: _isHolding ? 26 : 18,
                                  spreadRadius: _isHolding ? -4 : -6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.directions_bus_filled_rounded,
                                size: isActive ? 26 : 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isHolding
                                ? 'ধরে রাখুন...'
                                : isActive
                                    ? 'ভাড়া: ৳${tripState.currentFare.toStringAsFixed(1)}'
                                    : 'যাত্রা শুরু করতে\nধরে রাখুন',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontFamily: AppConstants.fontBengali,
                              color: _isHolding
                                  ? (isActive ? AppConstants.errorRed : AppConstants.primaryGreen)
                                  : (isDark ? Colors.white60 : AppConstants.inkSoft),
                              fontWeight: _isHolding ? FontWeight.w700 : FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          if (isActive && !_isHolding) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDuration(elapsed: _displayElapsed)} · ${tripState.currentDistance.toStringAsFixed(1)} কিমি',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: AppConstants.fontBengali,
                                color: isDark ? Colors.white38 : AppConstants.inkSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration({required Duration elapsed}) {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60);
    final s = elapsed.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── STATUS PILLS ──
  Widget _buildStatusPills(
      bool isDark, Duration elapsed, TripState tripState, LocationState locationState) {
    final isActive = tripState.isActive;
    return Row(
      children: [
        _statusCard(
          isDark: isDark,
          ledColor: isActive ? AppConstants.successGreen : AppConstants.inkSoft,
          ledGlow: isActive,
          label: 'সময়',
          value: isActive ? _formatDuration(elapsed: elapsed) : '--:--',
          mono: true,
          highlight: isActive,
        ),
        const SizedBox(width: 10),
        _statusCard(
          isDark: isDark,
          ledColor: tripState.isJam ? AppConstants.warn : AppConstants.successGreen,
          ledGlow: isActive && !tripState.isJam,
          label: 'অবস্থা',
          value: isActive
              ? (tripState.isJam ? 'জ্যাম' : 'চলছে')
              : 'প্রস্তুত',
          mono: false,
          highlight: isActive,
        ),
        const SizedBox(width: 10),
        _statusCard(
          isDark: isDark,
          ledColor: locationState.accuracy <= AppConstants.gpsMaxAccuracy
              ? AppConstants.successGreen
              : AppConstants.warn,
          ledGlow: locationState.accuracy <= AppConstants.gpsMaxAccuracy,
          label: 'GPS',
          value: locationState.accuracy > 0
              ? '${locationState.accuracy.toStringAsFixed(0)}মি'
              : '--',
          mono: true,
          highlight: false,
        ),
      ],
    );
  }

  Widget _statusCard({
    required bool isDark,
    required Color ledColor,
    required bool ledGlow,
    required String label,
    required String value,
    required bool mono,
    required bool highlight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark ? Colors.white12 : AppConstants.cardLine,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ledColor,
                    shape: BoxShape.circle,
                    boxShadow: ledGlow
                        ? [BoxShadow(color: ledColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                        : [],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontFamily: AppConstants.fontBengali,
                    color: isDark ? Colors.white54 : AppConstants.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                fontFamily: mono ? AppConstants.fontEnglish : AppConstants.fontBengali,
                color: highlight
                    ? (isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen)
                    : (isDark ? Colors.white70 : AppConstants.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CTA BUTTON with breathe animation ──
  Widget _buildCtaButton(bool isDark, TripState tripState) {
    final isActive = tripState.isActive;
    final isStopping = tripState.isLoading;

    return GestureDetector(
      onLongPressStart: isStopping ? null : (_) => _startHold(),
      onLongPressEnd: isStopping ? null : (_) => _cancelHold(),
      onLongPressCancel: isStopping ? null : () => _cancelHold(),
      onTap: isStopping
          ? null
          : () {
              HapticFeedback.mediumImpact();
              if (isActive) {
                _handleStopTrip();
              } else {
                ref.read(tripProvider.notifier).startTrip();
                context.push('/map', extra: <dynamic>[]);
              }
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? [AppConstants.errorRed, AppConstants.errorRed.withValues(alpha: 0.85)]
                : [AppConstants.primaryGreen, AppConstants.pineDeep],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: (isActive ? AppConstants.errorRed : AppConstants.primaryGreen)
                  .withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _isHolding ? _holdController : _pulseController,
              builder: (context, _) {
                final scale = _isHolding
                    ? 0.85 + _holdController.value * 0.3
                    : 0.9 + _pulseController.value * 0.2;
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              isStopping
                  ? 'থামানো হচ্ছে...'
                  : _isHolding
                      ? (isActive ? 'যাত্রা শেষ করুন (${(_holdController.value * 3).toStringAsFixed(0)}s)' : 'যাত্রা শুরু করুন (${(_holdController.value * 3).toStringAsFixed(0)}s)')
                      : (isActive ? 'যাত্রা শেষ করুন' : 'যাত্রা শুরু করুন'),
              style: const TextStyle(
                fontFamily: AppConstants.fontBengali,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStopTrip() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.endTripConfirm,
          style: const TextStyle(fontFamily: AppConstants.fontBengali),
        ),
        content: Text(
          AppStrings.endTripConfirmMsg,
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('না',
                style: TextStyle(fontFamily: AppConstants.fontBengali, color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.endTrip,
              style: TextStyle(
                fontFamily: AppConstants.fontBengali,
                color: isDark ? AppConstants.fareAmber : AppConstants.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    final trip = await ref.read(tripProvider.notifier).endTrip();
    if (trip != null && context.mounted) {
      context.push('/receipt', extra: trip);
    }
  }

  // ── MAP PREVIEW ──
  Widget _buildMapPreview(bool isDark, TripState tripState) {
    final hasRoute = tripState.isActive && tripState.routePoints.isNotEmpty;
    return GestureDetector(
      onTap: () => context.push('/map', extra: tripState.routePoints),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.grey[900]! : AppConstants.paper,
          border: Border.all(
            color: isDark ? Colors.white12 : AppConstants.cardLine,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Abstract map path
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPathPainter(isDark: isDark, hasRoute: hasRoute),
              ),
            ),
            // Caption overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Colors.grey[900]!.withValues(alpha: 0)
                          : AppConstants.paper.withValues(alpha: 0),
                      isDark ? Colors.grey[900]! : AppConstants.paper,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map_rounded, size: 13, color: isDark ? Colors.white70 : AppConstants.ink),
                        const SizedBox(width: 8),
                        Text(
                          hasRoute
                              ? '${tripState.currentDistance.toStringAsFixed(1)} কিমি · ${tripState.routePoints.length} পয়েন্ট'
                              : 'মানচিত্র দেখুন',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppConstants.fontBengali,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppConstants.ink,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? AppConstants.pineGlow : AppConstants.pineDeep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM NAV ──
  Widget _buildBottomNav(bool isDark) {
    final items = [
      (Icons.home_rounded, 'হোম', 0),
      (Icons.history_rounded, 'ইতিহাস', 1),
      (Icons.directions_bus_rounded, 'যাত্রা', 2),
      (Icons.map_rounded, 'মানচিত্র', 3),
      (Icons.person_rounded, 'প্রোফাইল', 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : AppConstants.cardLine),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = item.$3 == _bottomNavIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _bottomNavIndex = item.$3);
                  switch (item.$3) {
                    case 0:
                    case 2:
                      break;
                    case 1:
                      guardRestrictedAction(context, ref);
                      if (!ref.read(authProvider).isGuestMode) {
                        context.push('/history');
                      }
                      break;
                    case 3:
                      context.push('/map', extra: <dynamic>[]);
                      break;
                    case 4:
                      guardRestrictedAction(context, ref);
                      if (!ref.read(authProvider).isGuestMode) {
                        context.push('/profile');
                      }
                      break;
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.$3 == 2)
                      Container(
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                              blurRadius: 18,
                              spreadRadius: -6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(item.$1, size: 20, color: Colors.white),
                        ),
                      )
                    else ...[
                      Icon(item.$1, size: 19,
                        color: isActive
                            ? (isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen)
                            : (isDark ? Colors.white38 : AppConstants.inkSoft),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontFamily: AppConstants.fontBengali,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? (isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen)
                              : (isDark ? Colors.white38 : AppConstants.inkSoft),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── DIAL CUSTOM PAINTER ──
class _DialPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final bool isDark;
  final double holdProgress;
  final Color holdColor;

  _DialPainter({
    required this.progress,
    required this.isActive,
    required this.isDark,
    this.holdProgress = 0,
    this.holdColor = AppConstants.primaryGreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.25),
        colors: isDark
            ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A), const Color(0xFF111111)]
            : [const Color(0xFFFFFFFF), const Color(0xFFEEF1E9), const Color(0xFFE4E7DD)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Inner circle border (dashed-style via two circles)
    final dashPaint = Paint()
      ..color = isDark ? const Color(0xFF333333) : const Color(0xFFD7DCCF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, dashPaint);

    // Progress arc
    if (isActive && progress > 0) {
      final arcPaint = Paint()
        ..color = AppConstants.primaryAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    } else {
      // Idle ring hint
      final idleRingPaint = Paint()
        ..color = AppConstants.pineGlow.withValues(alpha: isDark ? 0.2 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius - 6, idleRingPaint);
    }

    // Subtle shadow ring
    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 3, shadowPaint);

    if (holdProgress > 0) {
      final holdPaint = Paint()
        ..color = holdColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 2),
        -math.pi / 2,
        2 * math.pi * holdProgress,
        false,
        holdPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isActive != isActive ||
      oldDelegate.isDark != isDark ||
      oldDelegate.holdProgress != holdProgress;
}

// ── MAP PATH CUSTOM PAINTER ──
class _MapPathPainter extends CustomPainter {
  final bool isDark;
  final bool hasRoute;

  _MapPathPainter({required this.isDark, required this.hasRoute});

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = isDark
          ? AppConstants.pineGlow.withValues(alpha: 0.25)
          : AppConstants.primaryGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.15, size.height * 0.5,
        size.width * 0.25, size.height * 0.85,
        size.width * 0.4, size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.55, size.height * 0.3,
        size.width * 0.65, size.height * 0.7,
        size.width * 0.8, size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.9, size.height * 0.25,
        size.width * 0.95, size.height * 0.35,
        size.width, size.height * 0.2,
      );

    canvas.drawPath(path, pathPaint);

    // Start dot
    canvas.drawCircle(
      Offset(0, size.height * 0.65),
      4,
      Paint()..color = AppConstants.fareAmber,
    );
    // Waypoint dot
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.55),
      3,
      Paint()..color = AppConstants.primaryGreen,
    );
    // End dot
    canvas.drawCircle(
      Offset(size.width, size.height * 0.2),
      4.5,
      Paint()..color = AppConstants.primaryGreen,
    );

    // Grid dots
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : AppConstants.primaryGreen.withValues(alpha: 0.06);
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.hasRoute != hasRoute;
}
