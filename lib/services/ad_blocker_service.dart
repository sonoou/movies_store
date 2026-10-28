import '../models/browser_config.dart';
import '../utils/url_utils.dart';

class AdBlockerService {
  /// Fast check if a URL should be blocked as an ad or tracker
  static bool shouldBlockUrl(String url) {
    if (url.isEmpty || url.startsWith('data:') || url.startsWith('blob:')) {
      return false;
    }

    String lowerUrl = url.toLowerCase();

    // 1. Check Domain Match
    try {
      String domain = UrlUtils.extractDomain(url).toLowerCase();
      for (String adDomain in BrowserConfig.adDomains) {
        String cleanAdDomain = adDomain.toLowerCase();
        if (domain == cleanAdDomain || domain.endsWith('.$cleanAdDomain')) {
          return true;
        }
      }
    } catch (_) {}

    // 2. Check URL Patterns Match
    for (String pattern in BrowserConfig.adUrlPatterns) {
      if (lowerUrl.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
