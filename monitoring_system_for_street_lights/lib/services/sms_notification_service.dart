import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SMS Notification Service for Street Light GSM Messages
class SmsNotificationService {
  static final SmsNotificationService _instance =
      SmsNotificationService._internal();
  factory SmsNotificationService() => _instance;
  SmsNotificationService._internal();

  final Telephony telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Street light GSM numbers storage key
  static const String _gsm_numbers_key = 'street_light_gsm_numbers';

  List<String> _streetLightNumbers = [];
  bool _isInitialized = false;

  /// Initialize the SMS service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('📱 SMS Service already initialized');
      return;
    }

    try {
      // Request SMS permissions
      await _requestSmsPermissions();

      // Initialize notifications
      await _initializeNotifications();

      // Load saved GSM numbers
      await _loadStreetLightNumbers();

      // Start SMS listener
      await _startSmsListener();

      _isInitialized = true;
      print('✅ SMS Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing SMS service: $e');
    }
  }

  /// Request SMS permissions
  Future<bool> _requestSmsPermissions() async {
    try {
      final smsStatus = await Permission.sms.request();
      final phoneStatus = await Permission.phone.request();

      final smsGranted = smsStatus.isGranted;
      final phoneGranted = phoneStatus.isGranted;

      if (!smsGranted) {
        print('⚠️ SMS permission denied');
        return false;
      }

      print('✅ SMS permissions granted');
      return true;
    } catch (e) {
      print('❌ Permission request error: $e');
      return false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification tapped: ${response.payload}');
        // You can navigate to a specific screen here
      },
    );

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      'street_light_sms_channel',
      'Street Light SMS',
      description: 'SMS notifications from street light GSM modules',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    print('✅ Notifications initialized');
  }

  /// Start SMS listener
  Future<void> _startSmsListener() async {
    try {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _handleIncomingSms(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
      print('✅ SMS listener started');
    } catch (e) {
      print('❌ Error starting SMS listener: $e');
    }
  }

  /// Handle incoming SMS
  void _handleIncomingSms(SmsMessage message) {
    final sender = message.address ?? 'Unknown';
    final body = message.body ?? '';
    final timestamp = (message.date != null && message.date is DateTime)
        ? message.date as DateTime
        : DateTime.now();

    print('📱 SMS Received from: $sender');
    print('📱 Message: $body');
    print('📱 Time: $timestamp');

    // Check if this is a street light message
    if (_isStreetLightMessage(sender, body)) {
      print('🚨 Street Light Message Detected!');

      // Show notification
      _showNotification(
        title: '🚨 Street Light Alert',
        body: body,
        sender: sender,
        timestamp: timestamp,
      );

      // Save to Firebase
      _saveMessageToFirebase(
        sender: sender,
        message: body,
        timestamp: timestamp,
      );
    }
  }

  /// Check if message is from street light
  bool _isStreetLightMessage(String sender, String body) {
    // Clean sender number (remove country code, spaces, etc.)
    final cleanSender = sender.replaceAll(RegExp(r'[^\d]'), '');

    // Check if sender is in registered GSM numbers
    for (var number in _streetLightNumbers) {
      final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanSender.contains(cleanNumber) ||
          cleanNumber.contains(cleanSender)) {
        print('✅ Matched registered number: $number');
        return true;
      }
    }

    // Check for street light keywords
    final keywords = [
      'alert',
      'battery',
      'fault',
      'error',
      'warning',
      'status',
      'street light',
      'solar panel',
      'voltage',
      'current',
      'power',
      'offline',
      'online',
    ];

    final lowerBody = body.toLowerCase();
    for (var keyword in keywords) {
      if (lowerBody.contains(keyword)) {
        print('✅ Matched keyword: $keyword');
        return true;
      }
    }

    return false;
  }

  /// Show notification
  Future<void> _showNotification({
    required String title,
    required String body,
    required String sender,
    required DateTime timestamp,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'street_light_sms_channel',
        'Street Light SMS',
        channelDescription: 'SMS notifications from street light GSM modules',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      final notificationId = timestamp.millisecondsSinceEpoch ~/ 1000;

      await _notifications.show(
        notificationId,
        title,
        '$body\n\nFrom: $sender\nTime: ${_formatTime(timestamp)}',
        notificationDetails,
        payload: sender,
      );

      print('✅ Notification shown: $title');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Save message to Firebase
  Future<void> _saveMessageToFirebase({
    required String sender,
    required String message,
    required DateTime timestamp,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('street_light_sms').add({
        'sender': sender,
        'message': message,
        'timestamp': Timestamp.fromDate(timestamp),
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Message saved to Firebase');
    } catch (e) {
      print('❌ Error saving to Firebase: $e');
    }
  }

  /// Load street light numbers from SharedPreferences
  Future<void> _loadStreetLightNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numbers = prefs.getStringList(_gsm_numbers_key) ?? [];
      _streetLightNumbers = numbers;
      print('✅ Loaded ${numbers.length} GSM numbers');
    } catch (e) {
      print('❌ Error loading GSM numbers: $e');
    }
  }

  /// Save street light numbers to SharedPreferences
  Future<void> _saveStreetLightNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_gsm_numbers_key, _streetLightNumbers);
      print('✅ Saved ${_streetLightNumbers.length} GSM numbers');
    } catch (e) {
      print('❌ Error saving GSM numbers: $e');
    }
  }

  /// Add a street light GSM number
  Future<void> addStreetLightNumber(String number) async {
    final cleanNumber = number.trim();
    if (cleanNumber.isEmpty) return;

    if (!_streetLightNumbers.contains(cleanNumber)) {
      _streetLightNumbers.add(cleanNumber);
      await _saveStreetLightNumbers();
      print('✅ Added GSM number: $cleanNumber');
    } else {
      print('⚠️ GSM number already exists: $cleanNumber');
    }
  }

  /// Remove a street light GSM number
  Future<void> removeStreetLightNumber(String number) async {
    _streetLightNumbers.remove(number);
    await _saveStreetLightNumbers();
    print('✅ Removed GSM number: $number');
  }

  /// Get all registered street light numbers
  List<String> getStreetLightNumbers() => List.from(_streetLightNumbers);

  /// Format timestamp
  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  print('📱 Background SMS received from: ${message.address}');
  print('📱 Message: ${message.body}');

  // The background handler will trigger the main handler
  // which will show notification and save to Firebase
}
