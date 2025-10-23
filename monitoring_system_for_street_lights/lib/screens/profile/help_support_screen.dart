import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I monitor street lights in real-time?',
      'answer':
          'The dashboard provides live status updates for all connected street lights. You can view their current state, temperature, and last update timestamp. The system automatically refreshes data every few seconds.',
    },
    {
      'question': 'What should I do when I receive a fault notification?',
      'answer':
          'When you receive a fault alert, tap on the notification to view details. Check the street light location, fault description, and timestamp. You can mark the fault as fixed once maintenance is completed on-site.',
    },
    {
      'question': 'How does the fault detection system work?',
      'answer':
          'The system uses IoT sensors to continuously monitor each street light. When a light fails to turn on during scheduled hours or shows abnormal current flow, it automatically triggers a fault alert and sends notifications to maintenance staff.',
    },
    {
      'question': 'Can I view historical data and analytics?',
      'answer':
          'Yes, the analytics section provides comprehensive historical data including fault frequency, performance trends, and maintenance insights. This helps in predictive maintenance and system optimization.',
    },
    {
      'question': 'How do I add or remove street lights from monitoring?',
      'answer':
          'Street light management is handled by system administrators. Contact support to add new lights or modify existing configurations. Each light requires proper IoT sensor installation and network connectivity.',
    },
    {
      'question': 'Why am I not receiving notifications?',
      'answer':
          'Check your notification settings in the app and device settings. Ensure the app has permission to send notifications and that you\'re logged in with proper access rights. Network connectivity is also required for real-time alerts.',
    },
    {
      'question': 'How secure is my data in the system?',
      'answer':
          'All data is encrypted using AES-256 standards and stored securely on Firebase cloud infrastructure. User authentication is required for access, and all communications are protected with industry-standard security protocols.',
    },
    {
      'question': 'Can I access the system offline?',
      'answer':
          'Limited offline functionality is available for viewing previously cached data. However, real-time monitoring, notifications, and most features require an active internet connection to sync with the cloud database.',
    },
  ];

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@streetlightmonitor.com',
      query: 'subject=Smart Street Light Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showContactDialog();
      }
    } catch (e) {
      _showContactDialog();
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1-555-LIGHTS');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone app not available. Please call +1-555-LIGHTS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open phone app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@streetlightmonitor.com'),
            SizedBox(height: 8.h),
            Text('Phone: +1-555-LIGHTS'),
            SizedBox(height: 8.h),
            Text('Hours: 24/7 Emergency Support'),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: HelpBackgroundPainter(_backgroundController.value),
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
                      'Help & Support',
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
                      // Support Overview Card
                      _buildSupportOverviewCard(),
                      SizedBox(height: 24.h),

                      // Quick Actions
                      _buildQuickActionsCard(),
                      SizedBox(height: 24.h),

                      // FAQ Section
                      _buildSectionTitle('Frequently Asked Questions'),
                      SizedBox(height: 16.h),
                      _buildFAQSection(),

                      SizedBox(height: 24.h),

                      // Contact Support Section
                      _buildSectionTitle('Contact Support'),
                      SizedBox(height: 16.h),
                      _buildContactSection(),

                      SizedBox(height: 24.h),

                      // System Information
                      _buildSectionTitle('System Information'),
                      SizedBox(height: 16.h),
                      _buildSystemInfoCard(),

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

  Widget _buildSupportOverviewCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF48BB78), Color(0xFF38A169)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF48BB78).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.support_agent,
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
                      '24/7 Support Available',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Our technical team is here to help you monitor and maintain your smart street lighting infrastructure.',
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
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSupportStat('Response Time', '< 2 hrs'),
                Container(
                  width: 1,
                  height: 30.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildSupportStat('Availability', '99.9%'),
                Container(
                  width: 1,
                  height: 30.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildSupportStat('Satisfaction', '4.9/5'),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 800.ms);
  }

  Widget _buildSupportStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    final actions = [
      {
        'title': 'Report Issue',
        'subtitle': 'Report a system problem',
        'icon': Icons.report_problem,
        'color': const Color(0xFFE53E3E),
        'action': () => _showReportIssueDialog(),
      },
      {
        'title': 'Live Chat',
        'subtitle': 'Chat with support agent',
        'icon': Icons.chat,
        'color': const Color(0xFF667EEA),
        'action': () => _showChatDialog(),
      },
      {
        'title': 'User Manual',
        'subtitle': 'Download user guide',
        'icon': Icons.description,
        'color': const Color(0xFF48BB78),
        'action': () => _showUserManualDialog(),
      },
      {
        'title': 'Video Tutorials',
        'subtitle': 'Watch how-to videos',
        'icon': Icons.play_circle,
        'color': const Color(0xFFED8936),
        'action': () => _showTutorialsDialog(),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return GestureDetector(
          onTap: action['action'] as VoidCallback,
          child: Container(
            padding: EdgeInsets.all(16.w),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  action['title'] as String,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  action['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ).animate().scale(
          delay: (200 + index * 100).ms,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
      }).toList(),
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

  Widget _buildFAQSection() {
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
        children: _faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          final isLast = index == _faqs.length - 1;
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
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF718096),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              onExpansionChanged: (expanded) {
                // FAQ expansion handled by ExpansionTile internally
              },
            ),
          );
        }).toList(),
      ),
    ).animate().slideY(begin: 0.2, delay: 400.ms, duration: 600.ms);
  }

  Widget _buildContactSection() {
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
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _launchEmail,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.email, color: Colors.white, size: 24.sp),
                        SizedBox(height: 8.h),
                        Text(
                          'Email Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Response in 2 hours',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: _launchPhone,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 24.sp),
                        SizedBox(height: 8.h),
                        Text(
                          'Phone Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Available 24/7',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                  Icons.info_outline,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'For urgent system failures, please call our emergency hotline immediately.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 600.ms, duration: 600.ms);
  }

  Widget _buildSystemInfoCard() {
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
                  Icons.info,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Application Information',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Application', 'Smart Street Light Monitor'),
          _buildInfoRow('Version', 'v2.1.0 (Build 2025.1)'),
          _buildInfoRow('Platform', 'Flutter + Firebase'),
          _buildInfoRow('Backend', 'Firebase Realtime Database'),
          _buildInfoRow('IoT Protocol', 'MQTT + HTTP/HTTPS'),
          _buildInfoRow('Encryption', 'AES-256 + TLS 1.3'),
          _buildInfoRow('Last Update', 'January 2025'),
          _buildInfoRow(
            'Support ID',
            'SLM-2025-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 800.ms, duration: 600.ms);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog() {
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
              child: Icon(Icons.report_problem, color: Colors.red, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Text('Report Issue', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Text(
          'Please describe the issue you\'re experiencing. Our support team will investigate and provide a solution.',
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
              _launchEmail();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Send Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('Live Chat Support'),
        content: Text(
          'Live chat will connect you with a technical support representative. Average wait time is less than 2 minutes.',
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
                  content: Text('Live chat feature coming soon!'),
                  backgroundColor: Color(0xFF667EEA),
                ),
              );
            },
            child: Text('Start Chat'),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showUserManualDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('User Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available documentation:'),
            SizedBox(height: 12.h),
            ...[
              'Quick Start Guide',
              'Feature Overview',
              'Troubleshooting',
              'API Reference',
            ].map(
              (doc) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16.sp,
                      color: const Color(0xFF667EEA),
                    ),
                    SizedBox(width: 8.w),
                    Text(doc, style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documentation download started'),
                  backgroundColor: Color(0xFF48BB78),
                ),
              );
            },
            child: Text('Download'),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showTutorialsDialog() {
    final tutorials = [
      'Getting Started with Street Light Monitoring',
      'Understanding Fault Notifications',
      'Using the Analytics Dashboard',
      'Managing User Permissions',
      'Setting Up Automated Alerts',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('Video Tutorials'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tutorials
                .map(
                  (tutorial) => ListTile(
                    leading: Icon(
                      Icons.play_circle,
                      color: const Color(0xFFED8936),
                    ),
                    title: Text(tutorial, style: TextStyle(fontSize: 12.sp)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Playing: $tutorial'),
                          backgroundColor: const Color(0xFFED8936),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
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

// Custom Painter for Help Background
class HelpBackgroundPainter extends CustomPainter {
  final double animationValue;

  HelpBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Help themed floating elements
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        (size.width * 0.2 * i) + (30 * (animationValue + i * 0.3).remainder(1)),
        (size.height * 0.1) +
            (20 * (animationValue * 0.2 + i * 0.4).remainder(1)),
      );

      paint.color = const Color(0xFF48BB78).withOpacity(0.02);
      canvas.drawCircle(offset, 10 + (i * 2), paint);
    }

    // Additional help elements
    for (int i = 0; i < 4; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.25 * i) -
            (40 * animationValue.remainder(1)),
        (size.height * 0.75) +
            (25 * (animationValue * 0.3 + i * 0.2).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.015);
      canvas.drawCircle(offset, 8 + (i * 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
