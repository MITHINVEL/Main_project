import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/social_signin_buttons.dart';
import '../home/dashboard_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppConstants.mediumAnimation,
        ),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppConstants.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConstants.surfaceColor, Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppConstants.paddingLarge.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: AppConstants.paddingXLarge.h),

                // Floating Logo Animation
                AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: Container(
                        height: 120.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          gradient: AppConstants.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusXLarge.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.lamp_charge,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ).animate().scale(
                  delay: 200.ms,
                  duration: AppConstants.longAnimation,
                  curve: Curves.elasticOut,
                ),

                SizedBox(height: AppConstants.paddingXLarge.h),

                // Welcome Text
                Column(
                  children: [
                    Text(
                      'Welcome to',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ).animate().slideY(
                      begin: 0.5,
                      delay: 400.ms,
                      duration: AppConstants.mediumAnimation,
                    ),

                    SizedBox(height: AppConstants.paddingSmall.h),

                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppConstants.primaryGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                      child: Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().slideY(
                      begin: 0.5,
                      delay: 500.ms,
                      duration: AppConstants.mediumAnimation,
                    ),

                    SizedBox(height: AppConstants.paddingMedium.h),

                    Text(
                      'Smart lighting solutions for\nsustainable cities',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppConstants.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().slideY(
                      begin: 0.5,
                      delay: 600.ms,
                      duration: AppConstants.mediumAnimation,
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.paddingXLarge.h * 1.5),

                // Social Sign In Card
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SocialSignInCard(
                      onGooglePressed: _handleGoogleSignIn,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ).animate().slideY(
                  begin: 1,
                  delay: 700.ms,
                  duration: AppConstants.mediumAnimation,
                ),

                SizedBox(height: AppConstants.paddingLarge.h),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium.w,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate().fadeIn(
                  delay: 800.ms,
                  duration: AppConstants.mediumAnimation,
                ),

                SizedBox(height: AppConstants.paddingLarge.h),

                // Traditional Sign In Buttons
                Column(
                  children: [
                    CustomButton(
                      text: 'Sign In with Email',
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const LoginScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                            transitionDuration: AppConstants.shortAnimation,
                          ),
                        );
                      },
                      icon: Iconsax.sms,
                    ).animate().slideX(
                      begin: -0.5,
                      delay: 900.ms,
                      duration: AppConstants.mediumAnimation,
                    ),

                    SizedBox(height: AppConstants.paddingMedium.h),

                    CustomButton(
                      text: 'Create New Account',
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const RegisterScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                            transitionDuration: AppConstants.shortAnimation,
                          ),
                        );
                      },
                      isOutlined: true,
                      icon: Iconsax.user_add,
                    ).animate().slideX(
                      begin: 0.5,
                      delay: 1000.ms,
                      duration: AppConstants.mediumAnimation,
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.paddingLarge.h),

                // Terms and Privacy
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  delay: 1100.ms,
                  duration: AppConstants.mediumAnimation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
