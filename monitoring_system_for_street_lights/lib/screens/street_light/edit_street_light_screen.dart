import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditStreetLightScreen extends StatefulWidget {
  final Map<String, dynamic> streetLightData;

  const EditStreetLightScreen({super.key, required this.streetLightData});

  @override
  State<EditStreetLightScreen> createState() => _EditStreetLightScreenState();
}

class _EditStreetLightScreenState extends State<EditStreetLightScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController areaController;
  late TextEditingController wardController;
  late TextEditingController phoneController;
  late TextEditingController streetLightNumberController;
  late TextEditingController latController;
  late TextEditingController lngController;

  bool isLoading = false;
  bool isFormChanged = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    nameController = TextEditingController(
      text: widget.streetLightData['name'] ?? '',
    );
    addressController = TextEditingController(
      text:
          widget.streetLightData['address'] ??
          widget.streetLightData['fullAddress']?['street'] ??
          '',
    );
    areaController = TextEditingController(
      text:
          widget.streetLightData['area'] ??
          widget.streetLightData['fullAddress']?['area'] ??
          '',
    );
    wardController = TextEditingController(
      text:
          widget.streetLightData['ward'] ??
          widget.streetLightData['fullAddress']?['ward'] ??
          '',
    );
    phoneController = TextEditingController(
      text: widget.streetLightData['phoneNumber'] ?? '',
    );
    streetLightNumberController = TextEditingController(
      text:
          widget.streetLightData['streetLightNumber'] ??
          widget.streetLightData['number'] ??
          widget.streetLightData['lightNumber'] ??
          '',
    );
    latController = TextEditingController(
      text:
          (widget.streetLightData['latitude'] ??
                  widget.streetLightData['coordinates']?['lat'])
              ?.toString() ??
          '',
    );
    lngController = TextEditingController(
      text:
          (widget.streetLightData['longitude'] ??
                  widget.streetLightData['coordinates']?['lng'])
              ?.toString() ??
          '',
    );

    // Add listeners to detect changes
    nameController.addListener(_onFieldChanged);
    addressController.addListener(_onFieldChanged);
    areaController.addListener(_onFieldChanged);
    wardController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    streetLightNumberController.addListener(_onFieldChanged);
    latController.addListener(_onFieldChanged);
    lngController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!isFormChanged) {
      setState(() {
        isFormChanged = true;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    areaController.dispose();
    wardController.dispose();
    phoneController.dispose();
    streetLightNumberController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF6B73FF),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  'Edit Street Light',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(),
                centerTitle: true,
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ).animate().scale(delay: 300.ms),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isFormChanged
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isFormChanged
                        ? Colors.green.withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: isFormChanged && !isLoading
                      ? _updateStreetLight
                      : null,
                  icon: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.save_rounded,
                          color: isFormChanged ? Colors.white : Colors.white70,
                          size: 22.sp,
                        ),
                ),
              ).animate().scale(delay: 400.ms),
            ],
          ),

          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Basic Information Section
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      children: [
                        _buildLuxuryTextField(
                          controller: nameController,
                          label: 'Street Light Name',
                          icon: Icons.lightbulb_outline,
                          isRequired: true,
                        ),
                        SizedBox(height: 16.h),
                        _buildLuxuryTextField(
                          controller: streetLightNumberController,
                          label: 'Street Light Number',
                          icon: Icons.numbers_rounded,
                          isRequired: false,
                        ),
                        SizedBox(height: 16.h),
                        _buildLuxuryTextField(
                          controller: phoneController,
                          label: 'GSM ID / Phone Number',
                          icon: Icons.sim_card_rounded,
                          keyboardType: TextInputType.phone,
                          isRequired: false,
                        ),
                      ],
                    ).animate().slideY(
                      begin: 0.3,
                      duration: 600.ms,
                      delay: 100.ms,
                    ),

                    SizedBox(height: 24.h),

                    // Location Details Section
                    _buildSectionCard(
                      title: 'Location Details',
                      icon: Icons.location_on_outlined,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                      ),
                      children: [
                        _buildLuxuryTextField(
                          controller: addressController,
                          label: 'Street Address',
                          icon: Icons.home_outlined,
                          isRequired: true,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLuxuryTextField(
                                controller: areaController,
                                label: 'Area',
                                icon: Icons.location_city_outlined,
                                isRequired: false,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildLuxuryTextField(
                                controller: wardController,
                                label: 'Ward',
                                icon: Icons.domain_outlined,
                                isRequired: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().slideY(
                      begin: 0.3,
                      duration: 600.ms,
                      delay: 200.ms,
                    ),

                    SizedBox(height: 24.h),

                    // Coordinates Section
                    _buildSectionCard(
                      title: 'GPS Coordinates',
                      icon: Icons.gps_fixed_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildLuxuryTextField(
                                controller: latController,
                                label: 'Latitude',
                                icon: Icons.explore_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                isRequired: false,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildLuxuryTextField(
                                controller: lngController,
                                label: 'Longitude',
                                icon: Icons.explore_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                isRequired: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'GPS coordinates help locate the exact position of the street light',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().slideY(
                      begin: 0.3,
                      duration: 600.ms,
                      delay: 300.ms,
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          // Section Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
                letterSpacing: 0.3,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4.w),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: isRequired
                ? (value) => value?.trim().isEmpty == true
                      ? '$label is required'
                      : null
                : null,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.all(12.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: const Color(0xFF667EEA), size: 18.sp),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: const Color(0xFF667EEA),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.red.withOpacity(0.7),
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStreetLight() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Parse coordinates
      final double? lat = double.tryParse(latController.text.trim());
      final double? lng = double.tryParse(lngController.text.trim());

      // Prepare updated data
      final updatedData = {
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'area': areaController.text.trim(),
        'ward': wardController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'streetLightNumber': streetLightNumberController.text.trim(),
        'latitude': lat ?? 0.0,
        'longitude': lng ?? 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'coordinates': {'lat': lat ?? 0.0, 'lng': lng ?? 0.0},
        'fullAddress': {
          'street': addressController.text.trim(),
          'area': areaController.text.trim(),
          'ward': wardController.text.trim(),
          'formatted':
              '${addressController.text.trim()}, ${areaController.text.trim()}',
        },
      };

      // Get document ID
      final docId = widget.streetLightData['id'];
      if (docId == null || docId.toString().isEmpty) {
        throw Exception('Document ID not found');
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('street_lights')
          .doc(docId.toString())
          .update(updatedData);

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Failed to update: ${e.toString()}',
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
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ).animate().scale(duration: 500.ms),
              SizedBox(height: 20.h),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 8.h),
              Text(
                'Street light details updated successfully',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(
                      context,
                    ).pop(true); // Return to detail screen with success
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.3, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
