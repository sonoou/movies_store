import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'browser_config.dart';
import '../services/native_adblock_bridge.dart';

class BrowserSettings extends ChangeNotifier {
  static const String _keyJsEnabled = 'js_enabled';
  static const String _keyAdBlockEnabled = 'adblock_enabled';
  static const String _keyHomepage = 'homepage_url';
  static const String _keyAllowedDomains = 'allowed_domains';
  static const String _keyPerSiteAdAllowed = 'persite_ad_allowed_';
  static const String _keyPopupPolicy = 'popup_policy';
  static const String _keyHideBarsInLandscape = 'hide_bars_in_landscape';
  static const String _keyAutoHideSystemUi = 'auto_hide_system_ui';
  static const String _keyAutoHideDelaySeconds = 'auto_hide_delay_seconds';
  static const String _keyFpsOption = 'fps_option';
  static const String _keyFabSize = 'fab_size';
  static const String _keyAppAutoRotate = 'app_auto_rotate';
  static const String _keyRotationBtnSize = 'rotation_btn_size';
  static const String _keyVolumeBtnSize = 'volume_btn_size';
  static const String _keyFabOpacity = 'fab_opacity';
  static const String _keyRotationBtnOpacity = 'rotation_btn_opacity';
  static const String _keyVolumeBtnOpacity = 'volume_btn_opacity';
  static const String _keyVolumeSliderOpacity = 'volume_slider_opacity';
  static const String _keyVolumeBoost = 'volume_boost';
  static const String _keyVolumeSliderMode = 'volume_slider_mode';
  static const String _keyVolumeSliderAutoDelay = 'volume_slider_auto_delay';
  static const String _keyDesktopMode = 'desktop_mode';
  static const String _keyDomainVisitCounts = 'domain_visit_counts';

  Map<String, int> _domainVisitCounts = {};

  bool _javaScriptEnabled = true;
  bool _adBlockerEnabled = true;
  bool _desktopMode = false;
  String _homepageUrl = BrowserConfig.defaultHomepage;
  List<String> _allowedDomains = List.from(BrowserConfig.defaultAllowlist);
  String _popupPolicy = 'ALLOW_USER_GESTURE';
  bool _isInitialized = false;

  bool _hideBarsInLandscape = true;
  bool _autoHideSystemUi = true;
  int _autoHideDelaySeconds = 5;
  String _fpsOption = 'MAX';
  double _fabSize = 46.0;
  bool _appAutoRotate = false;
  double _rotationBtnSize = 46.0;
  double _volumeBtnSize = 46.0;
  double _fabOpacity = 0.9;
  double _rotationBtnOpacity = 0.95;
  double _volumeBtnOpacity = 0.9;
  double _volumeSliderOpacity = 0.95;
  int _volumeBoost = 100;
  String _volumeSliderMode = 'AUTO';
  int _volumeSliderAutoDelay = 5;

  // Kill App / Sleep Timer State
  Timer? _killAppTimer;
  int _killAppTotalSeconds = 0;
  int _killAppRemainingSeconds = 0;
  int? _selectedKillAppMinutes;

  Map<String, int> _blockedStats = {
    'ads': 0,
    'trackers': 0,
    'popups': 0,
    'redirects': 0,
    'externalIntents': 0,
  };

  final Map<String, bool> _perSiteAdAllowedMap = {};

  bool get javaScriptEnabled => _javaScriptEnabled;
  bool get adBlockerEnabled => _adBlockerEnabled;
  bool get desktopMode => _desktopMode;
  String get homepageUrl => _homepageUrl;
  List<String> get allowedDomains => List.unmodifiable(_allowedDomains);
  String get popupPolicy => _popupPolicy;
  bool get isInitialized => _isInitialized;
  bool get hideBarsInLandscape => _hideBarsInLandscape;
  bool get autoHideSystemUi => _autoHideSystemUi;
  int get autoHideDelaySeconds => _autoHideDelaySeconds;
  String get fpsOption => _fpsOption;
  double get fabSize => _fabSize;
  bool get appAutoRotate => _appAutoRotate;
  double get rotationBtnSize => _rotationBtnSize;
  double get volumeBtnSize => _volumeBtnSize;
  double get fabOpacity => _fabOpacity;
  double get rotationBtnOpacity => _rotationBtnOpacity;
  double get volumeBtnOpacity => _volumeBtnOpacity;
  double get volumeSliderOpacity => _volumeSliderOpacity;
  int get volumeBoost => _volumeBoost;
  String get volumeSliderMode => _volumeSliderMode;
  int get volumeSliderAutoDelay => _volumeSliderAutoDelay;

  // Kill App Timer Getters
  bool get isKillTimerActive => _killAppRemainingSeconds > 0;
  int get killAppRemainingSeconds => _killAppRemainingSeconds;
  int get killAppTotalSeconds => _killAppTotalSeconds;
  int? get selectedKillAppMinutes => _selectedKillAppMinutes;

  double get killTimerProgress {
    if (_killAppTotalSeconds <= 0) return 0.0;
    return (_killAppRemainingSeconds / _killAppTotalSeconds).clamp(0.0, 1.0);
  }

