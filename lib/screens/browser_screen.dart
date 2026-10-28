import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import '../models/browser_config.dart';
import '../models/browser_settings.dart';
import '../services/native_adblock_bridge.dart';
import '../services/allowlist_service.dart';
import '../utils/url_utils.dart';
import '../widgets/custom_toolbar.dart';
import '../widgets/bottom_status_bar.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  static const String _keyFabX = 'fab_position_x';
  static const String _keyFabY = 'fab_position_y';
  static const String _keyVolFabX = 'vol_fab_position_x';
  static const String _keyVolFabY = 'vol_fab_position_y';
  static const String _keyTimerFabX = 'timer_fab_position_x';
  static const String _keyTimerFabY = 'timer_fab_position_y';

  late final WebViewController _webViewController;

  String _currentUrl = BrowserConfig.defaultHomepage;
  String _pageTitle = 'Secure Browser';
  int _loadingProgress = 0;
  bool _isLoading = false;
  bool _isOffline = false;
  bool _hasLoadedInitialUrl = false;
  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';
  static const String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';
  bool _lastDesktopMode = false;

  // Bars hidden by default on app open as requested
  bool _isBarsVisible = false;
  Timer? _autoHideTimer;

  // ValueNotifier for zero-lag smooth 120Hz Draggable Floating Menu Button
  final ValueNotifier<Offset?> _fabPosNotifier = ValueNotifier<Offset?>(null);
  Offset _startFabOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  bool _isDraggingFab = false;

  // ValueNotifier for zero-lag smooth 120Hz Draggable Floating Volume Button
  final ValueNotifier<Offset?> _volPosNotifier = ValueNotifier<Offset?>(null);
  Offset _startVolOffset = Offset.zero;
  Offset _startVolFocalPoint = Offset.zero;
  bool _isDraggingVolFab = false;

  // ValueNotifier for zero-lag smooth 120Hz Draggable Floating Sleep/Kill Timer Button
  final ValueNotifier<Offset?> _timerFabPosNotifier = ValueNotifier<Offset?>(null);
  Offset _startTimerOffset = Offset.zero;
  Offset _startTimerFocalPoint = Offset.zero;
  bool _isDraggingTimerFab = false;

  // App's Internal Manual Floating Rotation Button State
  bool _showInternalRotationButton = false;
  bool _showVolumeSlider = false;
  Timer? _volumeSliderTimer;
  DeviceOrientation _pendingTargetOrientationEnum = DeviceOrientation.portraitUp;
  Timer? _internalRotationTimer;
  static const MethodChannel _adblockChannel = MethodChannel('com.sonoou.movies/adblock');

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initWebViewController();
    _loadFabPosition();
    _loadVolFabPosition();
    _loadTimerFabPosition();
    _initNativeMethodHandler();

    // Start with system bars hidden on app launch (Immersive Sticky Mode)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    NativeAdblockBridge.enableImmersiveMode();
  }

  @override
  void dispose() {
    _internalRotationTimer?.cancel();
    _volumeSliderTimer?.cancel();
    _fabPosNotifier.dispose();
    _volPosNotifier.dispose();
    _timerFabPosNotifier.dispose();
    _autoHideTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _startVolumeSliderTimer() {
    _volumeSliderTimer?.cancel();
    final settings = Provider.of<BrowserSettings>(context, listen: false);
    if (settings.volumeSliderMode == 'AUTO') {
      _volumeSliderTimer = Timer(Duration(seconds: settings.volumeSliderAutoDelay), () {
        if (mounted && _showVolumeSlider) {
          setState(() {
            _showVolumeSlider = false;
          });
        }
      });
    }
  }

  DeviceOrientation _mapStringToOrientation(String target) {
    switch (target) {
      case 'LANDSCAPE_RIGHT':
        return DeviceOrientation.landscapeRight;
      case 'PORTRAIT_DOWN':
        return DeviceOrientation.portraitDown;
      case 'LANDSCAPE_LEFT':
        return DeviceOrientation.landscapeLeft;
      case 'PORTRAIT_UP':
      default:
        return DeviceOrientation.portraitUp;
    }
  }

  void _initNativeMethodHandler() {
    _adblockChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPhysicalTilt') {
        final String? target = call.arguments['targetOrientation'];
        if (target != null && mounted) {
          final settings = Provider.of<BrowserSettings>(context, listen: false);
          final DeviceOrientation targetEnum = _mapStringToOrientation(target);

          if (settings.appAutoRotate) {
            // In-App Auto-Rotate is ON: Directly set exact physical orientation (4-way 360 degree supported!)
            SystemChrome.setPreferredOrientations([targetEnum]);
          } else {
            // In-App Auto-Rotate is OFF: Show internal 5s floating rotation button
            _internalRotationTimer?.cancel();
            setState(() {
              _pendingTargetOrientationEnum = targetEnum;
              _showInternalRotationButton = true;
            });

            _internalRotationTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showInternalRotationButton = false;
                });
              }
            });
          }
        }
      }
    });
  }

  Future<void> _loadFabPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? savedX = prefs.getDouble(_keyFabX);
      double? savedY = prefs.getDouble(_keyFabY);
      if (savedX != null && savedY != null && mounted) {
        _fabPosNotifier.value = Offset(savedX, savedY);
      }
    } catch (_) {}
  }

  Future<void> _saveFabPosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyFabX, x);
      await prefs.setDouble(_keyFabY, y);
    } catch (_) {}
  }

  Future<void> _loadVolFabPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? savedX = prefs.getDouble(_keyVolFabX);
      double? savedY = prefs.getDouble(_keyVolFabY);
      if (savedX != null && savedY != null && mounted) {
        _volPosNotifier.value = Offset(savedX, savedY);
      }
    } catch (_) {}
  }

  Future<void> _saveVolFabPosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyVolFabX, x);
      await prefs.setDouble(_keyVolFabY, y);
    } catch (_) {}
  }

  Future<void> _loadTimerFabPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? savedX = prefs.getDouble(_keyTimerFabX);
      double? savedY = prefs.getDouble(_keyTimerFabY);
      if (savedX != null && savedY != null && mounted) {
        _timerFabPosNotifier.value = Offset(savedX, savedY);
      }
    } catch (_) {}
  }

  Future<void> _saveTimerFabPosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTimerFabX, x);
      await prefs.setDouble(_keyTimerFabY, y);
    } catch (_) {}
  }

  Offset _clampToScreen(Offset pos, Size screenSize, double btnSize) {
    final double minX = 4.0;
    final double minY = 4.0;
    final double maxX = math.max(minX, screenSize.width - btnSize - 4.0);
    final double maxY = math.max(minY, screenSize.height - btnSize - 4.0);

    return Offset(
      pos.dx.clamp(minX, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  Offset _resolveMultiCollision({
    required Offset candidatePos,
    required double candidateSize,
    required List<Map<String, dynamic>> obstacles,
    required Size screenSize,
  }) {
    var pos = candidatePos;

    // 5-Pass Wall-Diverting Relaxation Solver: Guarantees 0% overlap even on physical screen edges
    for (int pass = 0; pass < 5; pass++) {
      pos = _clampToScreen(pos, screenSize, candidateSize);

      for (final obstacle in obstacles) {
        final Offset obsPos = obstacle['pos'] as Offset;
        final double obsSize = obstacle['size'] as double;

        final double minDistance = (candidateSize + obsSize) / 2.0 + 8.0; // 8px buffer spacing
        final Offset candCenter = Offset(pos.dx + candidateSize / 2.0, pos.dy + candidateSize / 2.0);
        final Offset obsCenter = Offset(obsPos.dx + obsSize / 2.0, obsPos.dy + obsSize / 2.0);

        double dx = candCenter.dx - obsCenter.dx;
        double dy = candCenter.dy - obsCenter.dy;
        double dist = math.sqrt(dx * dx + dy * dy);

        if (dist < minDistance) {
          if (dist == 0) {
            dx = 1.0;
            dy = 0.0;
            dist = 1.0;
          }

          final double overlap = minDistance - dist;
          double pushX = (dx / dist) * overlap;
          double pushY = (dy / dist) * overlap;

          double newX = pos.dx + pushX;
          double newY = pos.dy + pushY;

          // Edge Wall Force Redirection: If pushX hits left/right edge wall, divert push force along Y wall!
          if (newX <= 4.0 || newX >= screenSize.width - candidateSize - 4.0) {
            newY += (dy >= 0 ? 1.0 : -1.0) * overlap;
          }
          // If pushY hits top/bottom edge wall, divert push force along X wall!
          if (newY <= 4.0 || newY >= screenSize.height - candidateSize - 4.0) {
            newX += (dx >= 0 ? 1.0 : -1.0) * overlap;
          }

          pos = Offset(newX, newY);
          pos = _clampToScreen(pos, screenSize, candidateSize);
        }
      }
    }

    return pos;
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool offline = results.contains(ConnectivityResult.none);
      setState(() {
        _isOffline = offline;
      });
      if (!offline && _isOffline) {
        _reloadPage();
      }
    });
  }

  void _initWebViewController() {
    final settings = Provider.of<BrowserSettings>(context, listen: false);

    // Initial load uses persistent homepageUrl
    _currentUrl = settings.homepageUrl;
    _lastDesktopMode = settings.desktopMode;

    _webViewController = WebViewController()
      ..setJavaScriptMode(
        settings.javaScriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      )
      ..setUserAgent(
        settings.desktopMode ? _desktopUserAgent : _mobileUserAgent,
      )
      ..setBackgroundColor(BrowserConfig.backgroundColor)
      ..addJavaScriptChannel(
        'FullscreenChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'ENTER') {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            NativeAdblockBridge.enableImmersiveMode();
            setState(() {
              _isBarsVisible = false;
            });
          } else if (message.message == 'EXIT') {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            NativeAdblockBridge.disableImmersiveMode();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
              });
              if (url.isNotEmpty && url != 'about:blank') {
                settings.setHomepageUrl(url);
              }
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              String title = await _webViewController.getTitle() ?? '';
              setState(() {
                _currentUrl = url;
                _pageTitle = title.isNotEmpty ? title : UrlUtils.extractDomain(url);
                _isLoading = false;
              });

              if (url.isNotEmpty && url != 'about:blank') {
                settings.setHomepageUrl(url);
              }

              // Notify native engine of page load and sync stats
              await NativeAdblockBridge.onMainPageLoaded(url);
              await settings.syncStatsFromNative();

              // Apply saved volume boost setting natively to hardware
              if (settings.volumeBoost > 100) {
                settings.setVolumeBoost(settings.volumeBoost);
              }

              // Suppress JS popups silently & attach fullscreen video listener
              _webViewController.runJavaScript('''
                (function() {
                  try {
                    window.open = function() { return null; };
                    document.querySelectorAll('a[target="_blank"]').forEach(function(el) {
                      el.target = '_self';
                    });

                    function notifyFullscreenChange() {
                      var isFS = !!(document.fullscreenElement || document.webkitIsFullScreen || document.mozFullScreen || document.msFullscreenElement);
                      if (window.FullscreenChannel) {
                        window.FullscreenChannel.postMessage(isFS ? 'ENTER' : 'EXIT');
                      }
                    }

                    document.removeEventListener('fullscreenchange', notifyFullscreenChange);
                    document.removeEventListener('webkitfullscreenchange', notifyFullscreenChange);
                    document.addEventListener('fullscreenchange', notifyFullscreenChange);
                    document.addEventListener('webkitfullscreenchange', notifyFullscreenChange);
                  } catch(e) {}
                })();
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final currentSettings = Provider.of<BrowserSettings>(context, listen: false);
            final String targetUrl = request.url;

            // 1. First verify allowlist system
            bool isAllowedByDomain = AllowlistService.isUrlAllowed(targetUrl, currentSettings.allowedDomains);
            if (!isAllowedByDomain) {
              currentSettings.incrementAdCount();
              return NavigationDecision.prevent;
            }

            // 2. Evaluate Centralized Native Navigation Engine (Schemes, Popup Policy, Redirect Loops & Ad Engine)
            final decision = await NativeAdblockBridge.evaluateNavigation(
              targetUrl: targetUrl,
              isMainFrame: request.isMainFrame,
              isUserGesture: true,
            );

            await currentSettings.syncStatsFromNative();

            if (decision['allowed'] == false) {
              return NavigationDecision.prevent;
            }

            // 3. Sanitize tracking parameters
            String cleanUrl = UrlUtils.sanitizeUrl(targetUrl);
            if (cleanUrl != targetUrl) {
              _webViewController.loadRequest(Uri.parse(cleanUrl));
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    if (_webViewController.platform is AndroidWebViewController) {
      final androidController = _webViewController.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setUseWideViewPort(settings.desktopMode);
    }

    _webViewController.loadRequest(Uri.parse(_currentUrl));
  }

  void _toggleBars(BrowserSettings settings) {
    _autoHideTimer?.cancel();

    if (_isBarsVisible) {
      // Hide top/bottom bars & system UI immediately on tap
      setState(() {
        _isBarsVisible = false;
      });
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      NativeAdblockBridge.enableImmersiveMode();
    } else {
      // Show top/bottom bars & system UI, then auto-hide after 5s delay
      setState(() {
        _isBarsVisible = true;
      });
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      NativeAdblockBridge.disableImmersiveMode();

      _autoHideTimer = Timer(Duration(seconds: settings.autoHideDelaySeconds), () {
        if (mounted) {
          setState(() {
            _isBarsVisible = false;
          });
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          NativeAdblockBridge.enableImmersiveMode();
        }
      });
    }
  }

  void _navigateToUrl(String rawUrl, {bool updatePersistent = true}) {
    final settings = Provider.of<BrowserSettings>(context, listen: false);
    String formattedUrl = UrlUtils.formatUrl(rawUrl);
    String sanitizedUrl = UrlUtils.sanitizeUrl(formattedUrl);

    if (!AllowlistService.isUrlAllowed(sanitizedUrl, settings.allowedDomains)) {
      return;
    }

    if (updatePersistent) {
      settings.setHomepageUrl(sanitizedUrl);
    }

    setState(() {
      _currentUrl = sanitizedUrl;
    });

    _webViewController.loadRequest(Uri.parse(sanitizedUrl));
  }

  void _reloadPage() {
    _webViewController.reload();
  }

  void _goHome() {
    final settings = Provider.of<BrowserSettings>(context, listen: false);
    _navigateToUrl(settings.homepageUrl, updatePersistent: false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<BrowserSettings>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    if (settings.isInitialized && !_hasLoadedInitialUrl) {
      _hasLoadedInitialUrl = true;
      if (settings.homepageUrl.isNotEmpty && settings.homepageUrl != _currentUrl) {
        _currentUrl = settings.homepageUrl;
        _webViewController.loadRequest(Uri.parse(_currentUrl));
      }
    }

    _webViewController.setJavaScriptMode(
      settings.javaScriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
    );

    if (_lastDesktopMode != settings.desktopMode) {
      _lastDesktopMode = settings.desktopMode;
      _webViewController.setUserAgent(
        settings.desktopMode ? _desktopUserAgent : _mobileUserAgent,
      );
      if (_webViewController.platform is AndroidWebViewController) {
        final androidController = _webViewController.platform as AndroidWebViewController;
        androidController.setUseWideViewPort(settings.desktopMode);
      }
      _webViewController.reload();
    }

    return Listener(
      onPointerDown: (_) {
        NativeAdblockBridge.registerUserGesture();
      },
      child: Scaffold(
        backgroundColor: BrowserConfig.backgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // 1. Main WebView Container
              Positioned.fill(
                child: Column(
                  children: [
                    // Dynamic Spacer for Top Bar (topInset + 42dp height)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      height: _isBarsVisible ? (padding.top + 42.0) : 0.0,
                    ),

                    if (_isLoading)
                      LinearProgressIndicator(
                        value: _loadingProgress / 100.0,
                        backgroundColor: BrowserConfig.cardColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(BrowserConfig.accentColor),
                        minHeight: 3,
                      ),

                    Expanded(
                      child: _isOffline
                          ? _buildOfflineScreen()
                          : WebViewWidget(controller: _webViewController),
                    ),

                    // Dynamic Spacer for Bottom Bar (40dp height)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      height: _isBarsVisible ? 40.0 : 0.0,
                    ),
                  ],
                ),
              ),

              // 2. Animated Top Bar (Slides UP out of view)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  offset: _isBarsVisible ? Offset.zero : const Offset(0, -1.2),
                  child: CustomToolbar(
                    currentUrl: _currentUrl,
                    onNavigate: _navigateToUrl,
                    onRefresh: _reloadPage,
                    onHome: _goHome,
                  ),
                ),
              ),

              // 3. Animated Bottom Bar (Slides DOWN out of view)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  offset: _isBarsVisible ? Offset.zero : const Offset(0, 1.2),
                  child: BottomStatusBar(pageTitle: _pageTitle),
                ),
              ),

              // 4. Moveable Floating Toggle Button (Ultra-smooth active drag LERP interpolation with multi-collision physics solver)
              ValueListenableBuilder<Offset?>(
                valueListenable: _fabPosNotifier,
                builder: (context, pos, child) {
                  final double fabSize = settings.fabSize;
                  final double defaultMenuX = screenSize.width - fabSize - 8.0;
                  final double defaultMenuY = screenSize.height - fabSize - 90.0;

                  final rawOffset = pos ?? Offset(defaultMenuX, defaultMenuY);
                  final fabOffset = _clampToScreen(rawOffset, screenSize, fabSize);

                  return AnimatedPositioned(
                    duration: _isDraggingFab ? Duration.zero : const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    left: fabOffset.dx,
                    top: fabOffset.dy,
                    child: AnimatedScale(
                      scale: _isDraggingFab ? 0.94 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        onScaleStart: (details) {
                          setState(() {
                            _isDraggingFab = true;
                          });
                          _startFabOffset = _fabPosNotifier.value ?? Offset(defaultMenuX, defaultMenuY);
                          _startFocalPoint = details.focalPoint;
                        },
                        onScaleUpdate: (details) {
                          final delta = details.focalPoint - _startFocalPoint;
                          var targetOffset = Offset(_startFabOffset.dx + delta.dx, _startFabOffset.dy + delta.dy);

                          // Build obstacle list for physics collision solver
                          final defaultVolPos = Offset(8.0, screenSize.height - fabSize - 90.0);
                          final volPos = _clampToScreen(_volPosNotifier.value ?? defaultVolPos, screenSize, fabSize);

                          final List<Map<String, dynamic>> obstacles = [
                            {'pos': volPos, 'size': fabSize},
                          ];

                          if (_showInternalRotationButton) {
                            final rotPos = Offset(screenSize.width - settings.rotationBtnSize - 16.0, screenSize.height - settings.rotationBtnSize - 90.0);
                            obstacles.add({'pos': rotPos, 'size': settings.rotationBtnSize});
                          }

                          targetOffset = _resolveMultiCollision(
                            candidatePos: targetOffset,
                            candidateSize: fabSize,
                            obstacles: obstacles,
                            screenSize: screenSize,
                          );

                          final currentOffset = _fabPosNotifier.value ?? targetOffset;
                          final smoothedOffset = Offset.lerp(currentOffset, targetOffset, 0.55)!;
                          _fabPosNotifier.value = smoothedOffset;
                        },
                        onScaleEnd: (details) {
                          setState(() {
                            _isDraggingFab = false;
                          });
                          final currentPos = _fabPosNotifier.value;
                          if (currentPos != null) {
                            _saveFabPosition(currentPos.dx, currentPos.dy);
                          }
                        },
                        onTap: () {
                          _toggleBars(settings);
                        },
                        child: Opacity(
                          opacity: settings.fabOpacity,
                          child: Material(
                            elevation: settings.fabOpacity > 0 ? 6 : 0,
                            shape: const CircleBorder(),
                            color: Colors.transparent,
                            child: Container(
                              width: fabSize,
                              height: fabSize,
                              decoration: BoxDecoration(
                                color: BrowserConfig.cardColor.withValues(alpha: settings.fabOpacity),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: BrowserConfig.accentColor.withValues(alpha: settings.fabOpacity),
                                  width: 1.5,
                                ),
                                boxShadow: settings.fabOpacity > 0
                                    ? const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                _isBarsVisible ? Icons.unfold_less : Icons.menu,
                                color: BrowserConfig.textColor.withValues(alpha: settings.fabOpacity),
                                size: (fabSize * 0.46).clamp(18.0, 28.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 5. App's Internal Floating Manual Rotation Button (Circular, Animated Rotation Spin, Icon Only)
              if (_showInternalRotationButton)
                Positioned(
                  bottom: 90,
                  right: 20,
                  child: Opacity(
                    opacity: settings.rotationBtnOpacity,
                    child: GestureDetector(
                      onTap: () {
                        _internalRotationTimer?.cancel();
                        setState(() {
                          _showInternalRotationButton = false;
                        });
                        SystemChrome.setPreferredOrientations([_pendingTargetOrientationEnum]);
                      },
                      child: Material(
                        elevation: settings.rotationBtnOpacity > 0 ? 8 : 0,
                        shape: const CircleBorder(),
                        color: Colors.transparent,
                        child: Container(
                          width: settings.rotationBtnSize,
                          height: settings.rotationBtnSize,
                          decoration: BoxDecoration(
                            color: BrowserConfig.cardColor.withValues(alpha: settings.rotationBtnOpacity),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BrowserConfig.accentColor.withValues(alpha: settings.rotationBtnOpacity),
                              width: 1.5,
                            ),
                            boxShadow: settings.rotationBtnOpacity > 0
                                ? const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _ContinuousSpinIcon(size: settings.rotationBtnSize),
                        ),
                      ),
                    ),
                  ),
                ),

              // 6. Draggable Floating Volume Booster Control (Zero-lag 120Hz liquid drag with fixed button position)
              ValueListenableBuilder<Offset?>(
                valueListenable: _volPosNotifier,
                builder: (context, pos, child) {
                  final double fabSize = settings.volumeBtnSize;
                  final double defaultVolY = screenSize.height - fabSize - 90.0;
                  final rawOffset = pos ?? Offset(8.0, defaultVolY);
                  final volOffset = _clampToScreen(rawOffset, screenSize, fabSize);
                  final bool sliderAbove = volOffset.dy > 135.0;
                  const double sliderW = 56.0;
                  const double sliderH = 125.0;
                  final double popupX = (volOffset.dx + (fabSize - sliderW) / 2.0).clamp(4.0, screenSize.width - sliderW - 4.0);
                  final double popupY = sliderAbove
                      ? (volOffset.dy - sliderH - 1.0).clamp(4.0, double.infinity)
                      : (volOffset.dy + fabSize + 1.0).clamp(4.0, screenSize.height - sliderH - 4.0);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Volume Slider Popup (Clean, borderless & backgroundless, perfectly centered over Volume FAB)
                      if (_showVolumeSlider)
                        Positioned(
                          left: popupX,
                          top: popupY,
                          child: _buildVolumeSliderPopup(settings),
                        ),

                      // Volume FAB Button (Fixed position, ZERO sliding movement when clicked!)
                      AnimatedPositioned(
                        duration: _isDraggingVolFab ? Duration.zero : const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        left: volOffset.dx,
                        top: volOffset.dy,
                        child: AnimatedScale(
                          scale: _isDraggingVolFab ? 0.94 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: GestureDetector(
                            onScaleStart: (details) {
                              setState(() {
                                _isDraggingVolFab = true;
                              });
                              _startVolOffset = _volPosNotifier.value ?? Offset(8.0, defaultVolY);
                              _startVolFocalPoint = details.focalPoint;
                            },
                            onScaleUpdate: (details) {
                              final delta = details.focalPoint - _startVolFocalPoint;
                              var targetOffset = Offset(_startVolOffset.dx + delta.dx, _startVolOffset.dy + delta.dy);

                              // Build obstacle list for physics collision solver
                              final defaultMenuPos = Offset(screenSize.width - fabSize - 8.0, defaultVolY);
                              final menuPos = _clampToScreen(_fabPosNotifier.value ?? defaultMenuPos, screenSize, fabSize);

                              final List<Map<String, dynamic>> obstacles = [
                                {'pos': menuPos, 'size': fabSize},
                              ];

                              if (_showInternalRotationButton) {
                                final rotPos = Offset(screenSize.width - settings.rotationBtnSize - 16.0, screenSize.height - settings.rotationBtnSize - 90.0);
                                obstacles.add({'pos': rotPos, 'size': settings.rotationBtnSize});
                              }

                              targetOffset = _resolveMultiCollision(
                                candidatePos: targetOffset,
                                candidateSize: fabSize,
                                obstacles: obstacles,
                                screenSize: screenSize,
                              );

                              final currentOffset = _volPosNotifier.value ?? targetOffset;
                              final smoothedOffset = Offset.lerp(currentOffset, targetOffset, 0.55)!;
                              _volPosNotifier.value = smoothedOffset;
                            },
                            onScaleEnd: (details) {
                              setState(() {
                                _isDraggingVolFab = false;
                              });
                              final currentPos = _volPosNotifier.value;
                              if (currentPos != null) {
                                _saveVolFabPosition(currentPos.dx, currentPos.dy);
                              }
                            },
                            onTap: () {
                              setState(() {
                                _showVolumeSlider = !_showVolumeSlider;
                              });
                              if (_showVolumeSlider) {
                                _startVolumeSliderTimer();
                              } else {
                                _volumeSliderTimer?.cancel();
                              }
                            },
                            child: Opacity(
                              opacity: settings.volumeBtnOpacity,
                              child: Material(
                                elevation: settings.volumeBtnOpacity > 0 ? 8 : 0,
                                shape: const CircleBorder(),
                                color: Colors.transparent,
                                child: Container(
                                  width: fabSize,
                                  height: fabSize,
                                  decoration: BoxDecoration(
                                    color: BrowserConfig.cardColor.withValues(alpha: settings.volumeBtnOpacity),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (settings.volumeBoost > 100
                                              ? BrowserConfig.accentColor
                                              : Colors.white30)
                                          .withValues(alpha: settings.volumeBtnOpacity),
                                      width: 1.5,
                                    ),
                                    boxShadow: settings.volumeBtnOpacity > 0
                                        ? const [
                                            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: _showVolumeSlider
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${settings.volumeBoost}%',
                                                style: TextStyle(
                                                  color: (settings.volumeBoost > 100
                                                          ? BrowserConfig.accentColor
                                                          : BrowserConfig.textColor)
                                                      .withValues(alpha: settings.volumeBtnOpacity),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: (fabSize * 0.32).clamp(10.0, 16.0),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            settings.volumeBoost > 100 ? Icons.volume_up : Icons.volume_down,
                                            color: (settings.volumeBoost > 100
                                                    ? BrowserConfig.accentColor
                                                    : BrowserConfig.textColor)
                                                .withValues(alpha: settings.volumeBtnOpacity),
                                            size: (fabSize * 0.46).clamp(18.0, 28.0),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // 7. Draggable Floating Sleep / Kill App Timer Control (Circular countdown widget with liquid 120Hz physics)
              if (settings.isKillTimerActive)
                ValueListenableBuilder<Offset?>(
                  valueListenable: _timerFabPosNotifier,
                  builder: (context, pos, child) {
                    final double fabSize = settings.fabSize.clamp(44.0, 58.0);
                    final double defaultTimerX = 12.0;
                    final double defaultTimerY = 64.0;
                    final rawOffset = pos ?? Offset(defaultTimerX, defaultTimerY);
                    final timerOffset = _clampToScreen(rawOffset, screenSize, fabSize);

                    return AnimatedPositioned(
                      duration: _isDraggingTimerFab ? Duration.zero : const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      left: timerOffset.dx,
                      top: timerOffset.dy,
                      child: AnimatedScale(
                        scale: _isDraggingTimerFab ? 0.94 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: GestureDetector(
                          onScaleStart: (details) {
                            setState(() {
                              _isDraggingTimerFab = true;
                            });
                            _startTimerOffset = _timerFabPosNotifier.value ?? Offset(defaultTimerX, defaultTimerY);
                            _startTimerFocalPoint = details.focalPoint;
                          },
                          onScaleUpdate: (details) {
                            final delta = details.focalPoint - _startTimerFocalPoint;
                            var targetOffset = Offset(_startTimerOffset.dx + delta.dx, _startTimerOffset.dy + delta.dy);

                            // Build obstacle list for physics collision solver
                            final defaultMenuPos = Offset(screenSize.width - settings.fabSize - 8.0, screenSize.height - settings.fabSize - 90.0);
                            final menuPos = _clampToScreen(_fabPosNotifier.value ?? defaultMenuPos, screenSize, settings.fabSize);

                            final defaultVolPos = Offset(8.0, screenSize.height - settings.volumeBtnSize - 90.0);
                            final volPos = _clampToScreen(_volPosNotifier.value ?? defaultVolPos, screenSize, settings.volumeBtnSize);

                            final List<Map<String, dynamic>> obstacles = [
                              {'pos': menuPos, 'size': settings.fabSize},
                              {'pos': volPos, 'size': settings.volumeBtnSize},
                            ];

                            if (_showInternalRotationButton) {
                              final rotPos = Offset(screenSize.width - settings.rotationBtnSize - 16.0, screenSize.height - settings.rotationBtnSize - 90.0);
                              obstacles.add({'pos': rotPos, 'size': settings.rotationBtnSize});
                            }

                            targetOffset = _resolveMultiCollision(
                              candidatePos: targetOffset,
                              candidateSize: fabSize,
                              obstacles: obstacles,
                              screenSize: screenSize,
                            );

                            final currentOffset = _timerFabPosNotifier.value ?? targetOffset;
                            final smoothedOffset = Offset.lerp(currentOffset, targetOffset, 0.55)!;
                            _timerFabPosNotifier.value = smoothedOffset;
                          },
                          onScaleEnd: (details) {
                            setState(() {
                              _isDraggingTimerFab = false;
                            });
                            final currentPos = _timerFabPosNotifier.value;
                            if (currentPos != null) {
                              _saveTimerFabPosition(currentPos.dx, currentPos.dy);
                            }
                          },
                          onTap: () {
                            _showTimerQuickDialog(context, settings);
                          },
                          child: Opacity(
                            opacity: settings.fabOpacity,
                            child: Material(
                              elevation: settings.fabOpacity > 0 ? 8 : 0,
                              shape: const CircleBorder(),
                              color: Colors.transparent,
                              child: Container(
                                width: fabSize,
                                height: fabSize,
                                decoration: BoxDecoration(
                                  color: BrowserConfig.cardColor.withValues(alpha: settings.fabOpacity),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: BrowserConfig.accentColor.withValues(alpha: settings.fabOpacity),
                                    width: 1.5,
                                  ),
                                  boxShadow: settings.fabOpacity > 0
                                      ? const [
                                          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Progress Ring around the edge
                                    SizedBox(
                                      width: fabSize - 4,
                                      height: fabSize - 4,
                                      child: CircularProgressIndicator(
                                        value: settings.killTimerProgress,
                                        strokeWidth: 2.5,
                                        backgroundColor: Colors.white12,
                                        valueColor: const AlwaysStoppedAnimation(BrowserConfig.accentColor),
                                      ),
                                    ),
                                    // Countdown Timer Content
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.hourglass_top,
                                              size: 10,
                                              color: BrowserConfig.accentColor,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              settings.formattedKillTimerRemaining,
                                              style: TextStyle(
                                                color: BrowserConfig.textColor.withValues(alpha: settings.fabOpacity),
                                                fontWeight: FontWeight.bold,
                                                fontSize: (fabSize * 0.22).clamp(9.0, 13.0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimerQuickDialog(BuildContext context, BrowserSettings settings) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<BrowserSettings>(
          builder: (context, liveSettings, child) {
            return AlertDialog(
              backgroundColor: BrowserConfig.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: BrowserConfig.accentColor),
                  SizedBox(width: 8),
                  Text(
                    'Sleep Timer (Kill App)',
                    style: TextStyle(color: BrowserConfig.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    liveSettings.formattedKillTimerRemaining,
                    style: const TextStyle(
                      color: BrowserConfig.accentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'App will automatically close when timer ends',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: liveSettings.killTimerProgress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(BrowserConfig.accentColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrowserConfig.accentColor,
                          side: const BorderSide(color: BrowserConfig.accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          final currentMins = (liveSettings.killAppRemainingSeconds / 60).ceil();
                          liveSettings.startKillTimer(currentMins + 5);
                        },
                        child: const Text('+5 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrowserConfig.accentColor,
                          side: const BorderSide(color: BrowserConfig.accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          final currentMins = (liveSettings.killAppRemainingSeconds / 60).ceil();
                          liveSettings.startKillTimer(currentMins + 15);
                        },
                        child: const Text('+15 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrowserConfig.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text('Cancel Timer', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    liveSettings.resetKillTimer();
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVolumeSliderPopup(BrowserSettings settings) {
    return Opacity(
      opacity: settings.volumeSliderOpacity,
      child: SizedBox(
        height: 125,
        width: 56,
        child: RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderThemeData(
              trackShape: const _ZeroPaddingSliderTrackShape(),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: BrowserConfig.accentColor,
              inactiveTrackColor: Colors.white30,
              thumbColor: BrowserConfig.accentColor,
              trackHeight: 7.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
            ),
            child: Slider(
              value: settings.volumeBoost.toDouble().clamp(100.0, 400.0),
              min: 100.0,
              max: 400.0,
              divisions: 30,
              onChanged: (val) {
                settings.setVolumeBoost(val.round());
                _startVolumeSliderTimer();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Container(
      color: BrowserConfig.backgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 72,
              color: BrowserConfig.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                color: BrowserConfig.textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your network settings and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reloadPage,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrowserConfig.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinuousSpinIcon extends StatefulWidget {
  final double size;
  const _ContinuousSpinIcon({required this.size});

  @override
  State<_ContinuousSpinIcon> createState() => _ContinuousSpinIconState();
}

class _ContinuousSpinIconState extends State<_ContinuousSpinIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.screen_rotation,
        color: BrowserConfig.accentColor,
        size: (widget.size * 0.52).clamp(18.0, 30.0),
      ),
    );
  }
}

class _ZeroPaddingSliderTrackShape extends RoundedRectSliderTrackShape {
  const _ZeroPaddingSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 7.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2.0;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
