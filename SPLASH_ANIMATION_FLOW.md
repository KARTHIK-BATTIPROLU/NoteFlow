# 🎬 Splash Screen Animation Flow

## Visual Timeline

```
Time: 0ms
┌─────────────────────────────┐
│                             │
│                             │
│      [Logo - Opacity 0%]    │
│      (Invisible)            │
│                             │
│       NoteFlow              │
│                             │
│ Your notes. Everyone's      │
│      success.               │
│                             │
│    [Loading Spinner]        │
│                             │
└─────────────────────────────┘
Animation Controller starts
```

```
Time: 500ms
┌─────────────────────────────┐
│                             │
│                             │
│      [Logo - Opacity 33%]   │
│      (Fading in...)         │
│                             │
│       NoteFlow              │
│                             │
│ Your notes. Everyone's      │
│      success.               │
│                             │
│    [Loading Spinner]        │
│                             │
└─────────────────────────────┘
Logo becoming visible
```

```
Time: 1000ms
┌─────────────────────────────┐
│                             │
│                             │
│      [Logo - Opacity 66%]   │
│      (Almost visible)       │
│                             │
│       NoteFlow              │
│                             │
│ Your notes. Everyone's      │
│      success.               │
│                             │
│    [Loading Spinner]        │
│                             │
└─────────────────────────────┘
Logo more visible
```

```
Time: 1500ms
┌─────────────────────────────┐
│                             │
│                             │
│      [Logo - Opacity 100%]  │
│      (Fully visible)        │
│                             │
│       NoteFlow              │
│                             │
│ Your notes. Everyone's      │
│      success.               │
│                             │
│    [Loading Spinner]        │
│                             │
└─────────────────────────────┘
Animation complete
```

```
Time: 2000ms
┌─────────────────────────────┐
│                             │
│    Navigation triggered     │
│                             │
│    Checking auth state...   │
│                             │
│    If logged in → Home      │
│    If not → Login           │
│                             │
└─────────────────────────────┘
Navigating away
```

---

## Code Flow Diagram

```
App Launch
    │
    ├─> main.dart
    │   └─> runApp(MyApp)
    │
    ├─> Router initialized
    │   └─> initialLocation: '/'
    │
    ├─> SplashScreen widget created
    │   │
    │   ├─> initState()
    │   │   │
    │   │   ├─> Create AnimationController (1500ms)
    │   │   │
    │   │   ├─> Create FadeAnimation (0.0 → 1.0)
    │   │   │
    │   │   ├─> Start animation (_controller.forward())
    │   │   │
    │   │   └─> Schedule navigation (2000ms delay)
    │   │
    │   └─> build()
    │       │
    │       └─> FadeTransition
    │           │
    │           └─> Image.asset('assets/images/logo.png')
    │
    ├─> Animation runs (0ms → 1500ms)
    │   └─> Logo opacity: 0% → 100%
    │
    ├─> Wait until 2000ms
    │
    ├─> Check auth state
    │   │
    │   ├─> User logged in?
    │   │   ├─> Yes → context.go('/home')
    │   │   └─> No → context.go('/login')
    │   │
    │   └─> Loading/Error → context.go('/login')
    │
    └─> dispose()
        └─> Clean up AnimationController
```

---

## Animation State Machine

```
┌─────────────┐
│   INITIAL   │
│  (Mounted)  │
└──────┬──────┘
       │
       │ initState()
       ▼
┌─────────────┐
│  ANIMATING  │
│ (0-1500ms)  │
│             │
│ Opacity:    │
│ 0.0 → 1.0   │
└──────┬──────┘
       │
       │ Animation complete
       ▼
┌─────────────┐
│   WAITING   │
│(1500-2000ms)│
│             │
│ Logo fully  │
│  visible    │
└──────┬──────┘
       │
       │ 2000ms elapsed
       ▼
┌─────────────┐
│  CHECKING   │
│  AUTH STATE │
└──────┬──────┘
       │
       ├─> Authenticated
       │   │
       │   ▼
       │ ┌─────────────┐
       │ │  NAVIGATE   │
       │ │  TO HOME    │
       │ └─────────────┘
       │
       └─> Not Authenticated
           │
           ▼
         ┌─────────────┐
         │  NAVIGATE   │
         │  TO LOGIN   │
         └─────────────┘
```

---

## Widget Tree Structure

```
MaterialApp.router
    │
    └─> GoRouter
        │
        └─> Route: '/'
            │
            └─> SplashScreen (StatefulWidget)
                │
                └─> Scaffold
                    │
                    └─> Center
                        │
                        └─> FadeTransition
                            │
                            └─> Column
                                │
                                ├─> Image.asset (Logo)
                                │   └─> 'assets/images/logo.png'
                                │
                                ├─> SizedBox (spacing)
                                │
                                ├─> Text ('NoteFlow')
                                │
                                ├─> SizedBox (spacing)
                                │
                                ├─> Text ('Your notes...')
                                │
                                ├─> SizedBox (spacing)
                                │
                                └─> CircularProgressIndicator
```

