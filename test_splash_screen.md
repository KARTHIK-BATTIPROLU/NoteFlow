# 🧪 Splash Screen Testing Guide

## Quick Test Commands

### 1. Run on Android Emulator/Device
```bash
flutter run
```

### 2. Run on Chrome (Web)
```bash
flutter run -d chrome
```

### 3. Run on Windows
```bash
flutter run -d windows
```

## ✅ What to Verify

### Splash Screen Animation
- [ ] App opens with splash screen
- [ ] Logo image appears (not icon)
- [ ] Logo fades in smoothly over 1.5 seconds
- [ ] Total splash duration is 2 seconds
- [ ] After 2 seconds, navigates to login or home screen
- [ ] Animation is smooth with no stuttering

### App Launcher Icon
- [ ] **Android**: Check app drawer - logo appears as app icon
- [ ] **iOS**: Check home screen - logo appears as app icon
- [ ] **Web**: Check browser tab - logo appears as favicon
- [ ] **Windows**: Check taskbar/start menu - logo appears
- [ ] **Desktop**: Icon is clear and not pixelated

## 🎯 Expected Behavior

### First Launch (Not Logged In)
```
Splash Screen (2s with fade animation)
  ↓
Login Screen
```

### Subsequent Launch (Logged In)
```
Splash Screen (2s with fade animation)
  ↓
Home Screen
```

## 🐛 Troubleshooting

### Issue: Logo doesn't appear
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Old icon still showing on Android
**Solution:**
```bash
# Uninstall the app first
flutter clean
flutter pub get
flutter run
```

### Issue: Icons not updated
**Solution:**
```bash
flutter pub run flutter_launcher_icons
flutter clean
flutter run
```

## 📱 Platform-Specific Notes

### Android
- Icons generated in multiple resolutions (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- May need to uninstall old app to see new icon

### iOS
- Icons generated for all required sizes
- May need to clean build folder

### Web
- Favicon and PWA icons generated
- Check browser tab for favicon

### Windows/macOS/Linux
- Desktop icons generated
- Check application launcher/start menu

## 🎨 Animation Details

```dart
Duration: 1500ms (1.5 seconds) fade-in
Curve: Curves.easeIn
Total Splash Time: 2000ms (2 seconds)
Logo Size: 200x200 pixels
```

## 📸 Screenshot Checklist

Take screenshots of:
1. Splash screen at start (logo visible)
2. Splash screen mid-animation (logo fading in)
3. App icon in launcher/home screen
4. App running after splash

## ✨ Success Criteria

✅ Logo fades in smoothly  
✅ No errors in console  
✅ Navigation works after 2 seconds  
✅ App icon shows logo on all platforms  
✅ Animation is smooth (60 FPS)  
✅ No white flash before splash screen  
