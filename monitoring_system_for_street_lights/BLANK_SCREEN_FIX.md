# Quick Fixes for Blank White Screen

## Try these solutions step by step:

### Solution 1: Test with Debug Version
1. Rename current `main.dart` to `main_original.dart`
2. Rename `main_debug.dart` to `main.dart` 
3. Run the app to see if the debug version works

### Solution 2: Clear App Data and Restart
1. Go to Settings > Apps > Street Light Monitor
2. Clear Storage and Cache
3. Uninstall the app completely
4. Reinstall and test

### Solution 3: Check Firebase Setup
1. Ensure `google-services.json` is in `android/app/` folder
2. Check if Firebase project is properly configured
3. Verify internet connection

### Solution 4: Use the Fixed Main File
The main.dart file has been updated with:
- Better error handling
- Try-catch blocks for Firebase initialization
- Detailed logging to help identify issues
- Fallback screens if initialization fails

### Solution 5: Build Release APK
Sometimes debug builds have issues. Try:
```
flutter build apk --release
```

### Check Logs
When the app shows blank screen, check logs with:
```
flutter logs
```
or
```
adb logcat | grep flutter
```

## Common Causes:
1. Firebase initialization failure
2. Missing permissions
3. Network connectivity issues
4. Corrupted app cache
5. Invalid certificates

Try Solution 1 first - the debug version will show exactly what's failing!