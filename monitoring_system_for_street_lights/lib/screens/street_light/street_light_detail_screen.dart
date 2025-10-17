import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_street_light_screen.dart';

class StreetLightDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const StreetLightDetailScreen({super.key, required this.data});

  @override
  State<StreetLightDetailScreen> createState() =>
      _StreetLightDetailScreenState();
}

class _StreetLightDetailScreenState extends State<StreetLightDetailScreen> {
  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.data);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date;
      if (timestamp is DateTime)
        date = timestamp;
      // Firestore Timestamp has toDate()
      else if (timestamp.toDate != null)
        date = timestamp.toDate();
      else
        date = DateTime.parse(timestamp.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Street Light';
    final address =
        data['fullAddress'] != null && data['fullAddress']['formatted'] != null
        ? data['fullAddress']['formatted']
        : (data['address'] ?? 'No address');
    final phone = data['phoneNumber'] ?? '';
    final area = data['area'] ?? '';
    final ward = data['ward'] ?? '';
    final lat =
        (data['latitude'] ?? data['coordinates']?['lat'])?.toDouble() ?? 0.0;
    final lng =
        (data['longitude'] ?? data['coordinates']?['lng'])?.toDouble() ?? 0.0;
    final status = (data['status'] ?? 'Unknown').toString();
    final createdBy = data['createdByEmail'] ?? data['createdBy'] ?? '';
    final createdAt = _formatDate(data['createdAt']);
    final gsmNumber = phone; // GSM ID is the phone number
    final streetLightNumber =
        data['streetLightNumber'] ??
        data['number'] ??
        data['lightNumber'] ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Simple App Bar
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2D3748), Color(0xFF4A5568)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms).slideX(),
                centerTitle: true,
                titlePadding: EdgeInsets.only(bottom: 16.h),
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ).animate().scale(delay: 300.ms),
            actions: [
              // Edit Button
              Container(
                margin: EdgeInsets.only(right: 4.w, top: 8.h, bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _navigateToEditScreen(context),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  tooltip: 'Edit Street Light',
                ),
              ).animate().scale(delay: 400.ms),

              // Delete Button
              Container(
                margin: EdgeInsets.only(right: 8.w, top: 8.h, bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  tooltip: 'Delete Street Light',
                ),
              ).animate().scale(delay: 500.ms),
            ],
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Hero Card with Street Light Info
                  _buildLuxuryHeroCard(
                    name: name,
                    address: address,
                    gsmNumber: gsmNumber,
                    streetLightNumber: streetLightNumber,
                  ).animate().slideY(begin: 0.3, duration: 600.ms),

                  SizedBox(height: 24.h),

                  // Location Details Card
                  _buildLocationDetailsCard(
                    address: address,
                    area: area,
                    ward: ward,
                    lat: lat,
                    lng: lng,
                    gsmNumber: gsmNumber,
                    streetLightNumber: streetLightNumber,
                  ).animate().slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    delay: 100.ms,
                  ),

                  SizedBox(height: 24.h),

                  // Info Card
                  _buildInfoCard(
                    createdBy: createdBy,
                    createdAt: createdAt,
                    status: status,
                  ).animate().slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    delay: 200.ms,
                  ),

                  SizedBox(height: 24.h),

                  // Action Buttons
                  _buildActionButtons(lat: lat, lng: lng).animate().slideY(
                    begin: 0.3,
                    duration: 600.ms,
                    delay: 300.ms,
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryHeroCard({
    required String name,
    required String address,
    required String gsmNumber,
    required String streetLightNumber,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Street Light Icon/Image
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child:
                    data['imageUrl'] != null &&
                        (data['imageUrl'] as String).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          width: 80.w,
                          height: 80.h,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultLightIcon();
                          },
                        ),
                      )
                    : _buildDefaultLightIcon(),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A202C),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667EEA).withOpacity(0.1),
                            const Color(0xFF764BA2).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF667EEA).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        address.isNotEmpty ? address : 'No address',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLightIcon() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(Icons.lightbulb_rounded, color: Colors.white, size: 40.sp),
    );
  }

  Widget _buildLocationDetailsCard({
    required String address,
    required String area,
    required String ward,
    required double lat,
    required double lng,
    required String gsmNumber,
    required String streetLightNumber,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFC)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A202C),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // GSM ID and Light Number Row
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.sim_card_rounded,
                  label: 'GSM ID',
                  value: gsmNumber.isNotEmpty ? gsmNumber : 'Not Available',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Light No.',
                  value: streetLightNumber.isNotEmpty
                      ? streetLightNumber
                      : 'Not Set',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Address Info
          _buildInfoTile(
            icon: Icons.location_on_rounded,
            label: 'Full Address',
            value: address.isNotEmpty ? address : 'Address not available',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
            ),
            isFullWidth: true,
          ),

          SizedBox(height: 16.h),

          // Area and Ward Row
          if (area.isNotEmpty || ward.isNotEmpty)
            Row(
              children: [
                if (area.isNotEmpty)
                  Expanded(
                    child: _buildInfoTile(
                      icon: Icons.domain_rounded,
                      label: 'Area',
                      value: area,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9D50BB), Color(0xFF6B73FF)],
                      ),
                    ),
                  ),
                if (area.isNotEmpty && ward.isNotEmpty) SizedBox(width: 16.w),
                if (ward.isNotEmpty)
                  Expanded(
                    child: _buildInfoTile(
                      icon: Icons.location_city_outlined,
                      label: 'Ward',
                      value: ward,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9472), Color(0xFFF2709C)],
                      ),
                    ),
                  ),
              ],
            ),

          if (area.isNotEmpty || ward.isNotEmpty) SizedBox(height: 16.h),

          // Coordinates
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.withOpacity(0.05),
                  Colors.purple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.indigo.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Coordinates',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A202C),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$lat,$lng'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coordinates copied to clipboard'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: Colors.indigo[600],
                    size: 18.sp,
                  ),
                  tooltip: 'Copy Coordinates',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey[50]!]),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A202C),
            ),
            maxLines: isFullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String createdBy,
    required String createdAt,
    required String status,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFC)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9472), Color(0xFFF2709C)],
                  ),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A202C),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (createdBy.isNotEmpty) ...[
            _buildSimpleInfoRow(
              icon: Icons.person_rounded,
              label: 'Added by',
              value: createdBy,
              color: Colors.blue,
            ),
            SizedBox(height: 12.h),
          ],

          if (createdAt.isNotEmpty) ...[
            _buildSimpleInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Added on',
              value: createdAt,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({required double lat, required double lng}) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Get Directions Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12.h),
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                );
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12.w),
                          Text('Could not open Maps app'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                }
              },
              icon: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              label: Text(
                'Get Directions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998E),
                padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),

          // Open in Maps Button
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                );
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12.w),
                          Text('Could not open web browser'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                }
              },
              icon: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              label: Text(
                'View on Map',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 24.w),
                side: BorderSide(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Delete Street Light',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this street light? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _deleteStreetLight(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStreetLight(BuildContext context) async {
    // Show loading dialog with better styling
    Navigator.of(context).pop(); // Close confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF2D3748),
                ),
                strokeWidth: 3,
              ),
              SizedBox(height: 20.h),
              Text(
                'Deleting...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get document ID - check multiple possible fields
      final docId = data['id'] ?? data['documentId'] ?? data['lightId'];
      print('Delete attempt - Document ID: $docId');
      print('Available data keys: ${data.keys.toList()}');
      
      if (docId == null || docId.toString().isEmpty) {
        throw Exception('Document ID not found in data: ${data.keys.toList()}');
      }

      print('Deleting street light with ID: $docId');
      
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('street_lights')
          .doc(docId.toString())
          .delete();
          
      print('Successfully deleted from Firestore: $docId');

      // Close loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Navigate back to street lights list screen
      // Pop until we reach the street lights list screen
      Navigator.of(context).popUntil((route) {
        // Check if the current route is the street lights list screen
        return route.settings.name == '/street_lights' ||
            route.isFirst ||
            (route.settings.arguments != null &&
                route.settings.arguments.toString().contains('street_light'));
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Street light deleted successfully',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Failed to delete: ${e.toString()}',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  Future<void> _navigateToEditScreen(BuildContext context) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditStreetLightScreen(streetLightData: data),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // If the edit was successful, show success message
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Street light updated successfully!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF11998E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          margin: EdgeInsets.all(16.w),
          elevation: 8,
        ),
      );
    }
  }
}
