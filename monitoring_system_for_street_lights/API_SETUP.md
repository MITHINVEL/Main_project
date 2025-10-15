# API Setup Instructions

This document provides step-by-step instructions to configure the required API keys for the Street Light Monitoring System.

## 🗺️ Google Maps API Setup

### 1. Enable Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps JavaScript API
   - Places API
   - Geocoding API

### 2. Create API Key
1. Go to "Credentials" in Google Cloud Console
2. Click "Create Credentials" → "API Key"
3. Copy the generated API key

### 3. Configure Android App
1. Open `android/app/src/main/AndroidManifest.xml`
2. Find this line:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

### 4. Restrict API Key (Recommended)
1. In Google Cloud Console, edit your API key
2. Under "Application restrictions", select "Android apps"
3. Add your app's package name: `com.example.monitoring_system_for_street_lights`
4. Add your app's SHA-1 fingerprint

## 🌤️ OpenWeatherMap API Setup

### 1. Create Account
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to "My API keys" section
4. Copy your API key

### 2. Configure Flutter App
1. Open `lib/services/weather_service.dart`
2. Find this line:
   ```dart
   static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
   ```
3. Replace `YOUR_OPENWEATHERMAP_API_KEY` with your actual API key

## 🔥 Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication and Firestore Database

### 2. Configure Android App
1. Add Android app to Firebase project
2. Download `google-services.json`
3. Place it in `android/app/` directory

### 3. Configure iOS App (if needed)
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

## 🧪 Testing the Setup

### Test Google Maps
1. Run the app
2. Go to "Add Street Light" screen
3. Tap "📍 Pick from Map" button
4. Verify map loads and location can be selected

### Test Weather Service
1. Check the dashboard screen
2. Weather widget should display current weather
3. UV index and 5-day forecast should be visible

### Test Location Services
1. Tap "📍 Current Location" in Add Street Light screen
2. Grant location permissions when prompted
3. Verify current location is detected and address is filled

## 🔒 Security Best Practices

1. **Never commit API keys to version control**
2. **Use environment variables in production**
3. **Restrict API keys to specific apps/domains**
4. **Monitor API usage regularly**
5. **Rotate keys periodically**

## 📱 App Permissions

The app requires these permissions (already configured in AndroidManifest.xml):
- `ACCESS_FINE_LOCATION` - For precise location
- `ACCESS_COARSE_LOCATION` - For approximate location  
- `INTERNET` - For API calls
- `ACCESS_NETWORK_STATE` - For network connectivity

## 🚨 Troubleshooting

### Google Maps not loading
- Check API key is correct
- Verify APIs are enabled in Google Cloud Console
- Check internet connection
- Ensure location permissions are granted

### Weather data not loading
- Verify OpenWeatherMap API key
- Check internet connection
- Ensure location services are enabled

### Location not detected
- Grant location permissions in device settings
- Enable GPS/Location services
- Check if running on real device (emulator location might not work)

## 📞 Support

If you encounter issues:
1. Check the console logs for error messages
2. Verify all API keys are correctly configured
3. Ensure all required permissions are granted
4. Test on a real device rather than emulator

---

**Note**: Free tier limits apply to all APIs. Monitor usage to avoid hitting rate limits.