import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

/// Street Light Monitoring Service
/// Monitors street lights for status changes and sends real-time notifications
class StreetLightMonitoringService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _monitoringSubscription;
  static Map<String, Map<String, dynamic>> _lastKnownStatus = {};
  static bool _isMonitoring = false;

  /// Start monitoring street lights for the current user
  static Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🔍 Starting street light monitoring for user: ${user.uid}');

      // Initialize push notifications
      await PushNotificationService.initialize();

      // Start monitoring street lights collection
      _monitoringSubscription = _firestore
          .collection('street_lights')
          .where('createdBy', isEqualTo: user.uid)
          .snapshots()
          .listen(
            _handleStreetLightChanges,
            onError: (error) {
              print('❌ Monitoring error: $error');
            },
          );

      _isMonitoring = true;
      print('✅ Street light monitoring started');

      // Send welcome notification
      await _sendWelcomeNotification();
    } catch (e) {
      print('❌ Error starting monitoring: $e');
    }
  }

  /// Stop monitoring
  static Future<void> stopMonitoring() async {
    try {
      await _monitoringSubscription?.cancel();
      _monitoringSubscription = null;
      _isMonitoring = false;
      _lastKnownStatus.clear();

      print('🛑 Street light monitoring stopped');
    } catch (e) {
      print('❌ Error stopping monitoring: $e');
    }
  }

  /// Handle street light changes and send notifications
  static Future<void> _handleStreetLightChanges(QuerySnapshot snapshot) async {
    try {
      for (final docChange in snapshot.docChanges) {
        final lightData = docChange.doc.data() as Map<String, dynamic>?;
        if (lightData == null) continue;

        final lightId = docChange.doc.id;
        final lightName = lightData['name'] ?? 'Street Light';

        switch (docChange.type) {
          case DocumentChangeType.added:
            await _handleLightAdded(lightId, lightName, lightData);
            break;

          case DocumentChangeType.modified:
            await _handleLightModified(lightId, lightName, lightData);
            break;

          case DocumentChangeType.removed:
            await _handleLightRemoved(lightId, lightName);
            break;
        }

        // Update last known status
        _lastKnownStatus[lightId] = Map<String, dynamic>.from(lightData);
      }
    } catch (e) {
      print('❌ Error handling street light changes: $e');
    }
  }

  /// Handle new street light added
  static Future<void> _handleLightAdded(
    String lightId,
    String lightName,
    Map<String, dynamic> lightData,
  ) async {
    try {
      await _sendNotification(
        title: '💡 New Street Light Added',
        body: '$lightName has been added to your monitoring system',
        data: {
          'type': 'light_added',
          'lightId': lightId,
          'lightName': lightName,
        },
      );

      print('📱 Sent notification: Light added - $lightName');
    } catch (e) {
      print('❌ Error handling light added: $e');
    }
  }

  /// Handle street light status changes
  static Future<void> _handleLightModified(
    String lightId,
    String lightName,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final lastStatus = _lastKnownStatus[lightId];
      if (lastStatus == null) return;

      // Check for status changes
      await _checkStatusChange(lightId, lightName, lastStatus, currentData);

      // Check for battery level changes
      await _checkBatteryLevel(lightId, lightName, lastStatus, currentData);

      // Check for maintenance alerts
      await _checkMaintenanceAlerts(
        lightId,
        lightName,
        lastStatus,
        currentData,
      );
    } catch (e) {
      print('❌ Error handling light modified: $e');
    }
  }

  /// Check for status changes (on/off)
  static Future<void> _checkStatusChange(
    String lightId,
    String lightName,
    Map<String, dynamic> lastStatus,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final lastState = lastStatus['status'] ?? lastStatus['isActive'];
      final currentState = currentData['status'] ?? currentData['isActive'];

      if (lastState != currentState) {
        final isOn = currentState == 'on' || currentState == true;

        await _sendNotification(
          title: isOn ? '💡 Light Turned ON' : '🔴 Light Turned OFF',
          body: '$lightName is now ${isOn ? 'active' : 'inactive'}',
          data: {
            'type': 'status_change',
            'lightId': lightId,
            'lightName': lightName,
            'status': isOn ? 'on' : 'off',
          },
        );

        print(
          '📱 Sent notification: Status change - $lightName ($currentState)',
        );
      }
    } catch (e) {
      print('❌ Error checking status change: $e');
    }
  }

  /// Check for battery level alerts
  static Future<void> _checkBatteryLevel(
    String lightId,
    String lightName,
    Map<String, dynamic> lastStatus,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final currentBattery = (currentData['batteryLevel'] ?? 100.0).toDouble();
      final lastBattery = (lastStatus['batteryLevel'] ?? 100.0).toDouble();

      // Alert for low battery (below 20%)
      if (currentBattery <= 20 && lastBattery > 20) {
        await _sendNotification(
          title: '🔋 Low Battery Alert',
          body: '$lightName battery is at ${currentBattery.toInt()}%',
          data: {
            'type': 'low_battery',
            'lightId': lightId,
            'lightName': lightName,
            'batteryLevel': currentBattery.toString(),
            'priority': 'high',
          },
        );

        print(
          '📱 Sent notification: Low battery - $lightName (${currentBattery}%)',
        );
      }

      // Alert for critical battery (below 10%)
      if (currentBattery <= 10 && lastBattery > 10) {
        await _sendNotification(
          title: '⚠️ CRITICAL: Battery Almost Empty',
          body:
              '$lightName battery is critically low at ${currentBattery.toInt()}%',
          data: {
            'type': 'critical_battery',
            'lightId': lightId,
            'lightName': lightName,
            'batteryLevel': currentBattery.toString(),
            'priority': 'critical',
          },
        );

        print(
          '📱 Sent notification: Critical battery - $lightName (${currentBattery}%)',
        );
      }
    } catch (e) {
      print('❌ Error checking battery level: $e');
    }
  }

  /// Check for maintenance alerts
  static Future<void> _checkMaintenanceAlerts(
    String lightId,
    String lightName,
    Map<String, dynamic> lastStatus,
    Map<String, dynamic> currentData,
  ) async {
    try {
      // Check for offline status (last update > 30 minutes)
      final lastUpdated = currentData['lastUpdated'];
      if (lastUpdated != null) {
        DateTime lastUpdateTime;
        if (lastUpdated is Timestamp) {
          lastUpdateTime = lastUpdated.toDate();
        } else {
          lastUpdateTime = DateTime.parse(lastUpdated.toString());
        }

        final timeDiff = DateTime.now().difference(lastUpdateTime);
        final wasOnline = _isOnline(lastStatus['lastUpdated']);
        final isCurrentlyOnline = timeDiff.inMinutes < 30;

        if (wasOnline && !isCurrentlyOnline) {
          await _sendNotification(
            title: '📡 Connection Lost',
            body:
                '$lightName has gone offline. Last seen ${_formatTimeDiff(timeDiff)} ago',
            data: {
              'type': 'connection_lost',
              'lightId': lightId,
              'lightName': lightName,
              'offline_duration': timeDiff.inMinutes.toString(),
            },
          );

          print('📱 Sent notification: Connection lost - $lightName');
        }
      }

      // Check for efficiency drops
      final currentEfficiency = (currentData['solarEfficiency'] ?? 100.0)
          .toDouble();
      final lastEfficiency = (lastStatus['solarEfficiency'] ?? 100.0)
          .toDouble();

      if (currentEfficiency < 70 && lastEfficiency >= 70) {
        await _sendNotification(
          title: '⚡ Low Solar Efficiency',
          body:
              '$lightName solar efficiency dropped to ${currentEfficiency.toInt()}%',
          data: {
            'type': 'low_efficiency',
            'lightId': lightId,
            'lightName': lightName,
            'efficiency': currentEfficiency.toString(),
          },
        );

        print(
          '📱 Sent notification: Low efficiency - $lightName (${currentEfficiency}%)',
        );
      }
    } catch (e) {
      print('❌ Error checking maintenance alerts: $e');
    }
  }

  /// Handle street light removed
  static Future<void> _handleLightRemoved(
    String lightId,
    String lightName,
  ) async {
    try {
      await _sendNotification(
        title: '🗑️ Street Light Removed',
        body: '$lightName has been removed from monitoring',
        data: {
          'type': 'light_removed',
          'lightId': lightId,
          'lightName': lightName,
        },
      );

      // Remove from last known status
      _lastKnownStatus.remove(lightId);

      print('📱 Sent notification: Light removed - $lightName');
    } catch (e) {
      print('❌ Error handling light removed: $e');
    }
  }

  /// Send notification helper
  static Future<void> _sendNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Display a real local notification on this device
      await PushNotificationService.displayLocalNotification(
        title: title,
        body: body,
        data: data,
      );

      // Save to Firestore for history
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'title': title,
          'body': body,
          'data': data,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': data['type'] ?? 'general',
          'priority': data['priority'] ?? 'normal',
          // Include origin token so other devices can detect source and avoid
          // showing duplicate notifications for the same device.
          'createdByToken': PushNotificationService.fcmToken,
        });
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Send welcome notification
  static Future<void> _sendWelcomeNotification() async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Delay for better UX

      await _sendNotification(
        title: '🎉 Real-Time Monitoring Active',
        body:
            'Your street lights are now being monitored 24/7. You\'ll receive instant alerts!',
        data: {'type': 'welcome', 'priority': 'normal'},
      );

      print('📱 Sent welcome notification');
    } catch (e) {
      print('❌ Error sending welcome notification: $e');
    }
  }

  /// Simulate street light events (for testing)
  static Future<void> simulateEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🎭 Simulating street light events...');

      // Get user's street lights
      final lights = await _firestore
          .collection('street_lights')
          .where('createdBy', isEqualTo: user.uid)
          .limit(3)
          .get();

      if (lights.docs.isEmpty) return;

      final random = math.Random();

      // Simulate different events
      for (int i = 0; i < lights.docs.length; i++) {
        final doc = lights.docs[i];
        final lightName = doc.data()['name'] ?? 'Test Light ${i + 1}';

        await Future.delayed(Duration(seconds: i * 2));

        switch (i % 4) {
          case 0:
            // Status change
            await _sendNotification(
              title: '💡 Light Status Changed',
              body:
                  '$lightName has been turned ${random.nextBool() ? 'ON' : 'OFF'}',
              data: {
                'type': 'status_change',
                'lightId': doc.id,
                'lightName': lightName,
              },
            );
            break;

          case 1:
            // Low battery
            final batteryLevel = 15 + random.nextInt(10);
            await _sendNotification(
              title: '🔋 Low Battery Alert',
              body: '$lightName battery is at $batteryLevel%',
              data: {
                'type': 'low_battery',
                'lightId': doc.id,
                'lightName': lightName,
                'batteryLevel': batteryLevel.toString(),
                'priority': 'high',
              },
            );
            break;

          case 2:
            // Connection lost
            await _sendNotification(
              title: '📡 Connection Lost',
              body: '$lightName has gone offline',
              data: {
                'type': 'connection_lost',
                'lightId': doc.id,
                'lightName': lightName,
              },
            );
            break;

          case 3:
            // Maintenance needed
            await _sendNotification(
              title: '🔧 Maintenance Required',
              body:
                  '$lightName needs attention - solar efficiency dropped to 65%',
              data: {
                'type': 'maintenance_required',
                'lightId': doc.id,
                'lightName': lightName,
                'priority': 'medium',
              },
            );
            break;
        }
      }

      print('✅ Event simulation completed');
    } catch (e) {
      print('❌ Error simulating events: $e');
    }
  }

  /// Helper methods
  static bool _isOnline(dynamic lastUpdated) {
    if (lastUpdated == null) return false;

    try {
      DateTime lastUpdateTime;
      if (lastUpdated is Timestamp) {
        lastUpdateTime = lastUpdated.toDate();
      } else {
        lastUpdateTime = DateTime.parse(lastUpdated.toString());
      }

      return DateTime.now().difference(lastUpdateTime).inMinutes < 30;
    } catch (e) {
      return false;
    }
  }

  static String _formatTimeDiff(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Getters
  static bool get isMonitoring => _isMonitoring;
  static int get monitoredLightsCount => _lastKnownStatus.length;
}
