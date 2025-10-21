import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PushNotificationService
///
/// Responsibilities:
/// - Initialize FCM and flutter_local_notifications
/// - Persist which Firestore notification document ids have been shown on
///   this device (to avoid re-showing after app restart)
/// - Show local (OS) notifications for incoming RemoteMessage objects,
///   skipping those that we've already shown.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _kShownNotificationsKey = 'shown_notifications_v1';
  static final Set<String> _shownNotificationDocIds = <String>{};
  static String? _fcmToken;
  static bool _initialized = false;

  /// Call once at app startup (before listening to Firestore snapshots that
  /// might trigger local notifications).
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadShownNotificationIds();
    await _initializeLocalNotifications();
    await _initializeFCM();
    _setupMessageHandlers();
    await _getFCMToken();
    await _subscribeToTopics();
  }

  /// Initialize local notifications plugin and create channel on Android.
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'street_lights_channel',
        'Street Lights Notifications',
        description: 'Real-time notifications for street light monitoring',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  /// Request permissions and configure presentation options for FCM.
  static Future<void> _initializeFCM() async {
    try {
      await _firebaseMessaging.setAutoInitEnabled(true);

      // iOS presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request Android 13+ permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        print('📱 System Notification Permission: $status');
      }

      print('✅ FCM initialized');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Load persisted list of shown notification ids from SharedPreferences.
  static Future<void> _loadShownNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kShownNotificationsKey) ?? <String>[];
      _shownNotificationDocIds.clear();
      _shownNotificationDocIds.addAll(list);
      print(
        '✅ Loaded ${_shownNotificationDocIds.length} shown notification ids',
      );
    } catch (e) {
      print('❌ Error loading shown notification ids: $e');
    }
  }

  /// Persist shown notification ids to SharedPreferences.
  static Future<void> _persistShownNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kShownNotificationsKey,
        _shownNotificationDocIds.toList(),
      );
    } catch (e) {
      print('❌ Error persisting shown notification ids: $e');
    }
  }

  /// Mark a Firestore notification document id as shown on this device and
  /// persist the information so it is not shown again after restart.
  static Future<void> markNotificationAsShown(String notificationDocId) async {
    if (notificationDocId.isEmpty) return;
    _shownNotificationDocIds.add(notificationDocId);
    await _persistShownNotificationIds();
  }

  /// Check whether this device has already shown the given Firestore
  /// notification document id as an OS-level notification.
  static bool hasShownNotification(String notificationDocId) {
    if (notificationDocId.isEmpty) return false;
    return _shownNotificationDocIds.contains(notificationDocId);
  }

  /// Get FCM token and save to Firestore for the current user (if present).
  static Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenToFirestore(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static void _setupMessageHandlers() {
    try {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      _firebaseMessaging.getInitialMessage().then((message) {
        if (message != null) {
          _handleBackgroundMessageTap(message);
        }
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      print('✅ Message handlers setup complete');
    } catch (e) {
      print('❌ Error setting up message handlers: $e');
    }
  }

  /// Handle messages when app is in foreground.
  /// We show a local notification for new messages unless the message maps
  /// to a Firestore doc id we've already shown on this device.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('🔔 Foreground message received: ${message.data}');

      final data = Map<String, dynamic>.from(message.data);
      final docId =
          (data['notificationId'] ?? data['notification_id'] ?? data['docId'])
              ?.toString();

      if (docId != null && hasShownNotification(docId)) {
        print('Skipping foreground display; already shown doc $docId');
      } else {
        await _showLocalNotification(message);
      }

      // Persist into Firestore notifications collection for in-app listing.
      await _saveNotificationToFirestore(message);
    } catch (e) {
      print('❌ Error handling foreground message: $e');
    }
  }

  /// Handle notification taps (background/terminated)
  static Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    try {
      print('🔔 Background message tapped: ${message.data}');
      await _handleNotificationNavigation(
        Map<String, dynamic>.from(message.data),
      );
    } catch (e) {
      print('❌ Error handling background message tap: $e');
    }
  }

  /// Show local notification for the incoming RemoteMessage.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final data = Map<String, dynamic>.from(message.data);
      final docId =
          (data['notificationId'] ?? data['notification_id'] ?? data['docId'])
              ?.toString();

      if (docId != null && hasShownNotification(docId)) {
        print('Skipping already-shown notification for doc $docId');
        return;
      }

      // Prefer structured title: include appName and lightName when available
      final appName = (data['appName'] ?? data['app_name'])?.toString();
      final lightName =
          (data['lightName'] ?? data['light_name'] ?? data['name'])?.toString();
      final remoteTitle =
          message.notification?.title ?? data['title']?.toString();
      final remoteBody =
          message.notification?.body ?? data['body']?.toString() ?? '';

      String computedTitle;
      if ((appName != null && appName.isNotEmpty) ||
          (lightName != null && lightName.isNotEmpty)) {
        final parts = <String>[];
        if (appName != null && appName.isNotEmpty) parts.add(appName);
        if (lightName != null && lightName.isNotEmpty) parts.add(lightName);
        if (remoteTitle != null &&
            remoteTitle.isNotEmpty &&
            !parts.contains(remoteTitle))
          parts.add(remoteTitle);
        computedTitle = parts.join(' — ');
      } else {
        computedTitle = remoteTitle ?? 'Street Light Alert';
      }

      final computedBody = remoteBody;

      final androidDetails = AndroidNotificationDetails(
        'street_lights_channel',
        'Street Lights Notifications',
        channelDescription:
            'Real-time notifications for street light monitoring',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = docId != null
          ? (docId.hashCode & 0x7fffffff)
          : (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      await _localNotifications.show(
        notificationId,
        computedTitle,
        computedBody,
        notificationDetails,
        payload: jsonEncode(data),
      );

      if (docId != null) await markNotificationAsShown(docId);

      print('✅ Local notification shown (id=$notificationId)');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap callback from flutter_local_notifications
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload == null) return;
      final data = jsonDecode(response.payload!);
      _handleNotificationNavigation(Map<String, dynamic>.from(data));
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Save incoming notification into Firestore `notifications` collection
  /// for in-app display. If the RemoteMessage contains a Firestore document
  /// id in the payload, prefer that id to avoid duplicates.
  static Future<void> _saveNotificationToFirestore(
    RemoteMessage message,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = Map<String, dynamic>.from(message.data);
      final docId =
          (data['notificationId'] ?? data['notification_id'] ?? data['docId'])
              ?.toString();

      final docData = <String, dynamic>{
        'userId': user.uid,
        'title': message.notification?.title ?? data['title'],
        'body': message.notification?.body ?? data['body'],
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': data['type'] ?? 'general',
      };

      if (docId != null) {
        // If we already have a server-side document id, attempt to set it
        // (merge) so server and client agree on the same doc.
        await _firestore
            .collection('notifications')
            .doc(docId)
            .set(docData, SetOptions(merge: true));
      } else {
        await _firestore.collection('notifications').add(docData);
      }

      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Navigation handler - currently prints; integrate with navigator if you
  /// have a global navigator key and want to route users to specific screens.
  static Future<void> _handleNotificationNavigation(
    Map<String, dynamic> data,
  ) async {
    try {
      final type = data['type'];
      final lightId = data['lightId'] ?? data['light_id'];
      print(
        '🧭 Notification navigation requested - type: $type, lightId: $lightId',
      );
      // TODO: integrate with app navigation using a global navigator key if available.
    } catch (e) {
      print('❌ Error in notification navigation: $e');
    }
  }

  /// Subscribe to recommended topics (user-specific and global)
  static Future<void> _subscribeToTopics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firebaseMessaging.subscribeToTopic('user_${user.uid}');
      }
      await _firebaseMessaging.subscribeToTopic('street_lights_alerts');
      print('✅ Subscribed to notification topics');
    } catch (e) {
      print('❌ Error subscribing to topics: $e');
    }
  }

  /// Public helper to display a local notification from app code.
  /// If notificationDocId is provided it will be used to avoid future dupes.
  static Future<void> displayLocalNotification({
    required String title,
    String? body,
    Map<String, dynamic>? data,
    int? id,
    String? notificationDocId,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'street_lights_channel',
        'Street Lights Notifications',
        channelDescription:
            'Real-time notifications for street light monitoring',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Compose title to include appName/lightName when provided in data
      final appName = data == null
          ? null
          : (data['appName'] ?? data['app_name']);
      final lightName = data == null
          ? null
          : (data['lightName'] ?? data['light_name'] ?? data['name']);

      String finalTitle = title;
      try {
        if ((appName != null && appName.toString().isNotEmpty) ||
            (lightName != null && lightName.toString().isNotEmpty)) {
          final parts = <String>[];
          if (appName != null && appName.toString().isNotEmpty)
            parts.add(appName.toString());
          parts.add(title);
          if (lightName != null && lightName.toString().isNotEmpty)
            parts.add(lightName.toString());
          finalTitle = parts.join(' — ');
        }
      } catch (_) {
        // ignore and fallback to provided title
      }

      final notificationId =
          id ??
          (notificationDocId != null
              ? (notificationDocId.hashCode & 0x7fffffff)
              : (DateTime.now().millisecondsSinceEpoch ~/ 1000));

      final payload = data == null ? null : jsonEncode(data);

      await _localNotifications.show(
        notificationId,
        finalTitle,
        body ?? '',
        details,
        payload: payload,
      );

      if (notificationDocId != null)
        await markNotificationAsShown(notificationDocId);
    } catch (e) {
      print('❌ Error displaying local notification: $e');
    }
  }

  /// Accessor for current FCM token
  static String? get fcmToken => _fcmToken;

  /// Cancel a previously shown OS notification using the Firestore doc id.
  /// This computes the stable numeric id used when showing notifications.
  static Future<void> cancelNotificationByDocId(
    String notificationDocId,
  ) async {
    try {
      if (notificationDocId.isEmpty) return;
      final notificationId = (notificationDocId.hashCode & 0x7fffffff);
      await _localNotifications.cancel(notificationId);
      // Also remove from shown set so future remote/cloud re-sends can still show
      // if needed; we intentionally keep shown set intact to avoid re-showing
      // the same historical notification. If you prefer to allow re-showing,
      // remove the line below.
      _shownNotificationDocIds.remove(notificationDocId);
      await _persistShownNotificationIds();
      print(
        '✅ Cancelled OS notification (id=$notificationId) for doc $notificationDocId',
      );
    } catch (e) {
      print('❌ Error cancelling notification for doc $notificationDocId: $e');
    }
  }

  /// Check if notifications are enabled for this app.
  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      return false;
    }
  }

  /// Opens platform app settings so the user can toggle notifications.
  static Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (e) {
      print('❌ Error opening notification settings: $e');
    }
  }
}

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print('🔔 Background message received: ${message.data}');

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('background_notifications').add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': FieldValue.serverTimestamp(),
      'processed': false,
    });

    print('✅ Background message processed');
  } catch (e) {
    print('❌ Error in background handler: $e');
  }
}
