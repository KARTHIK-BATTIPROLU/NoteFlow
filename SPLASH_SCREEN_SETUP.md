# Splash Screen & App Logo Setup

## ✅ Completed Tasks

### 1. **Logo Asset Configuration**
- Created `assets/images/` directory
- Moved `logo.png` to `assets/images/logo.png`
- Updated `pubspec.yaml` to include the logo asset

### 2. **Splash Screen with Fade Animation**
- Updated the existing splash screen at `lib/features/auth/presentation/screens/splash_screen.dart`
- Implemented fade-in animation using `FadeTransition` and `AnimationController`
- Animation duration: 2 seconds with `Curves.easeIn` curve
- The logo fades in smoothly when the app launches
- After 2 seconds, automatically navigates to:
  - `/home` if user is authenticated
  - `/login` if user is not authenticated

### 3. **App Launcher Icons**
- Added `flutter_launcher_icons` package to dev dependencies
- Configured launcher icons for all platforms:
  - ✅ Android
  - ✅ iOS
  - ✅ Web
  - ✅ Windows
  - ✅ macOS
  - ✅ Linux
- Generated launcher icons using `logo.png`

## 📁 Files Modified

1. **pubspec.yaml**
   - Added assets configuration
   - Added `flutter_launcher_icons` dev dependency
   - Added launcher icons configuration

2. **lib/features/auth/presentation/screens/splash_screen.dart**
   - Replaced icon-based logo with `Image.asset` using `logo.png`
   - Maintained existing fade animation (2 seconds)
   - Kept authentication-based navigation logic

## 🎨 Animation Details

```dart
// Animation Controller
AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500), // 1.5s fade
)

// Fade Animation
Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  ),
)

// Total splash duration: 2 seconds
```

## 🚀 How to Test

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Expected behavior:**
   - App opens with splash screen
   - Logo fades in smoothly over 1.5 seconds
   - After 2 seconds total, navigates to home or login
   - App launcher icon shows your logo on all platforms

## 📱 Platform-Specific Icons

The launcher icons have been generated for:
- **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web**: `web/icons/Icon-*.png`
- **Windows**: `windows/runner/resources/app_icon.ico`
- **macOS**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Linux**: `linux/runner/resources/app_icon.png`

## 🔄 Regenerating Icons

If you update the logo, regenerate icons with:
```bash
flutter pub run flutter_launcher_icons
```

## 📝 Notes

- The splash screen uses the existing authentication logic
- Logo size on splash screen: 200x200 pixels
- Animation curve: `Curves.easeIn` for smooth fade-in effect
- Background color adapts to app theme (light/dark mode)
