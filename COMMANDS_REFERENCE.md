# 🎯 Commands Reference - Splash Screen & Logo

## 🚀 Essential Commands

### Run the App
```bash
# Standard run
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode (better performance)
flutter run --release
```

### Platform-Specific Run
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (Chrome)
flutter run -d chrome

# Web (Edge)
flutter run -d edge

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

## 🔧 Maintenance Commands

### Clean Build
```bash
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Clean + Get + Run
flutter clean && flutter pub get && flutter run
```

### Update Dependencies
```bash
# Get latest packages
flutter pub get

# Upgrade packages
flutter pub upgrade

# Check outdated packages
flutter pub outdated
```

---

## 🎨 Icon Generation Commands

### Generate Launcher Icons
```bash
# Generate icons for all platforms
flutter pub run flutter_launcher_icons

# Or using dart run (newer)
dart run flutter_launcher_icons
```

### After Updating Logo
```bash
# 1. Replace logo file
cp new_logo.png assets/images/logo.png

# 2. Regenerate icons
flutter pub run flutter_launcher_icons

# 3. Clean and run
flutter clean && flutter pub get && flutter run
```

---

## 🐛 Troubleshooting Commands

### Fix Common Issues
```bash
# Full clean rebuild
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run

# Clear Flutter cache
flutter pub cache repair

# Check Flutter setup
flutter doctor

# Verbose doctor output
flutter doctor -v
```

### Device Management
```bash
# List all devices
flutter devices

# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator-id>
```

---

## 📱 Build Commands

### Android
```bash
# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Install on device
flutter install
```

### iOS
```bash
# Build iOS app
flutter build ios

# Build iOS app (release)
flutter build ios --release
```

### Web
```bash
# Build web app
flutter build web

# Build web app (release)
flutter build web --release

# Serve web app locally
flutter run -d chrome
```

### Windows
```bash
# Build Windows app
flutter build windows

# Build Windows app (release)
flutter build windows --release
```

### macOS
```bash
# Build macOS app
flutter build macos

# Build macOS app (release)
flutter build macos --release
```

### Linux
```bash
# Build Linux app
flutter build linux

# Build Linux app (release)
flutter build linux --release
```

---

## 🧪 Testing Commands

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/splash_screen_test.dart

# Run tests with coverage
flutter test --coverage
```

### Analyze Code
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Format specific file
flutter format lib/features/auth/presentation/screens/splash_screen.dart
```

---

## 📊 Performance Commands

### Profile Performance
```bash
# Run in profile mode
flutter run --profile

# Run with performance overlay
flutter run --profile --trace-skia

# Measure app size
flutter build apk --analyze-size
```

### Check App Size
```bash
# Android APK size
flutter build apk --analyze-size

# iOS app size
flutter build ios --analyze-size
```

---

## 🔍 Debugging Commands

### Debug Mode
```bash
# Run with verbose logging
flutter run -v

# Run with specific log level
flutter run --verbose

# Attach to running app
flutter attach
```

### Hot Reload & Restart
```bash
# While app is running:
# Press 'r' for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

---

## 📦 Package Management

### Add Packages
```bash
# Add a package
flutter pub add <package_name>

# Add dev dependency
flutter pub add --dev <package_name>

# Remove package
flutter pub remove <package_name>
```

### Specific to This Project
```bash
# Add flutter_launcher_icons (already added)
flutter pub add --dev flutter_launcher_icons

# Add other useful packages
flutter pub add flutter_native_splash
flutter pub add lottie
```

---

## 🌐 Web-Specific Commands

### Web Development
```bash
# Run on Chrome
flutter run -d chrome

# Run on Chrome with specific port
flutter run -d chrome --web-port=8080

# Build for web
flutter build web

# Serve built web app
cd build/web && python -m http.server 8000
```

---

## 📱 Android-Specific Commands

### Android Development
```bash
# List Android devices
adb devices

# Install APK manually
adb install build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.example.noteflow

# View logs
adb logcat | grep flutter
```

---

## 🍎 iOS-Specific Commands

### iOS Development
```bash
# List iOS devices
xcrun simctl list devices

# Boot simulator
xcrun simctl boot <device-id>

# Open simulator
open -a Simulator
```

---

## 🔄 Git Commands (Bonus)

### Version Control
```bash
# Check status
git status

# Add changes
git add .

# Commit changes
git commit -m "Add splash screen with fade animation"

# Push changes
git push origin main
```

---

## 📝 Quick Reference Table

| Task | Command |
|------|---------|
| Run app | `flutter run` |
| Clean build | `flutter clean` |
| Get packages | `flutter pub get` |
| Generate icons | `flutter pub run flutter_launcher_icons` |
| Check setup | `flutter doctor` |
| List devices | `flutter devices` |
| Build APK | `flutter build apk --release` |
| Run tests | `flutter test` |
| Analyze code | `flutter analyze` |
| Format code | `flutter format .` |

---

## 🎯 Common Workflows

### First Time Setup
```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

### After Code Changes
```bash
# Just run (hot reload will work)
flutter run

# Or if issues occur
flutter clean
flutter pub get
flutter run
```

### After Logo Update
```bash
cp new_logo.png assets/images/logo.png
flutter pub run flutter_launcher_icons
flutter clean
flutter run
```

### Before Committing
```bash
flutter analyze
flutter format .
flutter test
git add .
git commit -m "Your message"
```

### Release Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## 💡 Pro Tips

### Speed Up Development
```bash
# Use hot reload (press 'r' while app is running)
# Use hot restart (press 'R' while app is running)
# Keep emulator/device running
# Use --no-sound-null-safety if needed
```

### Optimize Build Time
```bash
# Use specific device
flutter run -d <device-id>

# Skip unnecessary checks
flutter run --no-pub

# Use cached builds
flutter run --use-application-binary
```

### Debug Performance
```bash
# Profile mode
flutter run --profile

# With DevTools
flutter run --profile
# Then open DevTools in browser
```

---

## 🆘 Emergency Commands

### When Everything Breaks
```bash
# Nuclear option - clean everything
flutter clean
rm -rf build/
rm pubspec.lock
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

### Reset Flutter
```bash
# Repair Flutter cache
flutter pub cache repair

# Reinstall Flutter (if needed)
# Download Flutter again and replace
```

---

## 📞 Help Commands

### Get Help
```bash
# General help
flutter --help

# Command-specific help
flutter run --help
flutter build --help

# Check version
flutter --version

# Check doctor
flutter doctor
```

---

**Keep this reference handy for quick command lookup! 🚀**
