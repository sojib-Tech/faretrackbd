import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
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

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('--- [FATAL] Firebase.initializeApp() FAILED: $e');
    rethrow;
  }

  unawaited(ShakeSosService.init().catchError((_) {}));

  await BusDatabase.initialize();

  await GeminiService.init();

  final storage = StorageService();
  await storage.init();

  final bgService = BackgroundServiceManager();
  await bgService.init();
  await bgService.configureBackgroundService();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const FareTrackApp(),
    ),
  );
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
