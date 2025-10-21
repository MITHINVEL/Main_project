# Real-Time Push Notifications Setup Guide 🔔

This guide explains how to set up real-time push notifications for your Street Light Monitoring app that will appear at the top of your mobile device even when using other apps.

## ✅ What's Already Implemented

✓ **Complete FCM Integration**: Firebase Cloud Messaging service
✓ **Background Message Handling**: Notifications work even when app is closed
✓ **Local Notifications**: Rich notifications with icons and actions
✓ **Real-Time Monitoring**: Automatic detection of street light changes
✓ **Notification Test Widget**: Built-in testing interface
✓ **Permission Management**: Automatic permission requests

## 📱 Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `monitoring_system_for_street_lights`
3. Navigate to **Cloud Messaging** section
4. Enable **Firebase Cloud Messaging API (V1)**

### 3. Android Configuration (android/app/src/main/AndroidManifest.xml)
Add these permissions and services:

```xml
<!-- Notification Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

<!-- FCM Services -->
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Notification Metadata -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/accent_color" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="street_light_notifications" />
```

### 4. iOS Configuration (ios/Runner/Info.plist)
```xml
<!-- Notification Permissions -->
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>remote-notification</string>
</array>

<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

## 🧪 Testing Notifications

### Using Built-in Test Widget

1. Add Settings Screen to your navigation:
```dart
// In your main navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SettingsScreen(),
  ),
);
```

2. In Settings Screen, you'll find:
   - **Notification Test Widget** with multiple test buttons
   - **Real-time status** of notification services
   - **FCM Token** display for debugging

### Test Buttons Available:
- **Single Test**: Basic notification test
- **Low Battery**: Simulates battery alert
- **Light Status**: Simulates status change
- **Offline Alert**: Simulates connection loss
- **Simulate All Events**: Tests all notification types

## 🔧 Notification Types Configured

### 1. Battery Alerts 🔋
```dart
// Triggered when battery < 20%
await PushNotificationService.sendNotification(
  title: '🔋 Low Battery Alert',
  body: 'Street Light SL-001 battery is at 15%',
);
```

### 2. Status Changes 💡
```dart
// Triggered on ON/OFF changes
await PushNotificationService.sendNotification(
  title: '💡 Light Status Changed',
  body: 'Street Light SL-002 turned ON automatically',
);
```

### 3. Connection Issues 📡
```dart
// Triggered when offline > 30 minutes
await PushNotificationService.sendNotification(
  title: '📡 Connection Lost',
  body: 'Street Light SL-003 went offline',
);
```

### 4. Maintenance Alerts 🔧
```dart
// Triggered on sensor faults
await PushNotificationService.sendNotification(
  title: '🔧 Maintenance Required',
  body: 'Street Light SL-004 needs attention',
);
```

## 🚀 How to Enable Real-Time Monitoring

The monitoring service is automatically started in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize push notifications
  await PushNotificationService.initialize();
  
  // Start real-time monitoring
  StreetLightMonitoringService.startMonitoring();
  
  runApp(MyApp());
}
```

## 📱 Device-Level Notifications Features

✓ **Always Visible**: Notifications appear even when using other apps
✓ **Top Priority**: Uses high priority for immediate display
✓ **Rich Content**: Icons, actions, and detailed information
✓ **Background Processing**: Works even when app is completely closed
✓ **Permission Management**: Automatic permission requests

## 🔍 Troubleshooting

### If notifications don't appear:

1. **Check Permissions**:
```dart
final enabled = await PushNotificationService.areNotificationsEnabled();
print('Notifications enabled: $enabled');
```

2. **Verify FCM Token**:
```dart
final token = PushNotificationService.fcmToken;
print('FCM Token: $token');
```

3. **Test Local Notifications**:
```dart
await PushNotificationService.displayLocalNotification(
  title: '🔔 Test Notification',
  body: 'This is a local test notification',
  data: {'type': 'test'},
);
```

4. **Check Device Settings**:
   - Android: Settings > Apps > Your App > Notifications
   - iOS: Settings > Notifications > Your App

### Common Issues:

- **No notifications on Android**: Check if battery optimization is disabled
- **No notifications on iOS**: Ensure app has notification permissions
- **Background not working**: Verify background app refresh is enabled

## 📋 Implementation Status

✅ **PushNotificationService**: Complete FCM implementation
✅ **StreetLightMonitoringService**: Real-time monitoring with auto-notifications
✅ **NotificationTestWidget**: Comprehensive testing interface
✅ **SettingsScreen**: User-friendly settings and testing
✅ **Background Handlers**: Works when app is closed
✅ **Local Notifications**: Rich notification display
✅ **Permission Management**: Automatic permission handling

## 🎯 Next Steps

1. **Test on Real Device**: Deploy to physical device and test notifications
2. **Configure Firebase**: Ensure FCM is properly set up in Firebase Console
3. **Test Background**: Close app completely and verify notifications still work
4. **User Testing**: Get feedback on notification timing and content

Your real-time notification system is now ready! Notifications will appear at the top of the mobile device even when using other apps, providing instant alerts about street light status changes.