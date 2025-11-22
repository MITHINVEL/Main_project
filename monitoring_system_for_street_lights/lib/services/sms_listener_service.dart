import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitoring_system_for_street_lights/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SMS listener service that can work in mock mode or real platform mode.
/// To enable real SMS reception on Android, set enablePlatformListener = true
/// and ensure SMS permissions are granted.
/// 
/// RELAY MODE: If enabled, this device acts as a central SMS relay that
/// receives SMS from GSM modules and broadcasts notifications to all users
/// who have registered that specific GSM number.
class SmsListenerService {
  bool _listening = false;
  Timer? _smsTimer;
  DateTime? _lastChecked;

  /// If true, the service will attempt to use the platform SMS listener.
  /// Currently kept as mock-only due to Android namespace compatibility issues.
  final bool enablePlatformListener;
  
  /// If true, this device acts as a central relay for GSM SMS
  bool _relayMode = false;

  SmsListenerService({this.enablePlatformListener = false});

  Future<void> start() async {
    if (_listening) return;
    _listening = true;
    
    // Check if relay mode is enabled
    final prefs = await SharedPreferences.getInstance();
    _relayMode = prefs.getBool('sms_relay_mode') ?? false;

    if (enablePlatformListener) {
      try {
        // Request SMS permissions
        final smsPermission = await Permission.sms.request();

        if (smsPermission.isGranted) {
          _lastChecked = DateTime.now().subtract(const Duration(minutes: 5));

          // Start polling for new SMS every 10 seconds
          _smsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
            _checkForNewSMS();
          });

          print(
            'SMS Listener started (${_relayMode ? "RELAY" : "platform"} mode - real SMS polling active)',
          );
        } else {
          print('SMS permission denied - falling back to mock mode');
        }
      } catch (e) {
        print('Error starting SMS listener: $e - falling back to mock mode');
      }
    } else {
      print('SMS Listener started (mock mode)');
    }
  }

  Future<void> stop() async {
    _listening = false;
    _smsTimer?.cancel();
    _smsTimer = null;
    print('SMS Listener stopped');
  }

  /// Check for new SMS messages since last check
  Future<void> _checkForNewSMS() async {
    try {
      final SmsQuery query = SmsQuery();
      final List<SmsMessage> messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 20, // Get last 20 messages
      );

      final now = DateTime.now();
      final checkTime =
          _lastChecked ?? now.subtract(const Duration(minutes: 5));

      for (final message in messages) {
        // Check if message is newer than last check
        if (message.date != null && message.date!.isAfter(checkTime)) {
          final from = message.address ?? '';
          final body = message.body ?? '';

          print('Found new SMS from $from: $body');
          await _processIncomingSms(from, body, source: 'real_sms');
        }
      }

      _lastChecked = now;
    } catch (e) {
      print('Error checking SMS: $e');
    }
  }

  /// Mock method to simulate receiving an SMS from a GSM module.
  Future<void> simulateIncomingSms({
    required String fromNumber,
    required String message,
  }) async {
    await _processIncomingSms(fromNumber, message, source: 'sms_mock');
  }

  Future<void> _processIncomingSms(
    String fromNumber,
    String message, {
    required String source,
  }) async {
    try {
      // Normalize the number (keep + and digits)
      final normalized = fromNumber.replaceAll(RegExp(r"[^0-9+]"), '');

      // In RELAY MODE: Create notifications for ALL users who have this GSM number
      // In NORMAL MODE: Only create for current user's street lights
      final coll = FirebaseFirestore.instance.collection('street_lights');
      
      QuerySnapshot<Map<String, dynamic>> qs;
      
      if (_relayMode) {
        // RELAY MODE: Get ALL street lights with this phone number (any user)
        print('🔄 RELAY MODE: Checking all users for GSM number: $normalized');
        qs = await coll.where('phoneNumber', isEqualTo: normalized).get();
      } else {
        // NORMAL MODE: Only current user's street lights
        qs = await coll
            .where('phoneNumber', isEqualTo: normalized)
            .get();
      }

      List<QueryDocumentSnapshot<Map<String, dynamic>>> matches = [];

      if (qs.docs.isNotEmpty) {
        matches = qs.docs;
      } else {
        // Fallback: compare last N digits to support different formats
        final all = _relayMode 
            ? await coll.get()  // All users in relay mode
            : await coll.get(); // Should filter by userId in normal mode
        final normLast = _lastNDigits(normalized, 9);
        for (var doc in all.docs) {
          final smsField = (doc.data()['phoneNumber'] ?? '').toString();
          final smsNorm = smsField.replaceAll(RegExp(r"[^0-9+]"), '');
          if (smsNorm.isEmpty) continue;
          if (_lastNDigits(smsNorm, 9) == normLast) {
            matches.add(doc);
          }
        }
      }

      if (matches.isNotEmpty) {
        // In RELAY MODE: Create notification for EACH unique user
        // In NORMAL MODE: Create one notification for current user
        
        if (_relayMode) {
          // Group by userId to avoid duplicates
          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> userGroups = {};
          for (var doc in matches) {
            final userId = doc.data()['createdBy'] ?? doc.data()['userId'] ?? '';
            if (userId.isNotEmpty) {
              userGroups[userId] ??= [];
              userGroups[userId]!.add(doc);
            }
          }
          
          print('🔄 RELAY MODE: Creating notifications for ${userGroups.length} users');
          
          // Create notification for each user
          for (var entry in userGroups.entries) {
            final userId = entry.key;
            final userLights = entry.value;
            await _createNotificationForUser(
              userId: userId,
              fromNumber: normalized,
              message: message,
              source: '$source-relay',
              matchedLights: userLights,
            );
          }
        } else {
          // NORMAL MODE: Single notification
          final firstMatch = matches.first;
          final streetLightData = firstMatch.data();
          final createdBy = streetLightData['createdBy'] ?? '';
          
          await _createNotificationForUser(
            userId: createdBy,
            fromNumber: normalized,
            message: message,
            source: source,
            matchedLights: matches,
          );
        }
      } else {
        print('No matching street light for number: $normalized');
      }
    } catch (e) {
      print('SMS listener error: $e');
    }
  }
  
  Future<void> _createNotificationForUser({
    required String userId,
    required String fromNumber,
    required String message,
    required String source,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> matchedLights,
  }) async {
    try {
      final notificationsColl = FirebaseFirestore.instance.collection('notifications');
      final docRef = notificationsColl.doc();
      final docId = docRef.id;

      // Get first matched street light details for display
      String lightName = '';
      String lightLocation = '';
      if (matchedLights.isNotEmpty) {
        final firstLight = matchedLights.first.data();
        lightName =
            (firstLight['name'] ??
                    firstLight['streetLightNumber'] ??
                    firstLight['lightNumber'] ??
                    '')
                .toString();

        // Get location/address
        final fullAddress = firstLight['fullAddress'];
        if (fullAddress != null && fullAddress['formatted'] != null) {
          lightLocation = fullAddress['formatted'].toString();
        } else {
          lightLocation = (firstLight['address'] ?? '').toString();
        }
      }

      final notificationData = {
        'id': docId,
        'from': fromNumber,
        'body': message,
        'timestamp': FieldValue.serverTimestamp(),
        'source': source,
        'relatedLights': matchedLights.map((d) => d.id).toList(),
        'isFixed': false,
        'createdBy': userId,
        'userId': userId,
        // Add street light details directly to notification
        'lightName': lightName,
        'name': lightName,
        'title': lightName.isNotEmpty ? lightName : 'Street Light Alert',
        'location': lightLocation,
        'address': lightLocation,
      };

      await docRef.set(notificationData);

      // Show OS-level notification locally on this device
      try {
        await PushNotificationService.displayLocalNotification(
          title: '📩 New Message',
          body: message,
          data: {
            'type': 'sms_alert',
            'from': fromNumber,
            'relatedLights': matchedLights.map((d) => d.id).toList(),
            'notificationId': docId,
            'appName': 'StreetLight Monitor',
            'lightName': lightName,
          },
          notificationDocId: docId,
        );
      } catch (e) {
        print('Error showing local notification for SMS: $e');
      }

      print('✅ SMS notification created for user $userId (docId=$docId): $message');
    } catch (e) {
      print('❌ Error creating notification for user $userId: $e');
    }
  }

  String _lastNDigits(String s, int n) {
    final digits = s.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length <= n) return digits;
    return digits.substring(digits.length - n);
  }
}
