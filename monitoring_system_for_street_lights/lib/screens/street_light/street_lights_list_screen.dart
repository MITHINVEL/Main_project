import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'street_light_detail_screen.dart';

class StreetLightsListScreen extends StatefulWidget {
  const StreetLightsListScreen({super.key});

  @override
  State<StreetLightsListScreen> createState() => _StreetLightsListScreenState();
}

class _StreetLightsListScreenState extends State<StreetLightsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildStreetLightsList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2D3748),
      title: Text(
        'Street Lights',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search street lights...',
                hintStyle: TextStyle(
                  color: const Color(0xFF718096),
                  fontSize: 16.sp,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
        ],
      ),
    );
  }

  Widget _buildStreetLightsList() {
    final user = FirebaseAuth.instance.currentUser;

    // If no user is logged in, show empty state
    if (user == null) {
      return _buildLoginRequiredState();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('street_lights')
          .where('createdBy', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          // Log the underlying error for easier debugging
          debugPrint('StreetLightsListStream error: ${snapshot.error}');
          return _buildErrorState(snapshot.error?.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final streetLights = snapshot.data!.docs;
        final filteredLights = _filterStreetLights(streetLights);
        
        // Sort by createdAt on client-side (descending - newest first)
        filteredLights.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = aData['createdAt'];
          final bCreatedAt = bData['createdAt'];
          
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1; // nulls last
          if (bCreatedAt == null) return -1;
          
          if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
            return bCreatedAt.compareTo(aCreatedAt); // descending
          }
          return 0;
        });

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: filteredLights.length,
          itemBuilder: (context, index) {
            final doc = filteredLights[index];
            final lightData = {
              ...(doc.data() as Map<String, dynamic>),
              'id': doc.id,
            };
            return _buildStreetLightCard(lightData, index);
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterStreetLights(
    List<QueryDocumentSnapshot> lights,
  ) {
    return lights.where((light) {
      final data = light.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();

      // Search filter only
      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  Widget _buildStreetLightCard(Map<String, dynamic> lightData, int index) {
    final status = lightData['status'] ?? 'Active';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
          margin: EdgeInsets.only(bottom: 16.h),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StreetLightDetailScreen(data: lightData),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Street Light Image or Icon
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              lightData['imageUrl'] != null &&
                                  (lightData['imageUrl'] as String).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15.r),
                                  child: Image.network(
                                    lightData['imageUrl'],
                                    fit: BoxFit.cover,
                                    width: 60.w,
                                    height: 60.h,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: 60.w,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF667EEA),
                                                  const Color(0xFF764BA2),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15.r),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF667EEA),
                                              const Color(0xFF764BA2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            15.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lightbulb,
                                          color: Colors.white,
                                          size: 28.sp,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: Colors.white,
                                    size: 28.sp,
                                  ),
                                ),
                        ),

                        SizedBox(width: 16.w),

                        // Light Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lightData['name'] ?? 'Unknown Light',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: const Color(0xFF718096),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      (lightData['location'] != null &&
                                              (lightData['location'] as String)
                                                  .trim()
                                                  .isNotEmpty)
                                          ? lightData['location']
                                          : ((lightData['area'] != null &&
                                                    (lightData['area']
                                                            as String)
                                                        .trim()
                                                        .isNotEmpty)
                                                ? lightData['area']
                                                : (lightData['name'] ??
                                                      'Unknown Location')),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFF718096),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12.sp),
                              SizedBox(width: 4.w),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Details Row
                    Row(
                      children: [
                        _buildDetailChip(
                          Icons.tungsten,
                          'Type',
                          lightData['type'] ?? 'LED',
                        ),
                        SizedBox(width: 12.w),
                        _buildDetailChip(
                          Icons.brightness_6,
                          'Brightness',
                          '${lightData['brightness'] ?? 80}%',
                        ),
                        SizedBox(width: 12.w),
                        if (lightData['imageUrl'] != null &&
                            (lightData['imageUrl'] as String).isNotEmpty)
                          _buildDetailChip(
                            Icons.photo_camera,
                            'Image',
                            'Available',
                          )
                        else
                          _buildDetailChip(
                            Icons.schedule,
                            'Schedule',
                            lightData['autoSchedule'] == true
                                ? 'Auto'
                                : 'Manual',
                          ),
                      ],
                    ),

                    if (lightData['createdAt'] != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Added ${_formatDate(lightData['createdAt'])}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: (index * 100).ms)
        .slideX(begin: 0.3);
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF667EEA), size: 16.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF667EEA)),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading street lights...',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState([String? errorMessage]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: const Color(0xFFE53E3E),
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading street lights',
            style: TextStyle(
              fontSize: 18.sp,
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please try again later',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
          ),
          if (errorMessage != null) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 60.sp,
              color: const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Street Lights Found',
            style: TextStyle(
              fontSize: 20.sp,
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start by adding your first street light',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_street_light');
            },
            icon: Icon(Icons.add, size: 20.sp),
            label: Text('Add Street Light', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/add_street_light');
      },
      backgroundColor: const Color(0xFF667EEA),
      child: Icon(Icons.add, color: Colors.white, size: 28.sp),
    ).animate().scale(duration: 800.ms, delay: 1000.ms);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF48BB78);
      case 'Inactive':
        return const Color(0xFFE53E3E);
      case 'Maintenance':
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.check_circle;
      case 'Inactive':
        return Icons.cancel;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        date = DateTime.parse(timestamp.toString());
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(
              Icons.login,
              size: 60.sp,
              color: const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Login Required',
            style: TextStyle(
              fontSize: 20.sp,
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please login to view your street lights',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF718096)),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: Icon(Icons.login, size: 20.sp),
            label: Text('Login', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  // Previously showed details in a bottom sheet; replaced by full-screen
  // StreetLightDetailScreen. The old bottom sheet implementation was removed.

  // Detail row helper removed; details are now shown in full-screen detail page
}
