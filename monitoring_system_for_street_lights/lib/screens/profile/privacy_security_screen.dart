import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  bool _biometricEnabled = false;
  bool _dataEncryption = true;
  bool _locationAccess = true;
  bool _deviceSecurity = false;
  bool _twoFactorAuth = false;
  bool _analyticsEnabled = false;
  bool _crashReporting = true;
  bool _locationTracking = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _loadSecuritySettings();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _twoFactorAuth = prefs.getBool('two_factor_auth') ?? false;
        _analyticsEnabled = prefs.getBool('analytics_enabled') ?? false;
        _crashReporting = prefs.getBool('crash_reporting') ?? true;
        _locationTracking = prefs.getBool('location_tracking') ?? false;
        _deviceSecurity = prefs.getBool('device_security') ?? false;
      });
    } catch (e) {
      print('Error loading security settings: $e');
    }
  }

  Future<void> _saveSecuritySetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error saving security setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: SecurityBackgroundPainter(_backgroundController.value),
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
                      'Privacy & Security',
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
                      // Security Overview Card
                      _buildOverviewCard(),
                      SizedBox(height: 24.h),

                      // Account Security Section
                      _buildSectionTitle('Account Security'),
                      SizedBox(height: 16.h),
                      _buildSecurityCard([
                        _buildSecurityItem(
                          'Two-Factor Authentication',
                          'Add an extra layer of security to your account',
                          Icons.security,
                          _twoFactorAuth,
                          (value) {
                            setState(() => _twoFactorAuth = value);
                            _saveSecuritySetting('two_factor_auth', value);
                          },
                        ),
                        _buildSecurityItem(
                          'Biometric Authentication',
                          'Use fingerprint or face unlock for quick access',
                          Icons.fingerprint,
                          _biometricEnabled,
                          (value) {
                            setState(() => _biometricEnabled = value);
                            _saveSecuritySetting('biometric_enabled', value);
                          },
                        ),
                        _buildSecurityItem(
                          'Device Security Check',
                          'Verify device security before login',
                          Icons.shield,
                          _deviceSecurity,
                          (value) {
                            setState(() => _deviceSecurity = value);
                            _saveSecuritySetting('device_security', value);
                          },
                        ),
                      ]),

                      SizedBox(height: 24.h),

                      // Data Protection Section
                      _buildSectionTitle('Data Protection'),
                      SizedBox(height: 16.h),
                      _buildSecurityCard([
                        _buildInfoItem(
                          'Data Encryption',
                          'All data is encrypted using AES-256 standards',
                          Icons.lock,
                          _dataEncryption,
                        ),
                        _buildSecurityItem(
                          'Location Services',
                          'Allow app to access device location for enhanced features',
                          Icons.location_on,
                          _locationAccess,
                          (value) {
                            setState(() => _locationAccess = value);
                          },
                        ),
                        _buildSecurityItem(
                          'Location Tracking',
                          'Track location history for analytics (optional)',
                          Icons.my_location,
                          _locationTracking,
                          (value) {
                            setState(() => _locationTracking = value);
                            _saveSecuritySetting('location_tracking', value);
                          },
                        ),
                      ]),

                      SizedBox(height: 24.h),

                      // Privacy Controls Section
                      _buildSectionTitle('Privacy Controls'),
                      SizedBox(height: 16.h),
                      _buildSecurityCard([
                        _buildSecurityItem(
                          'Usage Analytics',
                          'Help improve the app by sharing anonymous usage data',
                          Icons.analytics,
                          _analyticsEnabled,
                          (value) {
                            setState(() => _analyticsEnabled = value);
                            _saveSecuritySetting('analytics_enabled', value);
                          },
                        ),
                        _buildSecurityItem(
                          'Crash Reporting',
                          'Automatically send crash reports to help fix issues',
                          Icons.bug_report,
                          _crashReporting,
                          (value) {
                            setState(() => _crashReporting = value);
                            _saveSecuritySetting('crash_reporting', value);
                          },
                        ),
                      ]),

                      SizedBox(height: 24.h),

                      // Data Management Section
                      _buildSectionTitle('Data Management'),
                      SizedBox(height: 16.h),
                      _buildActionCard([
                        _buildActionItem(
                          'Export My Data',
                          'Download a copy of all your data',
                          Icons.download,
                          Colors.blue,
                          () => _showDataExportDialog(),
                        ),
                        _buildActionItem(
                          'Delete Account',
                          'Permanently delete your account and all data',
                          Icons.delete_forever,
                          Colors.red,
                          () => _showDeleteAccountDialog(),
                        ),
                      ]),

                      SizedBox(height: 24.h),

                      // Permissions Section
                      _buildSectionTitle('App Permissions'),
                      SizedBox(height: 16.h),
                      _buildPermissionCard(),

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

  Widget _buildOverviewCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Status',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Your account is protected with industry-standard security measures',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildStatusIndicator('Encrypted', true),
              SizedBox(width: 12.w),
              _buildStatusIndicator('Secure Login', true),
              SizedBox(width: 12.w),
              _buildStatusIndicator('Protected', true),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 800.ms);
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.error,
              color: isActive ? Colors.white : Colors.red.shade300,
              size: 16.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildSecurityCard(List<Widget> children) {
    return Container(
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
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          final isLast = index == children.length - 1;

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
            child: child,
          );
        }).toList(),
      ),
    ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 600.ms);
  }

  Widget _buildSecurityItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: const Color(0xFF667EEA), size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667EEA),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String subtitle,
    IconData icon,
    bool isEnabled,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF48BB78).withOpacity(0.1)
                  : const Color(0xFF718096).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: isEnabled
                  ? const Color(0xFF48BB78)
                  : const Color(0xFF718096),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFFDEF7EC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              isEnabled ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? const Color(0xFF047857)
                    : const Color(0xFF718096),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(List<Widget> children) {
    return Container(
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
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          final isLast = index == children.length - 1;

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
            child: child,
          );
        }).toList(),
      ),
    ).animate().slideY(begin: 0.2, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
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
    );
  }

  Widget _buildPermissionCard() {
    final permissions = [
      {
        'title': 'Camera',
        'description': 'Access camera to capture fault images',
        'icon': Icons.camera_alt,
        'enabled': true,
      },
      {
        'title': 'Location',
        'description': 'Access location for street light mapping',
        'icon': Icons.location_on,
        'enabled': true,
      },
      {
        'title': 'Notifications',
        'description': 'Send alerts for system faults and updates',
        'icon': Icons.notifications,
        'enabled': true,
      },
      {
        'title': 'Storage',
        'description': 'Store offline data and user preferences',
        'icon': Icons.storage,
        'enabled': true,
      },
    ];

    return Container(
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
        children: permissions.asMap().entries.map((entry) {
          final index = entry.key;
          final permission = entry.value;
          final isLast = index == permissions.length - 1;

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
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: permission['enabled'] == true
                          ? const Color(0xFF48BB78).withOpacity(0.1)
                          : const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      permission['icon'] as IconData,
                      color: permission['enabled'] == true
                          ? const Color(0xFF48BB78)
                          : const Color(0xFFE53E3E),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          permission['title'] as String,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          permission['description'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: permission['enabled'] == true
                          ? const Color(0xFFDEF7EC)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      permission['enabled'] == true ? 'Granted' : 'Denied',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: permission['enabled'] == true
                            ? const Color(0xFF047857)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().slideY(begin: 0.2, delay: 600.ms, duration: 600.ms);
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.download, color: Colors.blue, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              'Export Data',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Your data will be exported as a JSON file containing all your account information, preferences, and activity history.',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export request submitted'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Export', style: TextStyle(color: Colors.white)),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              'Delete Account',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted:',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
            ),
            SizedBox(height: 12.h),
            ...[
              'Profile information',
              'Activity history',
              'Preferences',
              'Saved data',
            ].map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6.sp, color: Colors.red),
                    SizedBox(width: 8.w),
                    Text(item, style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

// Custom Painter for Security Background
class SecurityBackgroundPainter extends CustomPainter {
  final double animationValue;

  SecurityBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Security themed floating elements
    for (int i = 0; i < 6; i++) {
      final offset = Offset(
        (size.width * 0.15 * i) +
            (25 * (animationValue + i * 0.4).remainder(1)),
        (size.height * 0.1) +
            (15 * (animationValue * 0.3 + i * 0.25).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.02);
      canvas.drawCircle(offset, 8 + (i * 1.5), paint);
    }

    // Additional security elements
    for (int i = 0; i < 4; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.2 * i) -
            (35 * animationValue.remainder(1)),
        (size.height * 0.7) +
            (20 * (animationValue * 0.4 + i * 0.3).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.015);
      canvas.drawCircle(offset, 6 + (i * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
