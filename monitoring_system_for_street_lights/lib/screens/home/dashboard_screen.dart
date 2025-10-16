import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:monitoring_system_for_street_lights/screens/history/notification_history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../street_light/add_street_light_screen.dart';
import '../street_light/street_lights_list_screen.dart';
import '../../widgets/weather_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _statsController;
  int _currentIndex = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _statsController.forward();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getUserDisplayName() {
    if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!.split('@').first;
    } else {
      return 'User';
    }
  }

  void _handleActionTap(String actionTitle) {
    switch (actionTitle) {
      case 'Add Light':
        Navigator.of(context)
            .push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AddStreetLightScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            )
            .then((result) {
              // Refresh the page if a street light was added successfully
              if (result == true) {
                setState(() {
                  // This will trigger a rebuild and refresh the data
                });
              }
            });
        break;
      case 'Street Light\nData':
        // Navigate to street lights list
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const StreetLightsListScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        break;
      case 'Fault\nNotifications':
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(0.2, 0.0), end: Offset.zero),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
        break;

      case 'History':
        
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NotificationHistoryScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(0.2, 0.0), end: Offset.zero),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(),
          _buildAnalyticsContent(),
          const NotificationsScreen(
            showAppBar: false,
          ), // Embedded notifications screen
          _buildProfileContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDashboardContent() {
    return CustomPaint(
      painter: BackgroundPainter(_backgroundController.value),
      child: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    // Weather Section
                    const WeatherWidget(),
                    // Quick Actions
                    _buildQuickActions(),
                    SizedBox(height: 50.h),
                    // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64.sp, color: const Color(0xFF667EEA)),
            SizedBox(height: 16.h),
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return const ProfileScreen();
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Section
          Row(
            children: [
              Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _currentUser?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15.r),
                        child: Image.network(
                          _currentUser!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24.sp,
                            );
                          },
                        ),
                      )
                    : Icon(Icons.person, color: Colors.white, size: 24.sp),
              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF718096),
                    ),
                  ),
                  Text(
                    _getUserDisplayName(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ).animate().slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),
            ],
          ),

          // Notification Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15.r),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        NotificationsScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              },
              child: Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: const Color(0xFF4A5568),
                        size: 22.sp,
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child:
                          Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53E3E),
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate()
                              .scale(
                                duration: 1000.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.red.withOpacity(0.5),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Fault\nNotifications',
        'icon': Icons.notification_important,
        'color': const Color(0xFFE53E3E),
        'count': '12',
      },
      {
        'title': 'Street Light\nData',
        'icon': Icons.analytics,
        'color': const Color(0xFF667EEA),
        'count': null,
      },
      {
        'title': 'Add Light',
        'icon': Icons.add_circle,
        'color': const Color(0xFF48BB78),
        'count': null,
      },
      {
        'title': 'History',
        'icon': Icons.history,
        'color': const Color(0xFF9F7AEA),
        'count': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ).animate().slideX(begin: -0.3, duration: 600.ms, delay: 800.ms),

        SizedBox(height: 16.h),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15.w,
            mainAxisSpacing: 15.h,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () => _handleActionTap(action['title'] as String),
              child:
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: (action['color'] as Color).withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Icon(
                                action['icon'] as IconData,
                                color: action['color'] as Color,
                                size: 24.sp,
                              ),
                            ),
                            if (action['count'] != null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child:
                                    Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE53E3E),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            action['count'] as String,
                                            style: TextStyle(
                                              fontSize: 8.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .scale(
                                          duration: 1000.ms,
                                          curve: Curves.elasticOut,
                                        )
                                        .then()
                                        .shimmer(
                                          duration: 2000.ms,
                                          color: Colors.red.withOpacity(0.5),
                                        ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Flexible(
                          child: Text(
                            action['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                    delay: (900 + index * 100).ms,
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.r),
          topRight: Radius.circular(25.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.analytics, 'Analytics', 1),
          SizedBox(width: 60.w), // Space for FAB
          _buildNavItem(Icons.notifications, 'Alerts', 2),
          _buildNavItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFF667EEA)
                        : const Color(0xFF718096),
                    size: 24.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : const Color(0xFF718096),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                duration: 200.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
              ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const AddStreetLightScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(
                                    Tween(
                                      begin: const Offset(0.0, 1.0),
                                      end: Offset.zero,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 600),
                      ),
                    )
                    .then((result) {
                      // Refresh the page if a street light was added successfully
                      if (result == true) {
                        setState(() {
                          // This will trigger a rebuild and refresh the data
                        });
                      }
                    });
              },
              borderRadius: BorderRadius.circular(30.r),
              child: Icon(Icons.add, color: Colors.white, size: 28.sp),
            ),
          ),
        )
        .animate()
        .scale(duration: 800.ms, curve: Curves.elasticOut)
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
  }
}

// Custom Painter for Animated Background
class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Subtle floating shapes
    for (int i = 0; i < 6; i++) {
      final offset = Offset(
        (size.width * 0.15 * i) +
            (40 * (animationValue + i * 0.2).remainder(1)),
        (size.height * 0.1) +
            (25 * (animationValue * 0.3 + i * 0.15).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.03);
      canvas.drawCircle(offset, 15 + (i * 3), paint);
    }

    // Additional subtle elements
    for (int i = 0; i < 4; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.2 * i) -
            (60 * animationValue.remainder(1)),
        (size.height * 0.7) +
            (35 * (animationValue * 0.4 + i * 0.3).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.02);
      canvas.drawCircle(offset, 12 + (i * 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
