import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monitoring_system_for_street_lights/screens/home/dashboard_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/notifications/notifications_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/privacy_security_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/help_support_screen.dart';
import 'package:monitoring_system_for_street_lights/screens/profile/about_screen.dart';
import 'package:monitoring_system_for_street_lights/services/sms_listener_service.dart';
import 'package:monitoring_system_for_street_lights/services/push_notification_service.dart';
import 'package:monitoring_system_for_street_lights/services/street_light_monitoring_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Push Notification Service
  await PushNotificationService.initialize();

  // Initialize SMS Listener Service with platform listener enabled
  final smsService = SmsListenerService(enablePlatformListener: true);
  await smsService.start();

  // Start Street Light Monitoring Service
  await StreetLightMonitoringService.startMonitoring();

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
        return MaterialApp(
          title: 'Street Light Monitor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          home: const DashboardScreen(),
          routes: {
            '/profile/notifications': (context) => const NotificationsScreen(),
            '/profile/privacy': (context) => const PrivacySecurityScreen(),
            '/profile/help': (context) => const HelpSupportScreen(),
            '/profile/about': (context) => const AboutScreen(),
          },
        );
      },
    );
  }
}
