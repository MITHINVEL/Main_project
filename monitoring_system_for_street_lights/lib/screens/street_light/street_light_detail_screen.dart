import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StreetLightDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const StreetLightDetailScreen({super.key, required this.data});

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

  // Phone call helper removed; GSM ID is shown and copied instead.

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
    final brightness = data['brightness']?.toString() ?? '';
    final power = data['powerConsumption']?.toString() ?? '';
    final createdBy = data['createdByEmail'] ?? data['createdBy'] ?? '';
    final createdAt = _formatDate(data['createdAt']);
    final gsmNumber = phone; // GSM ID is the phone number
    final streetLightNumber =
        data['streetLightNumber'] ??
        data['number'] ??
        data['lightNumber'] ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: const Color(0xFF2D3748)),
        title: Text(
          name,
          style: TextStyle(color: const Color(0xFF2D3748), fontSize: 18.sp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Street Light Image or Icon
                  Container(
                    width: 70.w,
                    height: 70.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        data['imageUrl'] != null &&
                            (data['imageUrl'] as String).isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              data['imageUrl'],
                              fit: BoxFit.cover,
                              width: 70.w,
                              height: 70.h,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 70.w,
                                      height: 70.h,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: Colors.white,
                                    size: 32.sp,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          address,
                          style: TextStyle(color: const Color(0xFF718096)),
                        ),
                      ],
                    ),
                  ),

                  // Show GSM ID (not a phone call). Provide copy action.
                  // GSM ID display + copy action
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Location block
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: const Color(0xFF667EEA)),
                      SizedBox(width: 8.w),
                      Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    address,
                    style: TextStyle(color: const Color(0xFF718096)),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: const Color(0xFFA0AEC0),
                    ),
                  ),
                  if (area.isNotEmpty || ward.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Area: $area ${ward.isNotEmpty ? '· Ward: $ward' : ''}',
                      style: TextStyle(color: const Color(0xFF718096)),
                    ),
                  ],
                  if (createdBy.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Added by: $createdBy',
                      style: TextStyle(
                        color: const Color(0xFF718096),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      'Added on: $createdAt',
                      style: TextStyle(
                        color: const Color(0xFF718096),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Location Details Container
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: const Color(0xFF667EEA),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Location Details',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // GSM ID Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.sim_card,
                                    color: Colors.green,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'GSM ID',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                gsmNumber.isNotEmpty
                                    ? gsmNumber
                                    : 'Not Available',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: gsmNumber.isNotEmpty
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey[600],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: const Color(0xFF667EEA),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Light No.',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF667EEA),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                streetLightNumber.isNotEmpty
                                    ? streetLightNumber
                                    : 'Not Set',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: streetLightNumber.isNotEmpty
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Location Address Row
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          address.isNotEmpty
                              ? address
                              : 'Address not available',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: address.isNotEmpty
                                ? const Color(0xFF2D3748)
                                : Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                        if (area.isNotEmpty || ward.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(
                            '${area.isNotEmpty ? 'Area: $area' : ''}${area.isNotEmpty && ward.isNotEmpty ? ' • ' : ''}${ward.isNotEmpty ? 'Ward: $ward' : ''}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            // Navigation Buttons
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  // Get Directions Button
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Open external Google Maps for directions
                        final url = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                        );
                        try {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          // Show error if can't open maps
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not open Maps app'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      label: Text(
                        'Get Directions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Green
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 20.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  // Open in Maps Button
                  Container(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Open Google Maps web version
                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                        );
                        try {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          // Show error if can't open browser
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not open web browser'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          color: const Color(0xFF2196F3),
                          size: 20.sp,
                        ),
                      ),
                      label: Text(
                        'View on Map',
                        style: TextStyle(
                          color: const Color(0xFF2196F3),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 20.w,
                        ),
                        side: BorderSide(
                          color: const Color(0xFF2196F3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
