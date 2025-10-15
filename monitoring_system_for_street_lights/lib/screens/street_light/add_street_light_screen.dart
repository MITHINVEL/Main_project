import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../maps/location_picker_screen.dart';
import '../../services/location_service.dart';

class AddStreetLightScreen extends StatefulWidget {
  const AddStreetLightScreen({super.key});

  @override
  State<AddStreetLightScreen> createState() => _AddStreetLightScreenState();
}

class _AddStreetLightScreenState extends State<AddStreetLightScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late AnimationController _backgroundController;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _wardController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _powerConsumptionController = TextEditingController();

  String _selectedStatus = 'off';
  int _brightness = 100;
  bool _isScheduled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _wardController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _powerConsumptionController.dispose();
    super.dispose();
  }

  Future<void> _addStreetLight() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        print('Starting to add street light...');
        print('User: ${user.email}');

        // Generate unique ID for street light
        final streetLightId = FirebaseFirestore.instance
            .collection('street_lights')
            .doc()
            .id;

        print('Generated ID: $streetLightId');

        // Prepare street light data
        final streetLightData = {
          'id': streetLightId,
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'area': _areaController.text.trim(),
          'ward': _wardController.text.trim(),
          'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
          'status': _selectedStatus,
          'brightness': _brightness,
          'powerConsumption':
              double.tryParse(_powerConsumptionController.text.trim()) ?? 0.0,
          'isScheduled': _isScheduled,
          'schedule': {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
          'createdByEmail': user.email,
          'isActive': true,
        };

        print('Data prepared: ${streetLightData.toString()}');

        // Save to Firestore
        print('Saving to Firestore...');
        await FirebaseFirestore.instance
            .collection('street_lights')
            .doc(streetLightId)
            .set(streetLightData);

        print('Successfully saved to Firestore!');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text('Street Light added successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );

          // Navigate back and refresh
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        print('Error adding street light: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding street light: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      print('Form validation failed!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Open Google Maps location picker
  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialLatitude: double.tryParse(_latitudeController.text.trim()),
            initialLongitude: double.tryParse(_longitudeController.text.trim()),
            initialAddress: _addressController.text.trim(),
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _latitudeController.text = result['latitude'].toString();
          _longitudeController.text = result['longitude'].toString();
          _addressController.text = result['address'] ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Location updated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening location picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get current location and fill address
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
          _addressController.text = address;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.my_location, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Current location added!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting current location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomPaint(
        painter: StreetLightBackgroundPainter(_backgroundController.value),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFF2D3748),
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Add Street Light',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: -0.3, duration: 600.ms),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // Street Light Icon Animation
                        Container(
                              width: 120.w,
                              height: 120.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(60.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF667EEA,
                                    ).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 60.sp,
                              ),
                            )
                            .animate()
                            .scale(duration: 800.ms, curve: Curves.elasticOut)
                            .then()
                            .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withOpacity(0.3),
                            ),

                        SizedBox(height: 30.h),

                        // Basic Information Section
                        _buildSectionCard('Basic Information', Icons.info, [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Street Light Name',
                            icon: Icons.lightbulb_outline,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter street light name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Contact Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                        ], 0),

                        SizedBox(height: 20.h),

                        // Location Information Section
                        _buildSectionCard(
                          'Location Information',
                          Icons.location_on,
                          [
                            _buildTextField(
                              controller: _addressController,
                              label: 'Street Address',
                              icon: Icons.home,
                              maxLines: 2,
                              suffixIcon: IconButton(
                                onPressed: _openLocationPicker,
                                icon: Icon(
                                  Icons.location_on,
                                  color: const Color(0xFF667EEA),
                                  size: 24.sp,
                                ),
                                tooltip: 'Pick from map',
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter street address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                           
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _latitudeController,
                                    label: 'Latitude',
                                    icon: Icons.gps_fixed,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _longitudeController,
                                    label: 'Longitude',
                                    icon: Icons.gps_fixed,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            // Current Location Button
                            Container(
                              width: double.infinity,
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFF667EEA),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _getCurrentLocation,
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.my_location,
                                        color: const Color(0xFF667EEA),
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Use Current Location',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF667EEA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          1,
                        ),

                        SizedBox(height: 20.h),

                        // Technical Specifications Section
                        _buildSectionCard(
                          'Technical Specifications',
                          Icons.settings,
                          [
                            // Status Dropdown
                            _buildDropdownField(
                              label: 'Initial Status',
                              value: _selectedStatus,
                              icon: Icons.power_settings_new,
                              items: const [
                                DropdownMenuItem(
                                  value: 'on',
                                  child: Text('On'),
                                ),
                                DropdownMenuItem(
                                  value: 'off',
                                  child: Text('Off'),
                                ),
                                DropdownMenuItem(
                                  value: 'maintenance',
                                  child: Text('Maintenance'),
                                ),
                                DropdownMenuItem(
                                  value: 'faulty',
                                  child: Text('Faulty'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedStatus = value!);
                              },
                            ),
                            SizedBox(height: 16.h),

                            // Brightness Slider
                            _buildSliderField(
                              label: 'Initial Brightness',
                              value: _brightness,
                              icon: Icons.brightness_6,
                              onChanged: (value) {
                                setState(() => _brightness = value.round());
                              },
                            ),
                            SizedBox(height: 16.h),

                            _buildTextField(
                              controller: _powerConsumptionController,
                              label: 'Power Consumption (Watts)',
                              icon: Icons.electric_bolt,
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16.h),

                            // Scheduled Switch
                            _buildSwitchField(
                              label: 'Enable Scheduling',
                              value: _isScheduled,
                              icon: Icons.schedule,
                              onChanged: (value) {
                                setState(() => _isScheduled = value);
                              },
                            ),
                          ],
                          2,
                        ),

                        SizedBox(height: 20.h),

                        // Test Button (for debugging)
                        Container(
                          width: double.infinity,
                          height: 48.h,
                          margin: EdgeInsets.only(bottom: 20.h),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Not logged in'),
                                      ),
                                    );
                                    return;
                                  }

                                  print('Testing Firestore connection...');
                                  await FirebaseFirestore.instance
                                      .collection('test')
                                      .doc('test_doc')
                                      .set({
                                        'message': 'Hello from Flutter!',
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                        'user': user.email,
                                      });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Test successful! Check Firestore',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  print('Test failed: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Test failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Center(
                                child: Text(
                                  'Test Firestore Connection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Add Button
                        Container(
                          width: double.infinity,
                          height: 56.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _addStreetLight,
                              borderRadius: BorderRadius.circular(16.r),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24.w,
                                        height: 24.h,
                                        child: const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 24.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Add Street Light',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ).animate().slideY(
                          begin: 0.3,
                          delay: 1200.ms,
                          duration: 600.ms,
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
    int index,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: const Color(0xFF667EEA), size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    ).animate().slideY(
      begin: 0.3,
      delay: (400 + index * 200).ms,
      duration: 600.ms,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required int value,
    required IconData icon,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF667EEA), size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              '$label: $value%',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF667EEA),
            inactiveTrackColor: const Color(0xFF667EEA).withOpacity(0.3),
            thumbColor: const Color(0xFF667EEA),
            overlayColor: const Color(0xFF667EEA).withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required IconData icon,
    required void Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667EEA), size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF667EEA),
        ),
      ],
    );
  }
}

// Custom Painter for Street Light Background
class StreetLightBackgroundPainter extends CustomPainter {
  final double animationValue;

  StreetLightBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Animated light circles
    for (int i = 0; i < 8; i++) {
      final offset = Offset(
        (size.width * 0.15 * i) +
            (40 * (animationValue + i * 0.3).remainder(1)),
        (size.height * 0.1) +
            (30 * (animationValue * 0.5 + i * 0.2).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.02);
      canvas.drawCircle(offset, 15 + (i * 1.5), paint);
    }

    // Street light pole shapes
    for (int i = 0; i < 4; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.25 * i) -
            (60 * animationValue.remainder(1)),
        (size.height * 0.7) +
            (35 * (animationValue * 0.4 + i * 0.3).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.015);
      canvas.drawRRect(
        RRect.fromLTRBR(
          offset.dx - 8,
          offset.dy - 20,
          offset.dx + 8,
          offset.dy + 20,
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
