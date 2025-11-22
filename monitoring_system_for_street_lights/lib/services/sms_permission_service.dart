import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// SMS Permission Service
/// Handles all SMS permission requests with proper user dialog and explanation
class SmsPermissionService {
  static bool _isDialogShowing = false;

  /// Check and request SMS permission with user-friendly dialog
  static Future<bool> requestSmsPermission(BuildContext context) async {
    try {
      // Check current permission status
      final PermissionStatus status = await Permission.sms.status;
      
      print('📱 Current SMS permission status: $status');
      
      // If already granted, return true
      if (status.isGranted) {
        print('✅ SMS permission already granted');
        return true;
      }
      
      // If permanently denied, show settings dialog
      if (status.isPermanentlyDenied) {
        print('⚠️ SMS permission permanently denied');
        return await _showSettingsDialog(context);
      }
      
      // If not granted and not permanently denied, show explanation first
      if (!status.isGranted && !status.isPermanentlyDenied) {
        print('📱 SMS permission not granted, showing explanation...');
        
        // Show explanation dialog
        final bool shouldRequest = await _showPermissionExplanationDialog(context);
        
        if (!shouldRequest) {
          print('❌ User declined to grant SMS permission');
          return false;
        }
        
        // Request permission
        print('📱 Requesting SMS permission...');
        final PermissionStatus result = await Permission.sms.request();
        print('📱 Permission request result: $result');
        
        if (result.isGranted) {
          print('✅ SMS permission granted successfully');
          return true;
        } else if (result.isPermanentlyDenied) {
          print('⚠️ SMS permission permanently denied after request');
          return await _showSettingsDialog(context);
        } else {
          print('❌ SMS permission denied');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Show explanation dialog before requesting permission
  static Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    try {
      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sms, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SMS Permission Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📱 SMS Permission Requirements:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• To detect SMS messages from street lights\n'
                  '• To receive notifications even when app is closed\n'
                  '• For real-time alerts and emergency notifications\n'
                  '• For automatic notification relay to team members',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your SMS data will be secure. We will not read your personal messages.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Allow SMS Permission',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } finally {
      _isDialogShowing = false;
    }
  }

  /// Show settings dialog when permission is permanently denied
  static Future<bool> _showSettingsDialog(BuildContext context) async {
    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    try {
      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enable SMS Permission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚙️ Manual Permission Setup:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 Please enable manually in Settings:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Click "Open Settings" button\n'
                        '2. Go to "Permissions" → "SMS"\n'
                        '3. Toggle "Allow" option ON\n'
                        '4. Press back button to return to app',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ Street light notifications will not work without this permission.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                // Open app settings
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } finally {
      _isDialogShowing = false;
    }
  }

  /// Quick permission status check (without UI)
  static Future<bool> isPermissionGranted() async {
    try {
      final status = await Permission.sms.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error checking SMS permission: $e');
      return false;
    }
  }

  /// Show simple status message
  static void showPermissionStatus(BuildContext context) async {
    final isGranted = await isPermissionGranted();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.error,
                color: isGranted ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isGranted 
                  ? '✅ SMS Permission Granted'
                  : '❌ SMS Permission Required',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: isGranted ? Colors.green.shade600 : Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}