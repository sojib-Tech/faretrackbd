import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/storage_provider.dart';
import 'models/gps_point.dart';
import 'models/trip_model.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/shake_sos_service.dart';
import 'services/gemini_service.dart';
import 'core/utils/root_navigator.dart';
import 'data/bus_database.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/full_map_screen.dart';
import 'features/receipt/receipt_sheet.dart';
import 'features/history/history_screen.dart';
import 'features/history/history_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/routes/route_list_screen.dart';
import 'features/routes/fare_calculator_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/accident_map_screen.dart';
import 'screens/sos_settings_screen.dart';
import 'screens/email_screen.dart';
import 'features/journey/journey_planner_screen.dart';

GoRouter _createRouter(Ref ref) {
  const restrictedRoutes = {
    '/profile',
    '/history',
    '/history/detail',
    '/ai-assistant',
    '/email-verification',
    '/receipt',
  };

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isGuest = authState.isGuestMode;
      final path = state.matchedLocation;

      if (isGuest && restrictedRoutes.contains(path)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildSlideTransition(
          const SplashScreen(),
          state,
          fromRight: false,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildSlideTransition(
          const OnboardingScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _buildSlideTransition(
          const AuthScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildSlideTransition(
          const HomeScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) {
          final points = state.extra;
          final routePoints = (points is List)
              ? points.whereType<GpsPoint>().toList()
              : <GpsPoint>[];
          return _buildSlideTransition(
            FullMapScreen(routePoints: routePoints),
            state,
          );
        },
      ),
      GoRoute(
        path: '/receipt',
        pageBuilder: (context, state) {
          final trip = state.extra;
          if (trip is! TripModel) return _buildSlideTransition(const _ErrorRoute(), state);
          return _buildSlideTransition(
            ReceiptSheet(trip: trip),
            state,
            fromRight: false,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildSlideTransition(
          const ProfileScreen(),
          state,
          fromRight: false,
        ),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => _buildSlideTransition(
          const HistoryScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/history/detail',
        pageBuilder: (context, state) {
          final trip = state.extra;
          if (trip is! TripModel) return _buildSlideTransition(const _ErrorRoute(), state);
          return _buildSlideTransition(
            HistoryDetailScreen(trip: trip),
            state,
          );
        },
      ),
      GoRoute(
        path: '/routes',
        pageBuilder: (context, state) => _buildSlideTransition(
          const RouteListScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/fare-calculator',
        pageBuilder: (context, state) => _buildSlideTransition(
          const FareCalculatorScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/ai-assistant',
        pageBuilder: (context, state) => _buildSlideTransition(
          const AiAssistantScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/accident-map',
        pageBuilder: (context, state) => _buildSlideTransition(
          const AccidentMapScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/sos-settings',
        pageBuilder: (context, state) => _buildSlideTransition(
          const SosSettingsScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/email-verification',
        pageBuilder: (context, state) => _buildSlideTransition(
          const EmailScreen(),
          state,
        ),
      ),
      GoRoute(
        path: '/journey-planner',
        pageBuilder: (context, state) => _buildSlideTransition(
          const JourneyPlannerScreen(),
          state,
        ),
      ),
    ],
  );
}

Page<Object> _buildSlideTransition(Widget child, GoRouterState state, {bool fromRight = true}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final begin = fromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
      return SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return _createRouter(ref);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('--- [FATAL] Firebase.initializeApp() FAILED: $e');
    rethrow;
  }

  final storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const FareTrackApp(),
    ),
  );

  unawaited(_deferredInit());
}

Future<void> _deferredInit() async {
  try {
    await BusDatabase.initialize();
  } catch (_) {}
  try {
    await GeminiService.init();
  } catch (_) {}
  try {
    unawaited(ShakeSosService.init().catchError((_) {}));
    autoStartShakeSos();
    final bgService = BackgroundServiceManager();
    await bgService.init();
    await bgService.configureBackgroundService();
  } catch (_) {}
}

void autoStartShakeSos() {
  try {
    if (ShakeSosService.isActive) return;
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      if (p.getBool('shake_sos') ?? false) {
        ShakeSosService.start();
      }
    });
  } catch (_) {}
}

class FareTrackApp extends ConsumerStatefulWidget {
  const FareTrackApp({super.key});

  @override
  ConsumerState<FareTrackApp> createState() => _FareTrackAppState();
}

class _FareTrackAppState extends ConsumerState<FareTrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Disabled: aggressive auto-signout was logging users out on every app switch.
    // if (state == AppLifecycleState.inactive) {
    //   _autoSignOut();
    // }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0F0B1E),
                      Color(0xFF1A0F2E),
                      Color(0xFF0A0612),
                    ]
                  : const [Color(0xFFFBF9FF), Color(0xFFF1ECFB)],
            ),
          ),
          child: isDark
              ? Stack(
                  children: [
                    const _GlowBlob(
                      color: Color(0x33FF8A5C),
                      top: -60,
                      left: -50,
                      size: 280,
                    ),
                    const _GlowBlob(
                      color: Color(0x2E7C3AED),
                      bottom: -90,
                      right: -70,
                      size: 320,
                    ),
                    _GlowBlob(
                      color: const Color(0x26EC4899),
                      top: MediaQuery.of(context).size.height * 0.5,
                      right: -40,
                      size: 220,
                    ),
                    child ?? const SizedBox.shrink(),
                  ],
                )
              : child,
        );
      },
    );
  }
}

class _ErrorRoute extends StatelessWidget {
  const _ErrorRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('পৃষ্ঠাটি পাওয়া যায়নি'),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  const _GlowBlob({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
