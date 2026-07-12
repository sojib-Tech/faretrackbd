import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/storage_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.straighten_rounded,
      title: AppStrings.onboardTitle1,
      subtitle: AppStrings.onboardSubtitle1,
    ),
    _OnboardingPage(
      icon: Icons.traffic_rounded,
      title: AppStrings.onboardTitle2,
      subtitle: AppStrings.onboardSubtitle2,
    ),
    _OnboardingPage(
      icon: Icons.monetization_on_rounded,
      title: AppStrings.onboardTitle3,
      subtitle: AppStrings.onboardSubtitle3,
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
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 12),
              child: Align(
                alignment: Alignment.topRight,
                child: _currentPage < 2
                    ? TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          AppStrings.skipButton,
                          style: TextStyle(
                            color: AppConstants.primaryAccent,
                            fontSize: 14,
                            fontFamily: AppConstants.fontBengali,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(
                    page: _pages[index],
                    index: index,
                    isActive: _currentPage == index,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _DotIndicator(
                        isActive: _currentPage == index,
                        index: index,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 2
                            ? AppStrings.startButton
                            : 'পরবর্তী',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppConstants.fontBengali,
                        ),
                      ),
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

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final _OnboardingPage page;
  final int index;
  final bool isActive;

  const _OnboardingPageContent({
    required this.page,
    required this.index,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isActive ? 1.0 : 0.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 56,
                color: AppConstants.primaryGreen,
              ),
            ).animate(target: isActive ? 1 : 0).scale(
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 40),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppConstants.fontBengali,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final int index;

  const _DotIndicator({required this.isActive, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppConstants.primaryGreen
            : AppConstants.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
