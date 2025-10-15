import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Street Light Monitor';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondaryColor = Color(0xFF3B82F6); // Bright Blue
  static const Color accentColor = Color(0xFFFBBF24); // Golden Yellow
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Sizes
  static const double buttonHeight = 56.0;
  static const double cardElevation = 4.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}

// Asset Paths
class AssetPaths {
  static const String logoPath = 'assets/images/logo.png';
  static const String onboarding1 = 'assets/lottie/street_light.json';
  static const String onboarding2 = 'assets/lottie/monitoring.json';
  static const String onboarding3 = 'assets/lottie/smart_city.json';
  static const String loginAnimation = 'assets/lottie/login.json';
}

// Error Messages
class ErrorMessages {
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String nameRequired = 'Name is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsNotMatch = 'Passwords do not match';
  static const String networkError =
      'Network error. Please check your connection';
  static const String unknownError = 'An unknown error occurred';
}

// Success Messages
class SuccessMessages {
  static const String accountCreated = 'Account created successfully';
  static const String loginSuccessful = 'Login successful';
  static const String passwordReset = 'Password reset email sent';
  static const String profileUpdated = 'Profile updated successfully';
}