---

## Animation Curve Visualization

```
Curves.easeIn

Opacity
  1.0 │                    ╱─────
      │                  ╱
      │                ╱
  0.7 │              ╱
      │            ╱
      │          ╱
  0.3 │        ╱
      │      ╱
      │    ╱
  0.0 │───╱
      └─────────────────────────> Time
      0ms   500ms  1000ms  1500ms

Slow start → Fast finish
```

---

## File Dependencies

```
pubspec.yaml
    │
    ├─> Declares: assets/images/logo.png
    │
    └─> Configures: flutter_launcher_icons

assets/images/logo.png
    │
    ├─> Used by: SplashScreen widget
    │
    └─> Used by: flutter_launcher_icons

lib/features/auth/presentation/screens/splash_screen.dart
    │
    ├─> Imports: flutter/material.dart
    ├─> Imports: flutter_riverpod
    ├─> Imports: go_router
    ├─> Imports: app_theme.dart
    └─> Imports: auth_repository.dart

lib/core/router/app_router.dart
    │
    └─> Routes '/' to SplashScreen
```

---

## Platform Icon Generation Flow

```
flutter pub run flutter_launcher_icons
    │
    ├─> Reads: pubspec.yaml config
    │
    ├─> Loads: assets/images/logo.png
    │
    ├─> Generates Android Icons
    │   └─> android/app/src/main/res/mipmap-*/
    │
    ├─> Generates iOS Icons
    │   └─> ios/Runner/Assets.xcassets/
    │
    ├─> Generates Web Icons
    │   └─> web/icons/
    │
    ├─> Generates Windows Icons
    │   └─> windows/runner/resources/
    │
    ├─> Generates macOS Icons
    │   └─> macos/Runner/Assets.xcassets/
    │
    └─> Generates Linux Icons
        └─> linux/runner/resources/
```

---

## Memory Management

```
SplashScreen Created
    │
    ├─> AnimationController allocated
    │   └─> Memory: ~1KB
    │
    ├─> Animation objects created
    │   └─> Memory: ~500B
    │
    ├─> Image loaded from assets
    │   └─> Memory: ~50-200KB (depends on logo)
    │
    └─> Widget tree built
        └─> Memory: ~2-5KB

Navigation Triggered (2000ms)
    │
    └─> dispose() called
        │
        ├─> AnimationController disposed ✓
        │
        ├─> Animation objects released ✓
        │
        ├─> Image cache managed by Flutter ✓
        │
        └─> Widget tree destroyed ✓

Memory cleaned up automatically
```

---

## Performance Metrics

```
Target Performance:
├─> Frame Rate: 60 FPS
├─> Animation Smoothness: 100%
├─> Memory Usage: < 10MB
├─> CPU Usage: < 5%
└─> Battery Impact: Minimal

Actual Performance (Expected):
├─> Frame Rate: 60 FPS ✓
├─> Animation Smoothness: 100% ✓
├─> Memory Usage: ~5-8MB ✓
├─> CPU Usage: ~2-3% ✓
└─> Battery Impact: Negligible ✓
```

---

## User Experience Timeline

```
User Action: Tap app icon
    │
    ├─> 0ms: App process starts
    │
    ├─> 50-100ms: Flutter engine initializes
    │
    ├─> 100-200ms: Splash screen appears
    │   └─> Logo starts fading in
    │
    ├─> 1500ms: Logo fully visible
    │   └─> User sees complete splash screen
    │
    ├─> 2000ms: Navigation begins
    │   └─> Smooth transition to next screen
    │
    └─> 2200ms: User sees login/home screen
        └─> App fully interactive

Total Time to Interactive: ~2.2 seconds
```

---

## Testing Checklist Flow

```
Start Testing
    │
    ├─> Visual Tests
    │   ├─> [ ] Logo appears
    │   ├─> [ ] Logo fades in smoothly
    │   ├─> [ ] Animation is 2 seconds
    │   ├─> [ ] No stuttering
    │   └─> [ ] Proper navigation
    │
    ├─> Platform Tests
    │   ├─> [ ] Android icon correct
    │   ├─> [ ] iOS icon correct
    │   ├─> [ ] Web favicon correct
    │   └─> [ ] Desktop icon correct
    │
    ├─> Performance Tests
    │   ├─> [ ] 60 FPS maintained
    │   ├─> [ ] No memory leaks
    │   └─> [ ] Fast app startup
    │
    └─> Edge Cases
        ├─> [ ] Works in dark mode
        ├─> [ ] Works on small screens
        ├─> [ ] Works on large screens
        └─> [ ] Works offline

All Tests Pass → ✅ Ready for Production
```

---

**This visual guide helps understand the complete flow of the splash screen implementation!**
