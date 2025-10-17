import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
  final _streetLightNumberController = TextEditingController();
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

  // Image upload variables
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isImageUploading = false;

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

    // Request necessary permissions
    _requestAllPermissions();
  }

  // Request all necessary permissions at startup
  Future<void> _requestAllPermissions() async {
    try {
      // Check current permission status for all required permissions
      bool cameraGranted = await Permission.camera.isGranted;
      bool storageGranted =
          await Permission.storage.isGranted ||
          await Permission.photos.isGranted;
      bool notificationGranted = await Permission.notification.isGranted;
      bool locationGranted = await Permission.location.isGranted;

      print('=== PERMISSION STATUS CHECK ===');
      print('Camera: $cameraGranted');
      print('Storage/Photos: $storageGranted');
      print('Notification: $notificationGranted');
      print('Location: $locationGranted');

      // Also check camera status specifically
      PermissionStatus cameraStatus = await Permission.camera.status;
      print('Camera detailed status: $cameraStatus');

      // Check if camera permission is available on this device
      bool cameraAvailable =
          await Permission.camera.isPermanentlyDenied == false;
      print('Camera permission available: $cameraAvailable');

      // If all permissions are granted, return
      if (cameraGranted &&
          storageGranted &&
          notificationGranted &&
          locationGranted) {
        print('All permissions already granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All permissions are enabled! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Force camera permission request if not available
      if (!cameraGranted) {
        print('=== REQUESTING CAMERA PERMISSION ===');
        PermissionStatus cameraResult = await Permission.camera.request();
        print('Camera request result: $cameraResult');

        if (cameraResult.isGranted) {
          cameraGranted = true;
        } else {
          print('Camera permission denied - opening settings');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Camera permission required! Opening Settings...',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          await Future.delayed(Duration(seconds: 1));
          openAppSettings();
          return;
        }
      }

      // Create list of missing permissions
      List<Permission> permissionsToRequest = [];
      List<String> missingPermissionNames = [];

      if (!storageGranted) {
        permissionsToRequest.add(Permission.storage);
        permissionsToRequest.add(Permission.photos);
        missingPermissionNames.add('Gallery/Photos');
      }
      if (!notificationGranted) {
        permissionsToRequest.add(Permission.notification);
        missingPermissionNames.add('Notifications');
      }
      if (!locationGranted) {
        permissionsToRequest.add(Permission.location);
        missingPermissionNames.add('Location');
      }

      // Request remaining permissions if any
      if (permissionsToRequest.isNotEmpty) {
        // Show permission explanation dialog
        if (mounted) {
          bool userConsent = await _showPermissionRequestDialog(
            missingPermissionNames,
          );
          if (!userConsent) {
            return;
          }
        }

        // Request missing permissions
        Map<Permission, PermissionStatus> statuses = await permissionsToRequest
            .request();

        // Check results and provide specific guidance
        List<String> stillDenied = [];

        statuses.forEach((permission, status) {
          String permName = _getPermissionName(permission);
          if (status.isDenied || status.isPermanentlyDenied) {
            stillDenied.add(permName);
            print('$permName permission denied: $status');
          } else {
            print('$permName permission granted: $status');
          }
        });

        if (mounted) {
          if (stillDenied.isEmpty) {
            // All permissions granted
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('All permissions granted successfully! 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // Some permissions still denied - show settings dialog
            _showPermissionSettingsDialog(stillDenied);
          }
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      // If there's an error, directly open settings
      if (mounted) {
        _showErrorAndOpenSettings();
      }
    }
  }

  // Get human readable permission name
  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.storage:
      case Permission.photos:
        return 'Gallery/Photos';
      case Permission.notification:
        return 'Notifications';
      case Permission.location:
        return 'Location';
      default:
        return permission.toString();
    }
  }

  // Show permission request explanation dialog
  Future<bool> _showPermissionRequestDialog(List<String> permissions) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              title: Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF667EEA), size: 28.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Enable Permissions',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs the following permissions to work properly:',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 15.h),
                  ...permissions
                      .map(
                        (permission) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Icon(
                                _getPermissionIcon(permission),
                                color: Color(0xFF667EEA),
                                size: 20.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      permission,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _getPermissionDescription(permission),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Not Now', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF667EEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Enable Permissions',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Get permission icon
  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'Camera':
        return Icons.camera_alt;
      case 'Gallery/Photos':
        return Icons.photo_library;
      case 'Notifications':
        return Icons.notifications;
      case 'Location':
        return Icons.location_on;
      default:
        return Icons.security;
    }
  }

  // Get permission description
  String _getPermissionDescription(String permission) {
    switch (permission) {
      case 'Camera':
        return 'Take photos of street lights';
      case 'Gallery/Photos':
        return 'Select images from your gallery';
      case 'Notifications':
        return 'Receive important updates and alerts';
      case 'Location':
        return 'Find and mark street light locations';
      default:
        return 'Required for app functionality';
    }
  }

  // Show settings dialog for denied permissions
  void _showPermissionSettingsDialog(List<String> deniedPermissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.orange, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Enable in Settings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enable these permissions in Settings:',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 15.h),
              ...deniedPermissions
                  .map(
                    (permission) => Container(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getPermissionIcon(permission),
                            color: Colors.orange,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            permission,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              SizedBox(height: 15.h),
              Text(
                '1. Tap "Open Settings"\n2. Find "Permissions"\n3. Enable the required permissions\n4. Return to the app',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error and open settings
  void _showErrorAndOpenSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10.w),
              Text('Permission Error'),
            ],
          ),
          content: Text(
            'There was an error requesting permissions. Please enable them manually in Settings.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _streetLightNumberController.dispose();
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

  // Image upload methods
  // Manual camera permission check for debugging
  Future<void> _checkCameraPermissionManually() async {
    print('=== MANUAL CAMERA PERMISSION CHECK ===');

    try {
      // Check various camera permission states
      bool isGranted = await Permission.camera.isGranted;
      bool isDenied = await Permission.camera.isDenied;
      bool isPermanentlyDenied = await Permission.camera.isPermanentlyDenied;
      bool isRestricted = await Permission.camera.isRestricted;
      PermissionStatus status = await Permission.camera.status;

      print('Camera isGranted: $isGranted');
      print('Camera isDenied: $isDenied');
      print('Camera isPermanentlyDenied: $isPermanentlyDenied');
      print('Camera isRestricted: $isRestricted');
      print('Camera status: $status');

      if (mounted) {
        String message;
        Color backgroundColor;

        if (isGranted) {
          message = 'Camera permission is GRANTED ✅';
          backgroundColor = Colors.green;
        } else if (isPermanentlyDenied) {
          message = 'Camera permission PERMANENTLY DENIED ❌ - Open Settings';
          backgroundColor = Colors.red;
        } else if (isDenied) {
          message = 'Camera permission DENIED 🚫 - Will request again';
          backgroundColor = Colors.orange;
        } else {
          message = 'Camera permission status: $status';
          backgroundColor = Colors.blue;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );

        // If not granted, try to request
        if (!isGranted && !isPermanentlyDenied) {
          print('Attempting to request camera permission...');
          PermissionStatus result = await Permission.camera.request();
          print('Camera request result: $result');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission request result: $result'),
              backgroundColor: result.isGranted ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking camera permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking camera permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Comprehensive permission checking methods
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check if already granted
      if (await Permission.storage.isGranted ||
          await Permission.photos.isGranted) {
        return true;
      }

      // Show specific dialog for gallery access
      bool shouldRequest = await _showSpecificPermissionDialog(
        'Gallery Access Required',
        'To select photos from your gallery, we need storage permission.',
        Icons.photo_library,
      );

      if (!shouldRequest) return false;

      // Request permissions
      final storageResult = await Permission.storage.request();
      final photosResult = await Permission.photos.request();

      bool granted =
          storageResult == PermissionStatus.granted ||
          photosResult == PermissionStatus.granted;

      // If denied, show specific guidance
      if (!granted && mounted) {
        _showSpecificSettingsGuidance(
          'Gallery/Photos',
          'To select images from your gallery',
        );
      }

      return granted;
    }
    return true; // iOS handles permissions automatically
  }

  Future<bool> _requestCameraPermission() async {
    // Check if already granted
    if (await Permission.camera.isGranted) {
      return true;
    }

    // Show specific dialog for camera access
    bool shouldRequest = await _showSpecificPermissionDialog(
      'Camera Access Required',
      'To take photos of street lights, we need camera permission.',
      Icons.camera_alt,
    );

    if (!shouldRequest) return false;

    // Request permission
    final result = await Permission.camera.request();

    // If denied, show specific guidance
    if (result != PermissionStatus.granted && mounted) {
      _showSpecificSettingsGuidance(
        'Camera',
        'To take photos of street lights',
      );
    }

    return result == PermissionStatus.granted;
  }

  // Show specific permission dialog
  Future<bool> _showSpecificPermissionDialog(
    String title,
    String message,
    IconData icon,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              title: Row(
                children: [
                  Icon(icon, color: Color(0xFF667EEA), size: 28.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Tap "Allow" in the next dialog to enable this feature.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF667EEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Show specific settings guidance
  void _showSpecificSettingsGuidance(String permissionName, String purpose) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.orange, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Enable $permissionName',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$purpose, please enable $permissionName permission in Settings.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 15.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Steps to enable:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '1. Tap "Open Settings"\n2. Find "Permissions"\n3. Enable "$permissionName"\n4. Return to the app',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        return; // Permission denied, settings will open automatically
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Save image path to shared preferences
        await _saveImageToPreferences(pickedFile.path);

        // Upload to Firebase Storage
        await _uploadImageToFirebase();
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing gallery. Opening settings...'),
          backgroundColor: Colors.orange,
        ),
      );
      // Open settings if there's any error
      openAppSettings();
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Request camera permission
      if (!await _requestCameraPermission()) {
        return; // Permission denied, settings will open automatically
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Save image path to shared preferences
        await _saveImageToPreferences(pickedFile.path);

        // Upload to Firebase Storage
        await _uploadImageToFirebase();
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageToPreferences(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('street_light_image_path', imagePath);
      print('Image path saved to preferences: $imagePath');
    } catch (e) {
      print('Error saving image path to preferences: $e');
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    setState(() {
      _isImageUploading = true;
    });

    try {
      // Create a unique filename
      final String fileName =
          'street_light_${DateTime.now().millisecondsSinceEpoch}_${path.basename(_selectedImage!.path)}';

      // Create reference to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('street_lights')
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);

      // Wait for completion
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isImageUploading = false;
      });

      print('Image uploaded successfully: $downloadUrl');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Image uploaded successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isImageUploading = false;
      });

      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      'Select Image',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageOption(
                            icon: Icons.photo_library,
                            label: 'Gallery',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromGallery();
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildImageOption(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromCamera();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.sp, color: const Color(0xFF667EEA)),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Address normalization helper method
  Map<String, String> _normalizeAddress() {
    final address = _addressController.text.trim();
    final area = _areaController.text.trim();
    final ward = _wardController.text.trim();

    // Split address by commas and clean up
    List<String> addressParts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    List<String> areaParts = area
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    // Remove duplicates between address and area
    Set<String> uniqueParts = {};
    uniqueParts.addAll(addressParts);
    uniqueParts.addAll(areaParts);

    // Filter out common duplicates (case insensitive)
    List<String> finalParts = [];
    Set<String> addedLower = {};

    for (String part in uniqueParts) {
      String lowerPart = part.toLowerCase();
      if (!addedLower.contains(lowerPart)) {
        finalParts.add(part);
        addedLower.add(lowerPart);
      }
    }

    // Reconstruct normalized addresses
    String normalizedAddress = finalParts.isNotEmpty
        ? finalParts.first
        : address;
    String normalizedArea = finalParts.length > 1
        ? finalParts.sublist(1).join(', ')
        : area;

    return {
      'address': normalizedAddress,
      'area': normalizedArea,
      'ward': ward,
      'formatted': finalParts.join(', '),
    };
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

        // Normalize address to prevent duplicates
        final normalizedAddress = _normalizeAddress();

        // Prepare street light data
        final streetLightData = {
          'id': streetLightId,
          'name': _nameController.text.trim(),
          // store GSM identifier and human-readable street light number
          'phoneNumber': _phoneController.text.trim(),
          'streetLightNumber': _streetLightNumberController.text.trim(),
          'address': normalizedAddress['address']!,
          'area': normalizedAddress['area']!,
          'ward': normalizedAddress['ward']!,
          'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
          'status': _selectedStatus,
          'brightness': _brightness,
          'powerConsumption':
              double.tryParse(_powerConsumptionController.text.trim()) ?? 0.0,
          'isScheduled': _isScheduled,
          'schedule': {},
          'imageUrl': _uploadedImageUrl, // Add image URL if uploaded
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
          'createdByEmail': user.email,
          'isActive': true,
          // Additional metadata for better tracking
          'deviceInfo': {'platform': 'mobile', 'version': '1.0.0'},
          'coordinates': {
            'lat': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
            'lng': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
          },
          'fullAddress': {
            'street': normalizedAddress['address']!,
            'area': normalizedAddress['area']!,
            'ward': normalizedAddress['ward']!,
            'formatted': normalizedAddress['formatted']!,
          },
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

          // Try to extract area from address for Kerala locations
          if (address.isNotEmpty) {
            final addressParts = address.split(',');
            if (addressParts.isNotEmpty) {
              // Use the first part as area if not already filled
              if (_areaController.text.isEmpty && addressParts.length > 0) {
                _areaController.text = addressParts[0].trim();
              }
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.my_location, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Current location added! Please verify area and ward details.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 3),
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

                        // Image Upload Section
                        _buildSectionCard(
                          'Street Light Image',
                          Icons.camera_alt,
                          [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15.r),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                      children: [
                                        Container(
                                          height: 200.h,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              13.r,
                                            ),
                                            image: DecorationImage(
                                              image: FileImage(_selectedImage!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8.h,
                                          right: 8.w,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImage = null;
                                                _uploadedImageUrl = null;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: EdgeInsets.all(5),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_isImageUploading)
                                          Container(
                                            height: 200.h,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(13.r),
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF667EEA)),
                                                  ),
                                                  SizedBox(height: 10.h),
                                                  Text(
                                                    'Uploading...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: _showImagePickerDialog,
                                      child: Container(
                                        height: 150.h,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 50.sp,
                                              color: Color(0xFF667EEA),
                                            ),
                                            SizedBox(height: 10.h),
                                            Text(
                                              'Add Street Light Photo',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF667EEA),
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'Tap to select from gallery or camera',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 10.h),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                          0,
                        ),

                        SizedBox(height: 20.h),

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
                          // GSM identifier (modem SIM/ID)
                          _buildTextField(
                            controller: _phoneController,
                            label: 'GSM Number / ID',
                            icon: Icons.sim_card,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter GSM Number/ID';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),
                          // Human-readable street light number (pole marking)
                          _buildTextField(
                            controller: _streetLightNumberController,
                            label: 'Street Light Number',
                            icon: Icons.confirmation_number,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter street light number';
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
                            SizedBox(height: 20.h),

                            // Location action buttons
                            Row(
                              children: [
                                // Current Location Button
                                Expanded(
                                  child: Container(
                                    height: 48.h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading
                                            ? null
                                            : _getCurrentLocation,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.my_location,
                                              color: Colors.white,
                                              size: 18.sp,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              'Current Location',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          1,
                        ),

                        SizedBox(height: 20.h),

                        SizedBox(height: 20.h),

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
