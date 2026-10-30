# Comprehensive Features Guide - Movies Store (Secure Browser)

> **⚠️ Educational & Research Disclaimer**: This software is designed and developed strictly for educational research into browser hardening, sandboxed content presentation, and Android platform multimedia optimizations.

---

## 📋 Table of Features

1. [Curated Movie & Series Allowlist](#1-curated-movie--series-allowlist)
2. [Dynamic Remote Allowlist Sync (Zero UI Lag)](#2-dynamic-remote-allowlist-sync-zero-ui-lag)
3. [Local Caching & Instant Offline Availability](#3-local-caching--instant-offline-availability)
4. [In-Dropdown Allowlist Refresh Action](#4-in-dropdown-allowlist-refresh-action)
5. [Dual-Layer Ad & Tracker Neutralization](#5-dual-layer-ad--tracker-neutralization)
6. [Intelligent Popup & Pop-under Interception](#6-intelligent-popup--pop-under-interception)
7. [Anti-Redirect Engine & Redirect Loop Protection](#7-anti-redirect-engine--redirect-loop-protection)
8. [Legitimate OAuth & Captcha Compatibility](#8-legitimate-oauth--captcha-compatibility)
9. [Hardware Audio Volume Booster (+30 dB / up to 400%)](#9-hardware-audio-volume-booster-30-db--up-to-400)
10. [Hardware Display Refresh Rate Override (120Hz / Max FPS)](#10-hardware-display-refresh-rate-override-120hz--max-fps)
11. [Sleep Timer (Auto-Kill App Process)](#11-sleep-timer-auto-kill-app-process)
12. [Zero-Lag Physics Floating Action Buttons (FABs)](#12-zero-lag-physics-floating-action-buttons-fabs)
13. [4-Way Accelerometer Tilt Detection & Rotation Control](#13-4-way-accelerometer-tilt-detection--rotation-control)
14. [Android Immersive Sticky Mode & HTML5 Video Fullscreen](#14-android-immersive-sticky-mode--html5-video-fullscreen)
15. [URL Parameter Sanitization & Privacy Shield](#15-url-parameter-sanitization--privacy-shield)
16. [Comprehensive Settings & Customization](#16-comprehensive-settings--customization)

---

### 1. Curated Movie & Series Allowlist
- **Strict Lockdown**: The browser enforces an allowlist-only navigation strategy. Only approved movie and web series streaming domains are permitted to load in the viewport.
- **Unauthorized Domain Rejection**: Any background script, iframe, or link trying to open a domain outside the allowlist is halted before any network request is made.
- **Top Bar Quick Selector**: A persistent dropdown menu on the toolbar displays all allowlisted streaming platforms with numbered indexing for one-tap switching.

### 2. Dynamic Remote Allowlist Sync (Zero UI Lag)
- **Background Isolate Parsing**: Allowlist definitions are fetched from the remote GitHub endpoint (`allowlist.txt`) and parsed in an independent background Dart Isolate thread using Flutter's `compute()` API.
- **Zero Frame Drops**: Parsing, line splitting, sanitization, and deduplication run off the UI thread, ensuring continuous 120 FPS animations without jitter or freezing.
- **Startup Auto-Sync**: Automatically checks for remote allowlist additions on launch.

### 3. Local Caching & Instant Offline Availability
- **Offline Persistence**: Domains are persisted in `SharedPreferences`.
- **Instant Cold Boot**: Upon startup, the browser loads the cached allowlist instantaneously, eliminating network wait times or blank screens during low-connectivity scenarios.
- **Automatic Fallback**: If the device is offline or the remote fetch times out, the local cached list remains active and fully functional.

### 4. In-Dropdown Allowlist Refresh Action
- **Quick-Access Action**: Positioned as the top item inside the domain selector dropdown for immediate accessibility.
- **Visual Status Spinner**: Features an active spinning indicator and real-time site count badge while the background update occurs.
- **Toast Notifications**: Displays clear snackbar alerts confirming successful synchronization or network fallback.

### 5. Dual-Layer Ad & Tracker Neutralization
- **Layer 1 (Dart Request Filter)**: Evaluates navigation requests against known advertising network hosts and URL path patterns.
- **Layer 2 (Native Android Kotlin Engine)**: A native `AdBlockEngine` checks requests against ad network databases (Doubleclick, Google AdServices, PopAds, ExoClick, PropellerAds, Adsterra, etc.).
- **Essential Asset Protection**: Smart filters whitelist necessary stylesheets (`.css`), fonts (`.woff`, `.woff2`, `.ttf`), and media fragments from allowlisted platforms.
- **Live Blocking Telemetry**: Live counter badge on the bottom status bar tracks blocked ads, trackers, popups, redirects, and intent calls, with a resetable detail dialog.

### 6. Intelligent Popup & Pop-under Interception
- **`window.open` Silencing**: Injected JavaScript overrides `window.open` to return `null`, converting `target="_blank"` anchors to open in the active viewport (`_self`).
- **User-Gesture Requirement**: Popups must be accompanied by an authentic physical user touch gesture registered within a strict 2.5-second time window.
- **Rate-Limiting Protection**: Restricts popups to a maximum allowable threshold per page and interval to stop spam storm popups.

### 7. Anti-Redirect Engine & Redirect Loop Protection
- **Redirect Chain Tracker**: Tracks recent navigation history in a circular buffer to detect infinite ping-pong loops (e.g., A → B → A).
- **Domain Escape Prevention**: Halts client-side and HTTP redirects attempting to redirect the user to malicious, unallowlisted destination URLs.

### 8. Legitimate OAuth & Captcha Compatibility
- **Essential Services Whitelist**: `RedirectCompatibilityManager` selectively allows critical single-sign-on (SSO) and verification providers, including:
  - Google Accounts (`accounts.google.com`)
  - Apple ID (`appleid.apple.com`)
  - ReCAPTCHA (`recaptcha.net`, `google.com/recaptcha`)
  - Payment Gateways (`stripe.com`, `paypal.com`)

### 9. Hardware Audio Volume Booster (+30 dB / up to 400%)
- **Native Android `LoudnessEnhancer`**: Hooks directly into audio session `0` via Android's native audio effects stack.
- **Gain Range**: Amplifies quiet video audio up to **+3000 mB (+30 dB)** above standard Android maximum volume.
- **Interactive Floating Slider**: Accessible via a floating volume button with an ultra-smooth vertical slider popup and auto-hide timer.

### 10. Hardware Display Refresh Rate Override (120Hz / Max FPS)
- **High Refresh Rate Enforcement**: Automatically requests maximum supported hardware display modes (60Hz, 90Hz, 120Hz, or MAX FPS) via `Display.Mode` and `window.attributes.preferredRefreshRate`.
- **Silky Playback & UI**: Eliminates micro-stuttering during video playback and gesture navigation.

### 11. Sleep Timer (Auto-Kill App Process)
- **Preset & Custom Intervals**: Choose from 10m, 20m, 30m, 40m, 60m, or enter a custom duration in minutes.
- **Countdown Floating Widget**: Displays a moveable circular countdown timer on screen with an active radial progress indicator ring.
- **Graceful Termination**: On completion, gracefully exits the application stack (`SystemNavigator.pop()` and `exit(0)`) to conserve device battery overnight.

### 12. Zero-Lag Physics Floating Action Buttons (FABs)
- **Multi-Widget System**: Includes draggable Menu FAB, Volume Booster FAB, Sleep Timer FAB, and Tilt Rotation FAB.
- **120Hz LERP Interpolation**: Active touch dragging uses linear interpolation for lag-free cursor tracking.
- **5-Pass Wall-Diverting Relaxation Solver**: Patented math algorithm prevents floating widgets from colliding with each other or being dragged outside screen bounds, automatically diverting push forces along screen edge walls.
- **Position Persistence**: Widget coordinates on screen are remembered across app restarts via `SharedPreferences`.

### 13. 4-Way Accelerometer Tilt Detection & Rotation Control
- **Hardware Orientation Listener**: Native `OrientationEventListener` maps physical tilt across 4 directions (0° Portrait, 90° Landscape Right, 180° Inverted Portrait, 270° Landscape Left).
- **Two Rotation Modes**:
  - *Direct Tilt Auto-Rotate*: Rotates screen immediately to match physical device tilt.
  - *Manual Rotation Bubble*: Displays an animated 5-second circular floating rotation icon to prevent accidental flips during handheld viewing in bed.

### 14. Android Immersive Sticky Mode & HTML5 Video Fullscreen
- **Full-Screen Immersive Canvas**: Runs in Android `immersiveSticky` mode (`WindowInsetsController`), hiding system status and navigation bars.
- **Auto-Hiding Toolbars**: Browser top and bottom bars automatically slide out of view with cubic bezier animations when scrolling or after a customizable delay (3s, 5s, 8s, 10s).
- **HTML5 Fullscreen Detection**: JavaScript bridge detects when HTML5 video elements enter/exit fullscreen, synchronizing system bars accordingly.

### 15. URL Parameter Sanitization & Privacy Shield
- **Tracker Stripping**: Strips tracking query parameters before sending requests, including `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`, `fbclid`, `gclid`, `msclkid`, `ref`, `partner`, and `affiliate`.
- **System Scheme Sandboxing**: Blocks dangerous local file protocols (`file://`) and restricts `tel:`, `sms:`, and `intent://` calls to verified user interactions.

### 16. Comprehensive Settings & Customization
- **Desktop Mode**: Toggle desktop user-agent (`Mozilla/5.0 Windows NT 10.0`) on the fly.
- **UI Element Scaling**: Independently customize button sizes (30dp - 70dp) and opacity (0% - 100%) for the Menu button, Volume button, Volume slider, and Rotation button.
- **JavaScript Toggle**: Enable/disable JavaScript execution globally.
- **Ad Blocker Master Switch**: Turn blocking engine on or off for benchmarking.
