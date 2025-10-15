import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StreetLightsListScreen extends StatefulWidget {
  const StreetLightsListScreen({super.key});

  @override
  State<StreetLightsListScreen> createState() => _StreetLightsListScreenState();
}

class _StreetLightsListScreenState extends State<StreetLightsListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Inactive', 'Maintenance'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildStreetLightsList(),
          ),
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
      actions: [
        IconButton(
          onPressed: () {
            // Filter options
            _showFilterBottomSheet();
          },
          icon: Icon(
            Icons.tune,
            color: const Color(0xFF667EEA),
            size: 24.sp,
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
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
          
          SizedBox(height: 16.h),
          
          // Filter Chips
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Container(
                  margin: EdgeInsets.only(right: 12.w),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF667EEA),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF667EEA),
                    side: BorderSide(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildStreetLightsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('street_lights')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final streetLights = snapshot.data!.docs;
        final filteredLights = _filterStreetLights(streetLights);

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: filteredLights.length,
          itemBuilder: (context, index) {
            final lightData = filteredLights[index].data() as Map<String, dynamic>;
            return _buildStreetLightCard(lightData, index);
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterStreetLights(List<QueryDocumentSnapshot> lights) {
    return lights.where((light) {
      final data = light.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      final status = data['status'] ?? 'Active';
      
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());
      
      // Status filter
      final matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
      
      return matchesSearch && matchesFilter;
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
          onTap: () => _showStreetLightDetails(lightData),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Light Icon
                    Container(
                      width: 50.w,
                      height: 50.h,
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
                        size: 24.sp,
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
                                  lightData['location'] ?? 'Unknown Location',
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
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 12.sp,
                          ),
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
                    _buildDetailChip(
                      Icons.schedule,
                      'Schedule',
                      lightData['autoSchedule'] == true ? 'Auto' : 'Manual',
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
    ).animate().fadeIn(
      duration: 600.ms,
      delay: (index * 100).ms,
    ).slideX(begin: 0.3);
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF667EEA),
              size: 16.sp,
            ),
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
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading street lights...',
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF718096),
            ),
          ),
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
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF718096),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_street_light');
            },
            icon: Icon(Icons.add, size: 20.sp),
            label: Text(
              'Add Street Light',
              style: TextStyle(fontSize: 16.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 16.h,
              ),
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
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: 28.sp,
      ),
    ).animate().scale(
      duration: 800.ms,
      delay: 1000.ms,
    );
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 20.h),
              ..._filterOptions.map((filter) {
                return ListTile(
                  title: Text(filter),
                  leading: Radio<String>(
                    value: filter,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _showStreetLightDetails(Map<String, dynamic> lightData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
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
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lightData['name'] ?? 'Unknown Light',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          lightData['location'] ?? 'Unknown Location',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow('Type', lightData['type'] ?? 'LED'),
                      _buildDetailRow('Brightness', '${lightData['brightness'] ?? 80}%'),
                      _buildDetailRow('Status', lightData['status'] ?? 'Active'),
                      _buildDetailRow('Schedule', lightData['autoSchedule'] == true ? 'Auto' : 'Manual'),
                      if (lightData['notes'] != null && lightData['notes'].toString().isNotEmpty)
                        _buildDetailRow('Notes', lightData['notes'].toString()),
                      if (lightData['createdAt'] != null)
                        _buildDetailRow('Added', _formatDate(lightData['createdAt'])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5568),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }
}