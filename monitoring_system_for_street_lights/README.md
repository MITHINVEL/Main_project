# Street Light Monitoring System 💡

A beautiful and professional Flutter application for monitoring and managing street lights across smart cities. This app features modern UI animations, Firebase authentication, and comprehensive street light management capabilities.

## 🚀 Features

### 🎨 Beautiful UI & Animations
- **Onboarding Screens**: Engaging introduction with smooth animations
- **Modern Design**: Professional UI with gradient backgrounds and glass-morphism effects
- **Smooth Animations**: Flutter Animate for beautiful transitions and micro-interactions
- **Responsive Design**: Optimized for different screen sizes using ScreenUtil

### 🔐 Authentication System
- **Firebase Authentication**: Secure user registration and login
- **Email/Password Authentication**: Standard authentication method
- **Password Reset**: Forgot password functionality
- **User Profile Management**: Complete user data management
- **Auto-login**: Remember user sessions

### 📱 App Structure
- **Onboarding Flow**: First-time user experience
- **Authentication Flow**: Login, Register, Forgot Password
- **Dashboard**: Main application interface with overview cards
- **Monitoring**: Real-time street light monitoring
- **Analytics**: Data visualization and insights
- **Profile**: User settings and preferences

### 🏗️ Architecture
- **Provider Pattern**: State management using Provider
- **Modular Structure**: Clean separation of concerns
- **Custom Widgets**: Reusable UI components
- **Theme System**: Consistent design system
- **Constants**: Centralized configuration

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── models/                            # Data models
│   ├── user_model.dart               # User and StreetLight models
│   └── onboarding_model.dart         # Onboarding content model
├── providers/                         # State management
│   └── auth_provider.dart            # Authentication provider
├── screens/                          # App screens
│   ├── onboarding/
│   │   └── onboarding_screen.dart    # Onboarding flow
│   ├── auth/
│   │   ├── welcome_screen.dart       # Welcome screen
│   │   ├── login_screen.dart         # Login screen
│   │   ├── register_screen.dart      # Registration screen
│   │   └── forgot_password_screen.dart # Password reset
│   └── home/
│       └── dashboard_screen.dart     # Main dashboard
├── services/                         # Business logic
│   └── auth_service.dart            # Firebase auth service
├── utils/                           # Utilities
│   ├── constants.dart               # App constants
│   └── app_theme.dart              # Theme configuration
└── widgets/                        # Reusable widgets
    ├── custom_button.dart          # Custom button components
    └── custom_text_field.dart      # Custom input fields
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account
- Android Studio / VS Code
- Android/iOS development setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd monitoring_system_for_street_lights
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Follow the setup wizard

#### Enable Authentication
1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication

#### Enable Firestore Database
1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode"
4. Select a location

#### Configure Firebase for Flutter
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Login to Firebase:
   ```bash
   firebase login
   ```

4. Configure FlutterFire:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Choose platforms (Android, iOS, Web, etc.)
   - This will generate `firebase_options.dart`

### 4. Platform-Specific Setup

#### Android
1. Update `android/app/build.gradle`:
   ```gradle
   android {
       compileSdkVersion 34
       
       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 34
       }
   }
   ```

2. Ensure `android/app/src/main/AndroidManifest.xml` has internet permission:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

#### iOS
1. Update `ios/Runner/Info.plist` with required permissions
2. Ensure minimum iOS version is 11.0 in `ios/Podfile`:
   ```ruby
   platform :ios, '11.0'
   ```

### 5. Run the Application
```bash
flutter run
```

## 📦 Dependencies

### Core Dependencies
- **flutter**: SDK framework
- **firebase_core**: Firebase core functionality
- **firebase_auth**: Authentication
- **cloud_firestore**: Database

### UI & Animations
- **flutter_screenutil**: Responsive design
- **flutter_animate**: Animations
- **google_fonts**: Typography
- **lottie**: Lottie animations
- **smooth_page_indicator**: Page indicators
- **iconsax**: Modern icons

### State Management
- **provider**: State management
- **shared_preferences**: Local storage

### Utilities
- **connectivity_plus**: Network connectivity
- **permission_handler**: Permissions
- **fluttertoast**: Toast messages

## 🎨 Design System

### Colors
- **Primary**: Deep Blue (#1E3A8A)
- **Secondary**: Bright Blue (#3B82F6)
- **Accent**: Golden Yellow (#FBBF24)
- **Success**: Green (#10B981)
- **Warning**: Orange (#F59E0B)
- **Error**: Red (#EF4444)

### Typography
- **Font Family**: Poppins
- **Display**: 32px, Bold
- **Headline**: 24px, SemiBold
- **Body**: 16px, Regular
- **Caption**: 14px, Regular

### Spacing
- **Small**: 8px
- **Medium**: 16px
- **Large**: 24px
- **XLarge**: 32px

## 🔧 Configuration

### Firebase Rules (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Street lights data (read for authenticated users, write for admins)
    match /streetlights/{lightId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Security Rules (Firebase Auth)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Generate Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📱 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email [your-email@example.com] or create an issue in the GitHub repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for typography
- Iconsax for beautiful icons
- Flutter community for packages and inspiration

---

**Built with ❤️ for smart cities and sustainable lighting solutions**
