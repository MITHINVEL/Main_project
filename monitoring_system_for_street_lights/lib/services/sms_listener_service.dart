import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitoring_system_for_street_lights/services/push_notification_service.dart';

/// SMS listener service that can work in mock mode or real platform mode.
/// To enable real SMS reception on Android, set enablePlatformListener = true
/// and ensure SMS permissions are granted.
class SmsListenerService {
  bool _listening = false;
  Timer? _smsTimer;
  DateTime? _lastChecked;

  /// If true, the service will attempt to use the platform SMS listener.
  /// Currently kept as mock-only due to Android namespace compatibility issues.
  final bool enablePlatformListener;

  SmsListenerService({this.enablePlatformListener = false});

  Future<void> start() async {
    if (_listening) return;
    _listening = true;

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
            'SMS Listener started (platform mode - real SMS polling active)',
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

      // Check if this number exists in street_lights collection using phoneNumber
      final coll = FirebaseFirestore.instance.collection('street_lights');
      QuerySnapshot<Map<String, dynamic>> qs = await coll
          .where('phoneNumber', isEqualTo: normalized)
          .get();

      List<QueryDocumentSnapshot<Map<String, dynamic>>> matches = [];

      if (qs.docs.isNotEmpty) {
        matches = qs.docs;
      } else {
        // Fallback: compare last N digits to support different formats
        final all = await coll.get();
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
        // Get the user who owns the first matching street light
        final firstMatch = matches.first;
        final streetLightData = firstMatch.data();
        final createdBy = streetLightData['createdBy'] ?? '';

        // Create a notification document with a stable id so clients can
        // deduplicate and use the doc id as notificationDocId for local display.
        final notificationsColl = FirebaseFirestore.instance.collection(
          'notifications',
        );
        final docRef = notificationsColl.doc();
        final docId = docRef.id;

        final notificationData = {
          'id': docId,
          'from': normalized,
          'body': message,
          'timestamp': FieldValue.serverTimestamp(),
          'source': source,
          'relatedLights': matches.map((d) => d.id).toList(),
          'isFixed': false,
          'createdBy': createdBy, // Associate with street light owner
        };

        await docRef.set(notificationData);

        // Show OS-level notification locally on this device so it mirrors the
        // in-app notification immediately (and mark it shown to avoid dupes).
        try {
          // try to include the first matched light's name for a nicer title
          String? firstLightName;
          if (matches.isNotEmpty) {
            firstLightName =
                (matches.first.data()['name'] ??
                        matches.first.data()['streetLightNumber'] ??
                        '')
                    .toString();
          }

          await PushNotificationService.displayLocalNotification(
            title: '📩 New Message',
            body: message,
            data: {
              'type': 'sms_alert',
              'from': normalized,
              'relatedLights': matches.map((d) => d.id).toList(),
              'notificationId': docId,
              'appName': 'StreetLight Monitor',
              'lightName': firstLightName ?? '',
            },
            notificationDocId: docId,
          );
        } catch (e) {
          print('Error showing local notification for SMS: $e');
        }

        print(
          'SMS notification created for user $createdBy (docId=$docId): $message',
        );
      } else {
        print('No matching street light for number: $normalized');
      }
    } catch (e) {
      print('SMS listener error: $e');
    }
  }

  String _lastNDigits(String s, int n) {
    final digits = s.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length <= n) return digits;
    return digits.substring(digits.length - n);
  }
}
