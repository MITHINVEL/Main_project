import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: AboutBackgroundPainter(_backgroundController.value),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFF667EEA),
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ).animate().slideX(begin: -0.3, duration: 600.ms),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo and Title Card
                      _buildAppInfoCard(),
                      SizedBox(height: 24.h),

                      // Project Description
                      _buildProjectDescriptionCard(),
                      SizedBox(height: 24.h),

                      // Key Features
                      _buildFeaturesCard(),
                      SizedBox(height: 24.h),

                      // Technology Stack
                      _buildTechnologyCard(),
                      SizedBox(height: 24.h),

                      // Research & Development
                      _buildResearchCard(),
                      SizedBox(height: 24.h),

                      // Version Information
                      _buildVersionInfoCard(),
                      SizedBox(height: 24.h),

                      // Team & Credits
                      _buildCreditsCard(),
                      SizedBox(height: 24.h),

                      // Legal Information
                      _buildLegalCard(),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Logo
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _logoController.value * 0.1,
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                );
              },
            ),
          ).animate().scale(delay: 200.ms, duration: 800.ms),

          SizedBox(height: 20.h),

          Text(
            'Smart Street Light\nMonitoring System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().slideY(begin: 0.3, delay: 400.ms, duration: 600.ms),

          SizedBox(height: 8.h),

          Text(
            'IoT-Based Intelligent Infrastructure Management',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ).animate().slideY(begin: 0.3, delay: 500.ms, duration: 600.ms),

          SizedBox(height: 20.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureHighlight('Real-time', Icons.timeline),
              _buildFeatureHighlight('IoT Enabled', Icons.sensors),
              _buildFeatureHighlight('Cloud-based', Icons.cloud),
            ],
          ).animate().slideY(begin: 0.3, delay: 600.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(String label, IconData icon) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDescriptionCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.description,
                  color: const Color(0xFF48BB78),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Project Overview',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'The Smart Street Light Monitoring and Fault Detection System addresses the growing need for intelligent and energy-efficient street lighting infrastructure in modern smart cities. This comprehensive solution utilizes Firebase as the backend cloud platform and Flutter for cross-platform mobile application development.',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'The system enables authorities to remotely monitor the operational status of street lights in real-time, receive instant notifications upon fault detection, and maintain comprehensive analytics for predictive maintenance and system optimization.',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 600.ms);
  }

  Widget _buildFeaturesCard() {
    final features = [
      {
        'title': 'Real-time Monitoring',
        'description':
            'Continuous monitoring of street light operational status',
        'icon': Icons.monitor,
        'color': const Color(0xFF667EEA),
      },
      {
        'title': 'Automated Fault Detection',
        'description': 'Intelligent detection of lighting system failures',
        'icon': Icons.error_outline,
        'color': const Color(0xFFE53E3E),
      },
      {
        'title': 'Instant Notifications',
        'description': 'Immediate push notifications for critical alerts',
        'icon': Icons.notifications_active,
        'color': const Color(0xFFED8936),
      },
      {
        'title': 'Analytics Dashboard',
        'description': 'Comprehensive performance metrics and trends',
        'icon': Icons.analytics,
        'color': const Color(0xFF48BB78),
      },
      {
        'title': 'Location Mapping',
        'description': 'GPS-based street light location identification',
        'icon': Icons.location_on,
        'color': const Color(0xFF9F7AEA),
      },
      {
        'title': 'Cloud Integration',
        'description': 'Secure Firebase cloud data synchronization',
        'icon': Icons.cloud_done,
        'color': const Color(0xFF38B2AC),
      },
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.stars,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          LayoutBuilder(
            builder: (context, constraints) {
              double itemWidth = (constraints.maxWidth - 12.w) / 2;
              double itemHeight = itemWidth * 0.9;

              return Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: features.map((feature) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: (feature['color'] as Color).withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              feature['icon'] as IconData,
                              color: feature['color'] as Color,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            feature['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Expanded(
                            child: Text(
                              feature['description'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildTechnologyCard() {
    final technologies = [
      {
        'name': 'Flutter',
        'type': 'Frontend',
        'icon': '📱',
        'color': const Color(0xFF02569B),
      },
      {
        'name': 'Firebase',
        'type': 'Backend',
        'icon': '🔥',
        'color': const Color(0xFFFF9100),
      },
      {
        'name': 'IoT Sensors',
        'type': 'Hardware',
        'icon': '📡',
        'color': const Color(0xFF4CAF50),
      },
      {
        'name': 'MQTT Protocol',
        'type': 'Communication',
        'icon': '🌐',
        'color': const Color(0xFF9C27B0),
      },
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFED8936).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.code,
                  color: const Color(0xFFED8936),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Technology Stack',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...technologies.map(
            (tech) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (tech['color'] as Color).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: (tech['color'] as Color).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tech['icon'] as String,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tech['name'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          tech['type'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: tech['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 600.ms, duration: 600.ms);
  }

  Widget _buildResearchCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF9F7AEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school,
                  color: const Color(0xFF9F7AEA),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Research Foundation',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildResearchPoint(
            'Problem Statement',
            'Traditional street lighting systems suffer from high energy consumption, lack of monitoring capabilities, and delayed fault identification.',
          ),
          _buildResearchPoint(
            'Innovation',
            'Integration of IoT technology with cloud computing enables real-time monitoring, automated fault detection, and predictive maintenance.',
          ),
          _buildResearchPoint(
            'Impact',
            'Significant improvement in fault detection time (from hours to seconds), reduced maintenance costs, and enhanced system reliability.',
          ),
          _buildResearchPoint(
            'Future Scope',
            'AI-powered predictive analytics, energy optimization algorithms, and integration with smart city infrastructure.',
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 800.ms, duration: 600.ms);
  }

  Widget _buildResearchPoint(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF718096),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF38B2AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.info,
                  color: const Color(0xFF38B2AC),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Version Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildVersionRow('Application Version', 'v2.1.0'),
          _buildVersionRow('Build Number', '2025.1.23'),
          _buildVersionRow('Release Date', 'January 2025'),
          _buildVersionRow('Platform', 'Flutter 3.x'),
          _buildVersionRow('API Level', 'v2.1'),
          _buildVersionRow('Database Schema', 'v1.3'),
          _buildVersionRow('License', 'Proprietary'),
          _buildVersionRow('Support Until', 'January 2026'),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 1000.ms, duration: 600.ms);
  }

  Widget _buildVersionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF718096)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.people,
                  color: const Color(0xFF48BB78),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Development Team',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'This project was developed as part of smart city infrastructure research, focusing on IoT-based monitoring solutions for urban lighting systems.',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          _buildCreditRow('Project Lead', 'Smart City Research Team'),
          _buildCreditRow('Mobile Development', 'Flutter Development Team'),
          _buildCreditRow('Backend Engineering', 'Firebase Integration Team'),
          _buildCreditRow('IoT Solutions', 'Hardware Engineering Team'),
          _buildCreditRow('UI/UX Design', 'Design & User Experience Team'),
          _buildCreditRow('Testing & QA', 'Quality Assurance Team'),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: const Color(0xFFE53E3E),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Special thanks to all contributors who made this project possible.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF4A5568),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 1200.ms, duration: 600.ms);
  }

  Widget _buildCreditRow(String role, String name) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            margin: EdgeInsets.only(top: 6.h),
            decoration: const BoxDecoration(
              color: Color(0xFF48BB78),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '$role: $name',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF2D3748),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF718096).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.gavel,
                  color: const Color(0xFF718096),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Legal Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildLegalItem(
            'Privacy Policy',
            'View our data handling and privacy practices',
            () => _launchURL('https://example.com/privacy'),
          ),
          _buildLegalItem(
            'Terms of Service',
            'Read the terms and conditions of use',
            () => _launchURL('https://example.com/terms'),
          ),
          _buildLegalItem(
            'Open Source Licenses',
            'View third-party library licenses',
            () => _showLicensesDialog(),
          ),
          SizedBox(height: 12.h),
          Text(
            '© 2025 Smart Street Light Monitoring System. All rights reserved.',
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF718096),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 1400.ms, duration: 600.ms);
  }

  Widget _buildLegalItem(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: const Color(0xFF718096),
            ),
          ],
        ),
      ),
    );
  }

  void _showLicensesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('Open Source Licenses'),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This application uses the following open source libraries:',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ...[
                  'Flutter SDK',
                  'Firebase SDK',
                  'flutter_screenutil',
                  'flutter_animate',
                  'url_launcher',
                ].map(
                  (lib) => ListTile(
                    leading: Icon(Icons.code, size: 16.sp),
                    title: Text(
                      lib,
                      style: TextStyle(fontSize: 11.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

// Custom Painter for About Background
class AboutBackgroundPainter extends CustomPainter {
  final double animationValue;

  AboutBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // About themed floating elements
    for (int i = 0; i < 7; i++) {
      final offset = Offset(
        (size.width * 0.12 * i) +
            (20 * (animationValue + i * 0.25).remainder(1)),
        (size.height * 0.08) +
            (15 * (animationValue * 0.2 + i * 0.35).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.015);
      canvas.drawCircle(offset, 6 + (i * 1.2), paint);
    }

    // Additional floating elements
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.18 * i) -
            (30 * animationValue.remainder(1)),
        (size.height * 0.82) +
            (18 * (animationValue * 0.25 + i * 0.3).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.01);
      canvas.drawCircle(offset, 5 + (i * 1.8), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
