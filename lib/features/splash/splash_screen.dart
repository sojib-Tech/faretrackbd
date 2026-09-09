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

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final authState = ref.read(authProvider);

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
      } else if (authState.isAdmin) {
        context.go('/admin');
      } else if (isLoggedIn || isGuest) {
        context.go('/home');
      } else {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3D6B), Color(0xFF072A4A), Color(0xFF041A2E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // App name + icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      'FareTrack',
                      style: const TextStyle(
                        fontSize: 44,
                        fontFamily: AppConstants.fontLobster,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 300.ms)
                    .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(width: 10),
                Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 500.ms)
                    .scale(duration: 600.ms, curve: Curves.easeOutBack),
              ],
            ),

            const SizedBox(height: 20),

            // Tagline
            Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontFamily: AppConstants.fontBengali,
                    fontWeight: FontWeight.w500,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, delay: 700.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}
