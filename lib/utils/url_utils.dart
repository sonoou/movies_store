import 'package:flutter/foundation.dart';

class UrlUtils {
  /// Default tracking parameters to strip
  static const List<String> trackingParameters = [
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'fbclid',
    'gclid',
    'msclkid',
    'ref',
    'source',
    'cid',
    'partner',
    'affiliate',
  ];

  /// Ensures URL has a scheme (defaults to https://)
  static String formatUrl(String rawUrl) {
    String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return 'https://onlyflix.to/';
    
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  /// Checks if URL is HTTPS
  static bool isHttps(String url) {
    return url.trim().toLowerCase().startsWith('https://');
  }

  /// Extracts the hostname/domain from a URL
  static String extractDomain(String urlString) {
    try {
      String formatted = formatUrl(urlString);
      Uri uri = Uri.parse(formatted);
      String host = uri.host.toLowerCase();
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (e) {
      debugPrint('Error extracting domain: $e');
      return urlString;
    }
  }

  /// Removes tracking parameters from a URL string
  static String sanitizeUrl(String urlString) {
    try {
      Uri uri = Uri.parse(urlString);
      if (!uri.hasQuery) return urlString;

      Map<String, String> queryParams = Map.from(uri.queryParameters);
      bool modified = false;

      for (String param in trackingParameters) {
        if (queryParams.containsKey(param)) {
          queryParams.remove(param);
          modified = true;
        }
      }

      // Also clean any param starting with utm_
      queryParams.removeWhere((key, value) {
        if (key.toLowerCase().startsWith('utm_')) {
          modified = true;
          return true;
        }
        return false;
      });

      if (!modified) return urlString;

      return uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams).toString();
    } catch (e) {
      return urlString;
    }
  }
}
