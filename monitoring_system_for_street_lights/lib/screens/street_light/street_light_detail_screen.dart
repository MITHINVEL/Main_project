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
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GSM ID',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF718096),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            phone != null && phone.isNotEmpty ? phone : '—',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () async {
                          if (phone != null && phone.isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('GSM ID copied to clipboard'),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.copy, color: const Color(0xFF667EEA)),
                      ),
                    ],
                  ),
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

            Spacer(),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Open external Google Maps for directions (app or web)
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                      );
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                    icon: Icon(
                      Icons.directions,
                      color: const Color(0xFF667EEA),
                    ),
                    label: Text(
                      'Navigate',
                      style: TextStyle(color: const Color(0xFF667EEA)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Open external Google Maps for navigation from current location
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                      );
                      if (await canLaunchUrl(url))
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                    },
                    icon: Icon(Icons.open_in_new, color: Colors.white),
                    label: Text(
                      'Open in Maps',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
