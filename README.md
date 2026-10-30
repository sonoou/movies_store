# Movies Store - Secure Browser

> **⚠️ DISCLAIMER: FOR EDUCATIONAL PURPOSES ONLY**
> 
> This project is created **strictly for educational, research, and experimental purposes only**. It serves as an architectural demonstration of building a hardened Android web browser using Flutter and native Kotlin, featuring dual-layer ad-blocking, popup suppression, native audio amplification (`LoudnessEnhancer`), and strict allowlist-only navigation. 
> 
> The author and contributors do not host, store, stream, or distribute any media content or copyright-protected material. All trademarks, service marks, and external domain names referenced in the codebase belong to their respective owners. Users are solely responsible for how they use this software and for complying with applicable local laws and regulations.

---

## 📖 Overview

**Movies Store** (package: `com.sonoou.movies` / `secure_browser`) is a specialized, privacy-focused Android media browser designed specifically for clean, secure video streaming. 

Traditional mobile browsers suffer from aggressive pop-under ads, unwanted new tabs, battery-draining trackers, and forced redirects when browsing web streaming platforms. This project solves these challenges by implementing an **allowlist-only navigation policy**: only vetted movie and web series streaming websites are permitted to load, while all extraneous redirects, malicious domain switches, and intrusive advertising networks are intercepted and blocked at both the Dart and native Android network levels.

---

## 📦 Releases & Downloads (v1.0.0)

Pre-built standalone Android release APKs are available in the [`releases/`](./releases/) directory:

| Package | Target Architecture | Direct Download Link | Size |
|:---|:---|:---:|:---:|
| **ARM64 (v8a)** | **All modern Android smartphones** (99% of devices) | [⬇️ Download ARM64 APK](./releases/app-arm64-v8a-release.apk?raw=true) | ~19 MB |
| **ARMv7 (32-bit)** | Older Android devices | [⬇️ Download ARMv7 APK](./releases/app-armeabi-v7a-release.apk?raw=true) | ~16.5 MB |
| **x86_64** | Android Emulators / x86 Architecture | [⬇️ Download x86_64 APK](./releases/app-x86_64-release.apk?raw=true) | ~20.5 MB |

For full checksums, SHA-256 verification, and installation steps, see [`releases/README.md`](./releases/README.md).

---

## ✨ Key Features

> 📖 **Full Details**: For an in-depth breakdown of every subsystem, algorithm, and optimization, check the [**Comprehensive Features Guide (`FEATURES.md`)**](./FEATURES.md).

### 🎬 Curated Movie & Series Allowlist
- **Strict Domain Protection**: Only authorized movie and web series platforms from the allowlist are permitted to load.
- **Dynamic Remote Allowlist Sync**: Automatically fetches and syncs the latest movie & series domains from GitHub (`allowlist.txt`) in an independent background Dart Isolate thread (0% UI freeze/lag).
- **Offline Caching & Fallback**: Stores allowed domains locally with `SharedPreferences`, loading instantly upon startup even when offline.
- **In-Dropdown Allowlist Refresh**: Quick one-tap "Refresh Allowlist" action directly inside the domain picker with visual sync status indicators.
- **Navigation Lockdown**: Any attempt by a webpage or script to redirect outside the curated allowlist is blocked instantly.

### 🛑 Dual-Layer Native Ad & Tracker Blocking
- **Network & Host Matching**: Blocks known ad exchanges, pop-under networks, telemetry, and tracking scripts (e.g. DoubleClick, Google AdServices, PopAds, PropellerAds, ExoClick, Adsterra, etc.).
- **URL Pattern Filtering**: Intercepts paths matching advertising patterns (`/ad/`, `/banner/`, `/pop/`, `utm_`, etc.) while safeguarding required stylesheets, fonts, and media segments.
- **UTM & Tracking Parameter Stripper**: Automatically strips tracking query strings (`utm_source`, `fbclid`, `gclid`, etc.) before requests are processed.
- **Interactive Protection Stats**: Live counter badge showing blocked ads, trackers, popups, redirects, and external intents with a detailed stats modal.

### 🛡️ Smart Popup & Redirect Protection
- **`window.open` Interception**: Silently suppresses unauthorized JavaScript popup windows and converts `target="_blank"` anchors to navigate within the same viewport.
- **User-Gesture Verification**: Popups require an active, verified physical touch gesture within a 2.5-second time window.
- **Rate-Limiting Engine**: Restricts popups to a maximum threshold per page and time interval.
- **Redirect Loop Killer**: Detects and neutralizes recursive redirect chains (e.g., A → B → A loops).
- **Legitimate OAuth Preservation**: Selectively permits essential authentication and verification endpoints (Google Accounts, Apple ID, ReCAPTCHA, Stripe).

### 🔊 Hardware Volume Booster (Up to 400% / +30 dB)
- Directly leverages Android's native `android.media.audiofx.LoudnessEnhancer` API on audio session `0`.
- Provides up to **+30 dB** (3000 mB) of hardware-level audio boost directly from a draggable floating slider widget to amplify quiet web video streams.

