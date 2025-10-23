import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _profileController;
  late AnimationController _backgroundController;
  final UserService _userService = UserService();
  User? _currentUser;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _profileController.forward();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      try {
        final userProfile = await _userService.getUserProfile(
          _currentUser!.uid,
        );

        if (userProfile != null && mounted) {
          setState(() {
            _userProfile = userProfile;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  String _getProviderInfo() {
    if (_userProfile?.provider != null) {
      switch (_userProfile!.provider) {
        case 'google.com':
          return 'Google Account';
        case 'password':
        case 'email':
          return 'Email Account';
        default:
          return 'Authenticated User';
      }
    } else if (_currentUser?.providerData.isNotEmpty == true) {
      final provider = _currentUser!.providerData.first.providerId;
      switch (provider) {
        case 'google.com':
          return 'Google Account';
        case 'password':
          return 'Email Account';
        default:
          return 'Authenticated User';
      }
    }
    return 'System User';
  }

  String _getUserDisplayName() {
    if (_userProfile?.name != null && _userProfile!.name.isNotEmpty) {
      return _userProfile!.name;
    } else if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!.split('@').first;
    } else {
      return 'User';
    }
  }

  String _getUserEmail() {
    if (_userProfile?.email != null) {
      return _userProfile!.email;
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!;
    } else {
      return 'No email available';
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog with animation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.logout,
                  color: const Color(0xFFE53E3E),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
      },
    );

    if (result == true && mounted) {
      // Show loading animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      );

      try {
        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Sign out from Google Sign In
        await GoogleSignIn().signOut();

        // Simulate logout process
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(-1.0, 0), end: Offset.zero),
                        ),
                        child: child,
                      ),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: ProfileBackgroundPainter(_backgroundController.value),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ).animate().slideX(begin: -0.3, duration: 600.ms),

                SizedBox(height: 30.h),

                // Profile Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Stack(
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(50.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child:
                                (_userProfile?.photoUrl != null ||
                                    _currentUser?.photoURL != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50.r),
                                    child: Image.network(
                                      _userProfile?.photoUrl ??
                                          _currentUser!.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 50.sp,
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50.sp,
                                  ),
                          ).animate().scale(
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child:
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF48BB78),
                                        Color(0xFF38A169),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ).animate().scale(
                                  delay: 600.ms,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // User Info
                      Text(
                        _getUserDisplayName(),
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        delay: 400.ms,
                        duration: 600.ms,
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        _getUserEmail(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF718096),
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        delay: 500.ms,
                        duration: 600.ms,
                      ),

                      SizedBox(height: 8.h),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _getProviderInfo(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().scale(delay: 600.ms, duration: 600.ms),
                    ],
                  ),
                ).animate().slideY(begin: 0.5, delay: 200.ms, duration: 800.ms),

                SizedBox(height: 30.h),

                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Lights Managed',
                        '2,543',
                        Icons.lightbulb,
                        const Color(0xFF667EEA),
                        0,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: _buildStatCard(
                        'System Uptime',
                        '99.2%',
                        Icons.trending_up,
                        const Color(0xFF48BB78),
                        1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30.h),

                // Menu Options
                _buildMenuSection(),

                SizedBox(height: 30.h),

                // Logout Button
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().slideY(
                  begin: 0.3,
                  delay: 1000.ms,
                  duration: 600.ms,
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
        ],
      ),
    ).animate().scale(
      delay: (400 + index * 100).ms,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage your alerts and reminders',
        'route': '/profile/notifications',
      },
      {
        'icon': Icons.security,
        'title': 'Privacy & Security',
        'subtitle': 'Account security settings',
        'route': '/profile/privacy',
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'route': '/profile/help',
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'subtitle': 'App version and information',
        'route': '/profile/about',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, item['route'] as String);
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFF667EEA),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFF718096),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().slideX(
            begin: 0.3,
            delay: (600 + index * 100).ms,
            duration: 600.ms,
          );
        }).toList(),
      ),
    );
  }
}

// Custom Painter for Profile Background
class ProfileBackgroundPainter extends CustomPainter {
  final double animationValue;

  ProfileBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gentle floating shapes
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        (size.width * 0.2 * i) + (30 * (animationValue + i * 0.3).remainder(1)),
        (size.height * 0.15) +
            (20 * (animationValue * 0.4 + i * 0.2).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.03);
      canvas.drawCircle(offset, 12 + (i * 2), paint);
    }

    // Additional subtle elements
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.3 * i) -
            (50 * animationValue.remainder(1)),
        (size.height * 0.8) +
            (25 * (animationValue * 0.3 + i * 0.4).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.02);
      canvas.drawCircle(offset, 8 + (i * 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