  String get formattedKillTimerRemaining {
    if (_killAppRemainingSeconds <= 0) return '00:00';
    final int hours = _killAppRemainingSeconds ~/ 3600;
    final int minutes = (_killAppRemainingSeconds % 3600) ~/ 60;
    final int seconds = _killAppRemainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedShortKillTimer {
    if (_killAppRemainingSeconds <= 0) return '0s';
    final int hours = _killAppRemainingSeconds ~/ 3600;
    final int minutes = (_killAppRemainingSeconds % 3600) ~/ 60;
    final int seconds = _killAppRemainingSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Map<String, int> get blockedStats => Map.unmodifiable(_blockedStats);
  int get adCount => _blockedStats['ads']! + _blockedStats['popups']! + _blockedStats['redirects']!;

  BrowserSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _javaScriptEnabled = prefs.getBool(_keyJsEnabled) ?? true;
      _adBlockerEnabled = prefs.getBool(_keyAdBlockEnabled) ?? true;
      _desktopMode = prefs.getBool(_keyDesktopMode) ?? false;
      _homepageUrl = prefs.getString(_keyHomepage) ?? BrowserConfig.defaultHomepage;
      _popupPolicy = prefs.getString(_keyPopupPolicy) ?? 'ALLOW_USER_GESTURE';

      _hideBarsInLandscape = prefs.getBool(_keyHideBarsInLandscape) ?? true;
      _autoHideSystemUi = prefs.getBool(_keyAutoHideSystemUi) ?? true;
      _autoHideDelaySeconds = prefs.getInt(_keyAutoHideDelaySeconds) ?? 5;
      _fpsOption = prefs.getString(_keyFpsOption) ?? 'MAX';
      _fabSize = prefs.getDouble(_keyFabSize) ?? 46.0;
      _appAutoRotate = prefs.getBool(_keyAppAutoRotate) ?? false;
      _rotationBtnSize = prefs.getDouble(_keyRotationBtnSize) ?? 46.0;
      _volumeBtnSize = prefs.getDouble(_keyVolumeBtnSize) ?? 46.0;
      _fabOpacity = prefs.getDouble(_keyFabOpacity) ?? 0.9;
      _rotationBtnOpacity = prefs.getDouble(_keyRotationBtnOpacity) ?? 0.95;
      _volumeBtnOpacity = prefs.getDouble(_keyVolumeBtnOpacity) ?? 0.9;
      _volumeSliderOpacity = prefs.getDouble(_keyVolumeSliderOpacity) ?? 0.95;
      _volumeBoost = prefs.getInt(_keyVolumeBoost) ?? 100;
      _volumeSliderMode = prefs.getString(_keyVolumeSliderMode) ?? 'AUTO';
      _volumeSliderAutoDelay = prefs.getInt(_keyVolumeSliderAutoDelay) ?? 5;

      final countsStr = prefs.getString(_keyDomainVisitCounts);
      if (countsStr != null && countsStr.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(countsStr);
          _domainVisitCounts = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
        } catch (_) {}
      }

      _allowedDomains = List.from(BrowserConfig.defaultAllowlist);
      await prefs.setStringList(_keyAllowedDomains, _allowedDomains);

      await NativeAdblockBridge.updateWhitelist(_allowedDomains);
      await NativeAdblockBridge.setPopupPolicy(_popupPolicy);
      await NativeAdblockBridge.setRefreshRate(_fpsOption);
      await syncStatsFromNative();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  int getDomainVisitCount(String domain) {
    String clean = domain.trim().toLowerCase();
    if (clean.startsWith('www.')) clean = clean.substring(4);
    return _domainVisitCounts[clean] ?? 0;
  }

  Future<void> recordDomainVisit(String rawUrlOrDomain) async {
    if (rawUrlOrDomain.isEmpty) return;
    String host = rawUrlOrDomain.trim().toLowerCase();
    try {
      final uri = Uri.parse(host.contains('://') ? host : 'https://$host');
      if (uri.host.isNotEmpty) {
        host = uri.host.toLowerCase();
      }
    } catch (_) {}
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    if (host.isEmpty) return;

    _domainVisitCounts[host] = (_domainVisitCounts[host] ?? 0) + 1;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDomainVisitCounts, jsonEncode(_domainVisitCounts));
  }

  Future<void> syncStatsFromNative() async {
    final stats = await NativeAdblockBridge.getBlockedStats();
    _blockedStats = stats;
    notifyListeners();
  }

