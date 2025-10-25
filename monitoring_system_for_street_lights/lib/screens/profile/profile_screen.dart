import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _profileController;
  late AnimationController _backgroundController;
  final UserService _userService = UserService();
  User? _currentUser;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _profileController.forward();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      try {
        final userProfile = await _userService.getUserProfile(
          _currentUser!.uid,
        );

        if (userProfile != null && mounted) {
          setState(() {
            _userProfile = userProfile;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  String _getProviderInfo() {
    if (_userProfile?.provider != null) {
      switch (_userProfile!.provider) {
        case 'google.com':
          return 'Google Account';
        case 'password':
        case 'email':
          return 'Email Account';
        default:
          return 'Authenticated User';
      }
    } else if (_currentUser?.providerData.isNotEmpty == true) {
      final provider = _currentUser!.providerData.first.providerId;
      switch (provider) {
        case 'google.com':
          return 'Google Account';
        case 'password':
          return 'Email Account';
        default:
          return 'Authenticated User';
      }
    }
    return 'System User';
  }

  String _getUserDisplayName() {
    if (_userProfile?.name != null && _userProfile!.name.isNotEmpty) {
      return _userProfile!.name;
    } else if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!.split('@').first;
    } else {
      return 'User';
    }
  }

  String _getUserEmail() {
    if (_userProfile?.email != null) {
      return _userProfile!.email;
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!;
    } else {
      return 'No email available';
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog with animation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.logout,
                  color: const Color(0xFFE53E3E),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
      },
    );

    if (result == true && mounted) {
      // Show loading animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      );

      try {
        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Sign out from Google Sign In
        await GoogleSignIn().signOut();

        // Simulate logout process
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(-1.0, 0), end: Offset.zero),
                        ),
                        child: child,
                      ),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show edit options bottom sheet
  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 20.h),

            // Edit Profile Image
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
              ),
              title: Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              subtitle: Text(
                'Update your profile picture',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF718096),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImagePickerOptions();
              },
            ),

            // Edit Name
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: const Color(0xFF48BB78),
                  size: 20.sp,
                ),
              ),
              title: Text(
                'Edit Name',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              subtitle: Text(
                'Change your display name',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF718096),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog();
              },
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ).animate().slideY(begin: 1, duration: 300.ms),
    );
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Select Photo',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 20.h),

            // Camera Option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: const Color(0xFF667EEA),
                  size: 20.sp,
                ),
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              subtitle: Text(
                'Use camera to take a new photo',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF718096),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            // Gallery Option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: const Color(0xFF48BB78),
                  size: 20.sp,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              subtitle: Text(
                'Select from your photo library',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF718096),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ).animate().slideY(begin: 1, duration: 300.ms),
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF667EEA),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Updating profile photo...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          ),
        );

        // Upload image and update profile
        await _updateProfileImage(File(pickedFile.path));

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: const Color(0xFF48BB78),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile photo: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  // Update profile image in Firebase
  Future<void> _updateProfileImage(File imageFile) async {
    if (_currentUser == null) return;

    try {
      final uid = _currentUser!.uid;

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth profile (photoURL)
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
      // Ensure auth user is reloaded
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser;
      });

      // Update Firestore user document
      await _userService.updateUserProfile(
        uid: uid,
        updates: {'photoUrl': downloadUrl},
      );

      // Refresh user data after update
      await _fetchUserData();
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  // Show edit name dialog
  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = _getUserDisplayName();

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
                color: const Color(0xFF48BB78).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFF48BB78),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Edit Name',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(
                  color: const Color(0xFF718096),
                  fontSize: 14.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF48BB78)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
              ),
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF48BB78), Color(0xFF38A169)],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: TextButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateUserName(nameController.text.trim());
                }
              },
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  // Update user name in Firebase
  Future<void> _updateUserName(String newName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF48BB78)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Updating name...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      );

      if (_currentUser != null) {
        final uid = _currentUser!.uid;

        // Update Firebase Auth display name
        await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
        // Ensure auth user is reloaded
        await FirebaseAuth.instance.currentUser?.reload();
        setState(() {
          _currentUser = FirebaseAuth.instance.currentUser;
        });

        // Update Firestore user document
        await _userService.updateUserProfile(
          uid: uid,
          updates: {'name': newName},
        );

        // Refresh user data after update
        await _fetchUserData();
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name updated successfully!'),
            backgroundColor: const Color(0xFF48BB78),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating name: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        // Make AppBar visually distinct with a gradient and rounded bottom
        flexibleSpace: Container(
          height: 300.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
          ),
        ),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: _showEditOptions,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 26.sp),
              ),
            ),
          ),
        ],
      ),
      body: CustomPaint(
        painter: ProfileBackgroundPainter(_backgroundController.value),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // Profile Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Stack(
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(50.r),
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
                            child:
                                (_userProfile?.photoUrl != null ||
                                    _currentUser?.photoURL != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50.r),
                                    child: Image.network(
                                      _userProfile?.photoUrl ??
                                          _currentUser!.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 50.sp,
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50.sp,
                                  ),
                          ).animate().scale(
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImagePickerOptions,
                              child:
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF48BB78),
                                          Color(0xFF38A169),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ).animate().scale(
                                    delay: 600.ms,
                                    duration: 600.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // User Info
                      Text(
                        _getUserDisplayName(),
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        delay: 400.ms,
                        duration: 600.ms,
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        _getUserEmail(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF718096),
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        delay: 500.ms,
                        duration: 600.ms,
                      ),

                      SizedBox(height: 8.h),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _getProviderInfo(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().scale(delay: 600.ms, duration: 600.ms),
                    ],
                  ),
                ).animate().slideY(begin: 0.5, delay: 200.ms, duration: 800.ms),

                SizedBox(height: 20.h),

                // Menu Options
                _buildMenuSection(),

                SizedBox(height: 20.h),

                // Logout Button
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Logout',
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
                ).animate().slideY(
                  begin: 0.3,
                  delay: 1000.ms,
                  duration: 600.ms,
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
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
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
          ),
        ],
      ),
    ).animate().scale(
      delay: (400 + index * 100).ms,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'subtitle': 'Manage your alerts and reminders',
        'route': '/profile/notifications',
      },
      {
        'icon': Icons.security,
        'title': 'Privacy & Security',
        'subtitle': 'Account security settings',
        'route': '/profile/privacy',
      },
      {
        'icon': Icons.help,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'route': '/profile/help',
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'subtitle': 'App version and information',
        'route': '/profile/about',
      },
    ];

    return Container(
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
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;

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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, item['route'] as String);
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFF667EEA),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              item['subtitle'] as String,
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
            ),
          ).animate().slideX(
            begin: 0.3,
            delay: (600 + index * 100).ms,
            duration: 600.ms,
          );
        }).toList(),
      ),
    );
  }
}

// Custom Painter for Profile Background
class ProfileBackgroundPainter extends CustomPainter {
  final double animationValue;

  ProfileBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gentle floating shapes
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        (size.width * 0.2 * i) + (30 * (animationValue + i * 0.3).remainder(1)),
        (size.height * 0.15) +
            (20 * (animationValue * 0.4 + i * 0.2).remainder(1)),
      );

      paint.color = const Color(0xFF667EEA).withOpacity(0.03);
      canvas.drawCircle(offset, 12 + (i * 2), paint);
    }

    // Additional subtle elements
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        size.width -
            (size.width * 0.3 * i) -
            (50 * animationValue.remainder(1)),
        (size.height * 0.8) +
            (25 * (animationValue * 0.3 + i * 0.4).remainder(1)),
      );

      paint.color = const Color(0xFF764BA2).withOpacity(0.02);
      canvas.drawCircle(offset, 8 + (i * 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
