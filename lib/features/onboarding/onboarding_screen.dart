import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/storage_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      icon: Icons.straighten_rounded,
      title: AppStrings.onboardTitle1,
      subtitle: AppStrings.onboardSubtitle1,
      gradient: AppConstants.brandGradient,
      accent: AppConstants.primary,
    ),
    _OnboardPage(
      icon: Icons.traffic_rounded,
      title: AppStrings.onboardTitle2,
      subtitle: AppStrings.onboardSubtitle2,
      gradient: const [Color(0xFF22D3EE), Color(0xFF3B82F6)],
      accent: const Color(0xFF3B82F6),
    ),
    _OnboardPage(
      icon: Icons.monetization_on_rounded,
      title: AppStrings.onboardTitle3,
      subtitle: AppStrings.onboardSubtitle3,
      gradient: AppConstants.fareGradient,
      accent: AppConstants.fareAmber,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingComplete();
    if (mounted) context.go('/home');
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
            colors: [
              Color(0xFF0A3D6B),
              Color(0xFF072A4A),
              Color(0xFF041A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: Align(
                  alignment: Alignment.topRight,
                  child: _currentPage < _pages.length - 1
                      ? TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            AppStrings.skipButton,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontFamily: AppConstants.fontBengali,
                            ),
                          ),
                        )
                      : const SizedBox(height: 48),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => _OnboardContent(
                    page: _pages[index],
                    isActive: _currentPage == index,
                  ),
                ),
              ),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: 400.ms,
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == i ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // CTA button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GradientButton(
                  label: _currentPage == _pages.length - 1
                      ? AppStrings.startButton
                      : 'পরবর্তী',
                  icon: _currentPage == _pages.length - 1
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  gradient: _pages[_currentPage].gradient,
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: 500.ms,
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accent;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accent,
  });
}

class _OnboardContent extends StatelessWidget {
  final _OnboardPage page;
  final bool isActive;

  const _OnboardContent({
    required this.page,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass illustration card
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.gradient.first.withValues(alpha: 0.7),
                    page.gradient.last.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Icon(
                page.icon,
                size: 70,
                color: Colors.white,
              ),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                duration: 700.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.6, 0.6),
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 44),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontBengali,
              color: Colors.white,
              height: 1.3,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.65),
                fontFamily: AppConstants.fontBengali,
              ),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
