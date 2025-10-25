import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:monitoring_system_for_street_lights/providers/auth_provider.dart'
    as AppAuthProvider;
import 'package:monitoring_system_for_street_lights/screens/home/dashboard_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/notifications/notifications_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/privacy_security_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/help_support_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/about_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/onboarding/onboarding_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/auth/welcome_screen.dart';
import 'package:monitoring_system_for_street_lights/services/sms_listener_service.dart';
import 'package:monitoring_system_for_street_lights/services/push_notification_service.dart';
import 'package:monitoring_system_for_street_lights/services/street_light_monitoring_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Initialize Push Notification Service
    try {
      await PushNotificationService.initialize();
      print("Push notification service initialized");
    } catch (e) {
      print("Push notification initialization failed: $e");
      // Don't fail the app if push notifications fail
    }

    // Initialize SMS Listener Service with platform listener enabled
    try {
      final smsService = SmsListenerService(enablePlatformListener: true);
      await smsService.start();
      print("SMS service started");
    } catch (e) {
      print("SMS service initialization failed: $e");
      // Don't fail the app if SMS service fails
    }

    // Start Street Light Monitoring Service
    try {
      await StreetLightMonitoringService.startMonitoring();
      print("Street light monitoring started");
    } catch (e) {
      print("Street light monitoring failed: $e");
      // Don't fail the app if monitoring fails
    }
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Even if Firebase fails, we should show an error screen instead of blank
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (context) => AppAuthProvider.AuthProvider(),
          child: MaterialApp(
            title: 'Street Light Monitor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            home: const AuthenticationWrapper(),
            routes: {
              '/profile/notifications': (context) =>
                  const NotificationsScreen(),
              '/profile/privacy': (context) => const PrivacySecurityScreen(),
              '/profile/help': (context) => const HelpSupportScreen(),
              '/profile/about': (context) => const AboutScreen(),
            },
          ),
        );
      },
    );
  }
}

/// Wrapper to determine which screen to show based on:
/// 1. Logged in user → Dashboard (highest priority)
/// 2. First-time user (not logged in) → Onboarding
/// 3. Returning user (not logged in) → Welcome/Login
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  Future<Widget> _determineInitialScreen() async {
    try {
      print("Determining initial screen...");

      // Check if user is logged in FIRST
      final currentUser = FirebaseAuth.instance.currentUser;
      print("Current user: ${currentUser?.email ?? 'No user'}");

      if (currentUser != null) {
        // User is logged in, go directly to dashboard
        print("User is logged in, navigating to dashboard");
        return const DashboardScreen();
      }

      // User is not logged in, check if first time user
      print("Checking SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      print("Onboarding completed: $onboardingCompleted");

      if (!onboardingCompleted) {
        // First time user, show onboarding
        print("First time user, showing onboarding");
        return const OnboardingScreen();
      }

      // Not logged in but has seen onboarding, show welcome/login screen
      print("Returning user, showing welcome screen");
      return const WelcomeScreen();
    } catch (e) {
      print("Error in _determineInitialScreen: $e");
      // If there's any error, default to onboarding screen
      return const OnboardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading screen while determining initial route
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 80.sp,
                    color: const Color(0xFF6C63FF),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Street Light Monitor',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          // Show error screen
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
                  SizedBox(height: 24.h),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }
}
