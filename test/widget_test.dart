import 'package:flutter_test/flutter_test.dart';
import 'package:secure_browser/models/browser_config.dart';
import 'package:secure_browser/services/allowlist_service.dart';
import 'package:secure_browser/utils/url_utils.dart';

void main() {
  test('AllowlistService allows domains in default allowlist', () {
    expect(
      AllowlistService.isUrlAllowed('https://onlyflix.to/movie', BrowserConfig.defaultAllowlist),
      isTrue,
    );
    expect(
      AllowlistService.isUrlAllowed('https://bingr.one/', BrowserConfig.defaultAllowlist),
      isTrue,
    );
    expect(
      AllowlistService.isUrlAllowed('https://malicious-ad-domain.com', BrowserConfig.defaultAllowlist),
      isFalse,
    );
  });

  test('UrlUtils strips tracking parameters correctly', () {
    const dirtyUrl = 'https://onlyflix.to/?utm_source=ad&fbclid=123&clean=1';
    final cleaned = UrlUtils.sanitizeUrl(dirtyUrl);
    expect(cleaned.contains('utm_source'), isFalse);
    expect(cleaned.contains('fbclid'), isFalse);
    expect(cleaned.contains('clean=1'), isTrue);
  });
}