### ⚡ Display Refresh Rate Optimization (120Hz / Max FPS)
- Queries supported hardware display modes via Android `Display.Mode`.
- Programmatically sets `preferredDisplayModeId` and `preferredRefreshRate` to force high refresh rates (60Hz, 90Hz, 120Hz, or Maximum FPS) for ultra-smooth scrolling and playback.

### ⏳ Sleep Timer (Auto-Kill App)
- In-app sleep countdown timer (10m, 20m, 30m, 40m, 60m, or custom duration).
- Displays a floating circular countdown widget with an active progress ring.
- Gracefully terminates the application process (`exit(0)`) when the timer reaches zero.

### 🎯 Zero-Lag Floating Physics Solver
- Draggable floating buttons (Menu FAB, Volume Booster FAB, Sleep Timer FAB, Tilt Rotation FAB) with smooth 120Hz LERP interpolation.
- **5-pass wall-diverting relaxation solver** prevents floating controls from overlapping each other or being dragged off-screen.

### 🔄 4-Way Accelerometer Tilt & Custom Rotation
- Hardware accelerometer orientation listener (`OrientationEventListener`) detects physical tilt across 4 directions (0°, 90°, 180°, 270°).
- Offers direct auto-rotation or a temporary 5-second animated floating rotate button to prevent accidental orientation changes.

### 📱 Full Immersive Mode
- Runs in Android Immersive Sticky mode (`WindowInsetsController`).
- Auto-hides top and bottom bars during video playback or after configurable delays (3s, 5s, 8s, 10s).
- Listens to HTML5 video `fullscreenchange` events via an injected JavaScript bridge.

---

## 🛠️ Architecture & Tech Stack

```
Flutter / Dart (UI & State)
   │
   ├── BrowserScreen (WebViewWidget, Physics FABs, Gestures)
   ├── SettingsScreen (Customization & Preferences)
   ├── BrowserSettings (Provider + SharedPreferences)
   └── AllowlistService & UrlUtils
         │
         │  (Platform MethodChannel: com.sonoou.movies/adblock)
         ▼
Native Android / Kotlin (Core Engine)
   ├── MainActivity (LoudnessEnhancer, Display Refresh Rate, InsetsController)
   ├── NavigationController (Navigation decisions & loop protection)
   ├── AdBlockEngine (Network-level domain/pattern blocking)
   ├── PopupController (Gesture verification & rate-limiting)
   ├── RedirectCompatibilityManager (OAuth & Captcha allowances)
   ├── ExternalNavigationController (Intent & scheme sandboxing)
   └── BlockingStats (Atomic counters for telemetry)
```

- **Framework**: [Flutter](https://flutter.dev) (SDK ^3.12.2 / Dart 3)
- **Native Platform**: Android (Kotlin, Android SDK 37, Java 17)
- **Key Packages**:
  - `webview_flutter` & `webview_flutter_android`: WebKit rendering engine
  - `provider`: State management
  - `shared_preferences`: Persistent configuration storage
  - `connectivity_plus`: Real-time network connectivity monitoring
  - `url_launcher`: Controlled external intent execution

---

## 📁 Project Structure

```
Secure_Browser/
├── lib/
│   ├── main.dart                          # App entry point, Dark theme & provider setup
│   ├── models/
│   │   ├── browser_config.dart            # App constants, colors, allowlist & ad patterns
│   │   └── browser_settings.dart          # Central ChangeNotifier state & persistence
│   ├── screens/
│   │   ├── browser_screen.dart            # Main browser UI, physics FABs & gestures
│   │   └── settings_screen.dart          # Display, volume, adblock & timer settings
│   ├── services/
│   │   ├── native_adblock_bridge.dart     # MethodChannel bridge to Kotlin engine
│   │   ├── allowlist_service.dart         # Allowlist domain verification
│   │   └── ad_blocker_service.dart        # Dart URL & pattern matcher
│   ├── utils/
│   │   └── url_utils.dart                 # URL cleaning & tracking parameter stripper
│   └── widgets/
│       ├── custom_toolbar.dart            # Top bar with site selector & URL indicator
│       ├── bottom_status_bar.dart         # Bottom title bar & live stats dialog
│       └── settings_menu.dart             # Settings, refresh, and home menu
└── android/app/src/main/kotlin/com/sonoou/movies/
    ├── MainActivity.kt                    # Platform channel receiver, Display FPS & Audio boost
    └── adblock/
        ├── AdBlockEngine.kt               # Native domain & pattern ad/tracker filtering
        ├── PopupController.kt             # Popup rate-limiting & user-gesture verification
        ├── NavigationController.kt        # Multi-stage navigation decision & loop protection
        ├── RedirectCompatibilityManager.kt # Preserves OAuth & payment gateway redirects
        ├── ExternalNavigationController.kt# Safeguards system intents (tel, sms, market, intent)
        └── BlockingStats.kt               # Atomic counters for blocked telemetry
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.12 or newer)
- Android SDK (API 34+ recommended, compileSdk 37)
- Java Development Kit (JDK 17)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/sonoou/movies_store.git
   cd movies_store
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on an Android device or emulator**:
   ```bash
   flutter run
   ```

4. **Build release APK**:
   ```bash
   flutter build apk --release
   ```

---

## 📄 License & Disclaimer

This project is open-source and intended solely for **educational and research demonstrations**. Please refer to the disclaimer at the beginning of this document.