  Future<void> setPopupPolicy(String policy) async {
    _popupPolicy = policy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPopupPolicy, policy);
    await NativeAdblockBridge.setPopupPolicy(policy);
  }

  Future<void> toggleHideBarsInLandscape(bool enabled) async {
    _hideBarsInLandscape = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideBarsInLandscape, enabled);
  }

  Future<void> toggleAutoHideSystemUi(bool enabled) async {
    _autoHideSystemUi = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoHideSystemUi, enabled);
  }

  Future<void> setAutoHideDelaySeconds(int seconds) async {
    _autoHideDelaySeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoHideDelaySeconds, seconds);
  }

  Future<void> setFpsOption(String option) async {
    _fpsOption = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFpsOption, option);
    await NativeAdblockBridge.setRefreshRate(option);
  }

  Future<void> setFabSize(double size) async {
    _fabSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFabSize, size);
  }

  Future<void> toggleAppAutoRotate(bool enabled) async {
    _appAutoRotate = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppAutoRotate, enabled);
  }

  Future<void> setRotationBtnSize(double size) async {
    _rotationBtnSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRotationBtnSize, size);
  }

  Future<void> setVolumeBtnSize(double size) async {
    _volumeBtnSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolumeBtnSize, size);
  }

  Future<void> setFabOpacity(double opacity) async {
    _fabOpacity = opacity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFabOpacity, opacity);
  }

  Future<void> setRotationBtnOpacity(double opacity) async {
    _rotationBtnOpacity = opacity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRotationBtnOpacity, opacity);
  }

  Future<void> setVolumeBtnOpacity(double opacity) async {
    _volumeBtnOpacity = opacity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolumeBtnOpacity, opacity);
  }

  Future<void> setVolumeSliderOpacity(double opacity) async {
    _volumeSliderOpacity = opacity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolumeSliderOpacity, opacity);
  }

  Future<void> setVolumeSliderMode(String mode) async {
    _volumeSliderMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVolumeSliderMode, mode);
  }

  Future<void> setVolumeSliderAutoDelay(int seconds) async {
    _volumeSliderAutoDelay = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVolumeSliderAutoDelay, seconds);
  }

  Future<void> setVolumeBoost(int percent) async {
    _volumeBoost = percent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVolumeBoost, percent);

    try {
      final channel = MethodChannel('com.sonoou.movies/adblock');
      await channel.invokeMethod('setVolumeBoost', {'boostPercent': percent});
    } catch (_) {}
  }

  Future<void> toggleJavaScript(bool enabled) async {
    _javaScriptEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyJsEnabled, enabled);
  }

  Future<void> toggleAdBlocker(bool enabled) async {
    _adBlockerEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdBlockEnabled, enabled);
  }

  Future<void> toggleDesktopMode(bool enabled) async {
    _desktopMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDesktopMode, enabled);
  }

  bool isAdAllowedForSite(String domain) {
    return _perSiteAdAllowedMap[domain] ?? false;
  }

  Future<void> toggleAllowAdsForSite(String domain, bool allow) async {
    _perSiteAdAllowedMap[domain] = allow;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPerSiteAdAllowed$domain', allow);
  }

  Future<void> setHomepageUrl(String url) async {
    _homepageUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHomepage, url);
  }

  Future<void> addAllowedDomain(String domain) async {
    String cleanDomain = domain.trim().toLowerCase();
    if (!_allowedDomains.contains(cleanDomain)) {
      _allowedDomains.add(cleanDomain);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyAllowedDomains, _allowedDomains);
      await NativeAdblockBridge.updateWhitelist(_allowedDomains);
    }
  }

  Future<void> removeAllowedDomain(String domain) async {
    _allowedDomains.remove(domain);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAllowedDomains, _allowedDomains);
    await NativeAdblockBridge.updateWhitelist(_allowedDomains);
  }

  Future<void> resetAllowedDomains() async {
    _allowedDomains = List.from(BrowserConfig.defaultAllowlist);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAllowedDomains, _allowedDomains);
    await NativeAdblockBridge.updateWhitelist(_allowedDomains);
  }

  void incrementAdCount() {
    _blockedStats['ads'] = (_blockedStats['ads'] ?? 0) + 1;
    notifyListeners();
  }

  void resetAdCount() async {
    _blockedStats = {'ads': 0, 'trackers': 0, 'popups': 0, 'redirects': 0, 'externalIntents': 0};
    await NativeAdblockBridge.resetStats();
    notifyListeners();
  }

  void startKillTimer(int minutes) {
    if (minutes <= 0) {
      resetKillTimer();
      return;
    }
    _killAppTimer?.cancel();
    _selectedKillAppMinutes = minutes;
    _killAppTotalSeconds = minutes * 60;
    _killAppRemainingSeconds = minutes * 60;
    notifyListeners();

    _killAppTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_killAppRemainingSeconds > 1) {
        _killAppRemainingSeconds--;
        notifyListeners();
      } else {
        _executeAppKill();
      }
    });
  }

  void resetKillTimer() {
    _killAppTimer?.cancel();
    _killAppTimer = null;
    _selectedKillAppMinutes = null;
    _killAppTotalSeconds = 0;
    _killAppRemainingSeconds = 0;
    notifyListeners();
  }

  void _executeAppKill() {
    _killAppTimer?.cancel();
    _killAppTimer = null;
    _selectedKillAppMinutes = null;
    _killAppTotalSeconds = 0;
    _killAppRemainingSeconds = 0;
    notifyListeners();

    try {
      SystemNavigator.pop(animated: true);
    } catch (_) {}
    try {
      exit(0);
    } catch (_) {}
  }
}
