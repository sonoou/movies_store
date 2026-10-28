import 'package:flutter/services.dart';

class NativeAdblockBridge {
  static const MethodChannel _channel = MethodChannel('com.sonoou.movies/adblock');

  /// Fetches real-time statistics for ads, trackers, popups, redirects, and external intents
  static Future<Map<String, int>> getBlockedStats() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getBlockedStats');
      if (result != null) {
        return {
          'ads': (result['ads'] as int?) ?? 0,
          'trackers': (result['trackers'] as int?) ?? 0,
          'popups': (result['popups'] as int?) ?? 0,
          'redirects': (result['redirects'] as int?) ?? 0,
          'externalIntents': (result['externalIntents'] as int?) ?? 0,
        };
      }
    } catch (e) {
      // Fallback if platform channel unavailable
    }
    return {'ads': 0, 'trackers': 0, 'popups': 0, 'redirects': 0, 'externalIntents': 0};
  }

  /// Centralized navigation decision pipeline evaluation
  static Future<Map<String, dynamic>> evaluateNavigation({
    required String targetUrl,
    bool isMainFrame = true,
    bool isUserGesture = false,
  }) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('evaluateNavigation', {
        'targetUrl': targetUrl,
        'isMainFrame': isMainFrame,
        'isUserGesture': isUserGesture,
      });
      if (result != null) {
        return {
          'allowed': (result['allowed'] as bool?) ?? true,
          'reason': (result['reason'] as String?) ?? 'ALLOWED',
          'action': (result['action'] as String?) ?? 'ALLOW_IN_WEBVIEW',
        };
      }
    } catch (_) {}
    return {'allowed': true, 'reason': 'ALLOWED', 'action': 'ALLOW_IN_WEBVIEW'};
  }

  /// Evaluates popup/window.open requests against PopupController policy & rate limits
  static Future<bool> evaluatePopup({
    required String targetUrl,
    required String sourceUrl,
  }) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('evaluatePopup', {
        'targetUrl': targetUrl,
        'sourceUrl': sourceUrl,
      });
      if (result != null) {
        return (result['allowed'] as bool?) ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Registers user gesture (touch/click/tap) for policy checks
  static Future<void> registerUserGesture() async {
    try {
      await _channel.invokeMethod('registerUserGesture');
    } catch (_) {}
  }

  /// Updates popup policy: BLOCK_ALL_UNREQUESTED, ALLOW_USER_GESTURE, ALLOW_WHITELISTED, ALLOW_ALL
  static Future<void> setPopupPolicy(String policy) async {
    try {
      await _channel.invokeMethod('setPopupPolicy', {'policy': policy});
    } catch (_) {}
  }

  /// Updates whitelisted domains list in native engine
  static Future<void> updateWhitelist(List<String> domains) async {
    try {
      await _channel.invokeMethod('updateWhitelist', {'domains': domains});
    } catch (_) {}
  }

  /// Resets stats counters
  static Future<void> resetStats() async {
    try {
      await _channel.invokeMethod('resetStats');
    } catch (_) {}
  }

  /// Notifies native engine when main page finishes loading
  static Future<void> onMainPageLoaded(String url) async {
    try {
      await _channel.invokeMethod('onMainPageLoaded', {'url': url});
    } catch (_) {}
  }

  /// Hides status bar and navigation bar in video fullscreen
  static Future<void> enableImmersiveMode() async {
    try {
      await _channel.invokeMethod('enableImmersiveMode');
    } catch (_) {}
  }

  /// Restores status bar and navigation bar
  static Future<void> disableImmersiveMode() async {
    try {
      await _channel.invokeMethod('disableImmersiveMode');
    } catch (_) {}
  }

  /// Sets preferred display refresh rate (MAX, 60, 90, 120)
  static Future<void> setRefreshRate(String fps) async {
    try {
      await _channel.invokeMethod('setRefreshRate', {'fps': fps});
    } catch (_) {}
  }
}
