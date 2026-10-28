import '../utils/url_utils.dart';

class AllowlistService {
  /// Checks if a given URL is allowed based on the allowlist domains
  static bool isUrlAllowed(String url, List<String> allowedDomains) {
    if (url.trim().isEmpty || url == 'about:blank' || url.startsWith('data:') || url.startsWith('blob:') || url.startsWith('javascript:')) return true;
    
    try {
      String targetDomain = UrlUtils.extractDomain(url).toLowerCase();
      if (targetDomain.isEmpty) return true;

      for (String allowed in allowedDomains) {
        String cleanAllowed = allowed.toLowerCase().trim().replaceFirst(RegExp(r'^https?:\/\/'), '');
        if (cleanAllowed.startsWith('www.')) cleanAllowed = cleanAllowed.substring(4);
        String hostOnly = cleanAllowed.split('/')[0].trim();

        if (targetDomain == cleanAllowed ||
            targetDomain == hostOnly ||
            targetDomain.endsWith('.$hostOnly') ||
            hostOnly.endsWith('.$targetDomain')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Preserves exact domain entries for UI display
  static List<String> getUniqueDomains(List<String> rawDomains) {
    Set<String> set = {};
    for (String d in rawDomains) {
      String clean = d.trim().toLowerCase();
      if (clean.isNotEmpty) {
        set.add(clean);
      }
    }
    return set.toList();
  }
}
