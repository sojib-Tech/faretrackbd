import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/storage_provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _routeController;
  late Animation<double> _routeProgress;

  @override
  void initState() {
    super.initState();

    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _routeProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.easeInOut),
    );

    _routeController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    var authState = ref.read(authProvider);

    // Wait for auth state to finish loading (race condition fix)
    int waitCount = 0;
    while (authState.isLoading && waitCount < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      authState = ref.read(authProvider);
      waitCount++;
    }

    final onboardingComplete = storage.isOnboardingComplete();

    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      firebaseUser = null;
    }
    final isLoggedIn = authState.isAuthenticated || firebaseUser != null;
    final isGuest = authState.isGuestMode;

    if (mounted) {
      if (!onboardingComplete) {
        context.go('/onboarding');
      } else if (isLoggedIn) {
        context.go('/home');
      } else if (isGuest) {
        context.go('/home');
      } else {
        context.go('/auth');
      }
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B5345),
              Color(0xFF117864),
            ],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _routeController,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      progress: _routeProgress.value,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 32),
                  const _AnimatedAppName(),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontFamily: AppConstants.fontBengali,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 1200.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v1.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
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

class _AnimatedAppName extends StatefulWidget {
  const _AnimatedAppName();

  @override
  State<_AnimatedAppName> createState() => _AnimatedAppNameState();
}

class _AnimatedAppNameState extends State<_AnimatedAppName> {
  final String _text = 'FareTrack BD';
  late List<bool> _revealed;

  @override
  void initState() {
    super.initState();
    _revealed = List.filled(_text.length, false);
    _revealLetters();
  }

  Future<void> _revealLetters() async {
    for (int i = 0; i < _text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() {
          _revealed[i] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _text.split('').asMap().entries.map((entry) {
        final idx = entry.key;
        final char = entry.value;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _revealed[idx] ? 1.0 : 0.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: _revealed[idx]
                ? Matrix4.identity()
                : Matrix4.translationValues(0, 20, 0),
            child: Text(
              char == ' ' ? '\u00A0' : char,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RoutePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];

    const numPoints = 20;
    for (int i = 0; i < numPoints; i++) {
      final t = i / (numPoints - 1);
      final x = size.width * 0.1 + size.width * 0.8 * t;
      final y = size.height * 0.3 +
          sin(t * pi * 3) * 60 +
          sin(t * pi * 5) * 30;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath =
          metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }

    if (progress > 0 && progress < 1 && metrics.isNotEmpty) {
      final drawPath = metrics.first;
      final pos = drawPath.getTangentForOffset(drawPath.length * progress);
      if (pos != null) {
        final busPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos.position, 6, busPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
