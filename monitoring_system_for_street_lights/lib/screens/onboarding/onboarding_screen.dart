import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/onboarding_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
          transitionDuration: AppConstants.mediumAnimation,
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < onboardingContents.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.shortAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingMedium.w),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: onboardingContents.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    content: onboardingContents[index],
                    index: index,
                  );
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: EdgeInsets.all(AppConstants.paddingLarge.w),
              child: Column(
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingContents.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppConstants.primaryColor,
                      dotColor: AppConstants.primaryColor.withOpacity(0.3),
                      dotHeight: 8.h,
                      dotWidth: 8.w,
                      expansionFactor: 3,
                      spacing: 8.w,
                    ),
                  ).animate().slideY(
                    begin: 1,
                    delay: 600.ms,
                    duration: AppConstants.mediumAnimation,
                  ),

                  SizedBox(height: AppConstants.paddingLarge.h),

                  // Next/Get Started Button
                  CustomButton(
                    text: _currentIndex == onboardingContents.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _nextPage,
                    icon: _currentIndex == onboardingContents.length - 1
                        ? Icons.rocket_launch
                        : Icons.arrow_forward,
                  ).animate().slideY(
                    begin: 1,
                    delay: 700.ms,
                    duration: AppConstants.mediumAnimation,
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

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;
  final int index;

  const OnboardingPage({super.key, required this.content, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation Container
          Container(
            height: 300.h,
            width: 300.w,
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusXLarge.r),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getIconForIndex(index),
                size: 120.sp,
                color: Colors.white,
              ),
            ),
          ).animate().scale(
            delay: 200.ms,
            duration: AppConstants.longAnimation,
            curve: Curves.elasticOut,
          ),

          SizedBox(height: AppConstants.paddingXLarge.h),

          // Title
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ).animate().slideY(
            begin: 0.5,
            delay: 400.ms,
            duration: AppConstants.mediumAnimation,
          ),

          SizedBox(height: AppConstants.paddingMedium.h),

          // Description
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ).animate().slideY(
            begin: 0.5,
            delay: 500.ms,
            duration: AppConstants.mediumAnimation,
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.lightbulb_outline;
      case 1:
        return Icons.analytics_outlined;
      case 2:
        return Icons.location_city_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }
}
