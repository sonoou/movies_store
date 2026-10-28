import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/browser_config.dart';
import '../models/browser_settings.dart';
import '../utils/url_utils.dart';
import 'settings_menu.dart';

class CustomToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String currentUrl;
  final Function(String) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onHome;

  const CustomToolbar({
    super.key,
    required this.currentUrl,
    required this.onNavigate,
    required this.onRefresh,
    required this.onHome,
  });

  @override
  Size get preferredSize => const Size.fromHeight(42.0);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<BrowserSettings>(context);
    final allowedDomains = settings.allowedDomains;
    final isHttps = UrlUtils.isHttps(currentUrl);
    final topInset = MediaQuery.of(context).padding.top;

    String currentDomain = UrlUtils.extractDomain(currentUrl);
    String? selectedValue;
    for (String domain in allowedDomains) {
      String cleanDomain = domain.toLowerCase().trim();
      String baseDomain = cleanDomain.startsWith('www.') ? cleanDomain.substring(4) : cleanDomain;
      if (currentDomain == cleanDomain || currentDomain == baseDomain || currentDomain.endsWith('.$baseDomain')) {
        selectedValue = domain;
        break;
      }
    }

    return Container(
      color: BrowserConfig.primaryColor,
      padding: EdgeInsets.only(top: topInset, left: 6, right: 6, bottom: 4),
      child: SizedBox(
        height: 38.0,
        child: Row(
          children: [
            // 1. LEFT: Dropdown Button showing Allowlist Websites
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: BrowserConfig.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  menuMaxHeight: 280.0,
                  icon: settings.isFetchingAllowlist
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(BrowserConfig.accentColor),
                          ),
                        )
                      : const Icon(Icons.arrow_drop_down, color: BrowserConfig.textColor, size: 20),
                  dropdownColor: BrowserConfig.cardColor,
                  hint: settings.isFetchingAllowlist
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(BrowserConfig.accentColor),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Updating...',
                              style: TextStyle(color: BrowserConfig.textColor, fontSize: 12),
                            ),
                          ],
                        )
                      : Text(
                          '${allowedDomains.length} Sites',
                          style: const TextStyle(color: BrowserConfig.textColor, fontSize: 12),
                        ),
                  style: const TextStyle(color: BrowserConfig.textColor, fontSize: 12),
                  onChanged: (String? selectedDomain) async {
                    if (selectedDomain == '__REFRESH_ALLOWLIST__') {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Fetching latest allowlist...'),
                            ],
                          ),
                          backgroundColor: BrowserConfig.primaryColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      final success = await settings.fetchRemoteAllowlist();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Allowlist updated successfully (${settings.allowedDomains.length} sites)!'
                                  : 'Could not fetch remote list. Using cached list.',
                            ),
                            backgroundColor: success ? BrowserConfig.accentColor : BrowserConfig.errorColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }
                    if (selectedDomain != null && selectedDomain.isNotEmpty) {
                      onNavigate(UrlUtils.formatUrl(selectedDomain));
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      // Item 0: Corresponds to '__REFRESH_ALLOWLIST__'
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, color: BrowserConfig.accentColor, size: 14),
                          SizedBox(width: 4),
                          Text('Refresh', style: TextStyle(color: BrowserConfig.accentColor, fontSize: 12)),
                        ],
                      ),
                      // Items 1..N: Correspond to allowedDomains
                      ...allowedDomains.asMap().entries.map<Widget>((entry) {
                        int sn = entry.key + 1;
                        String domain = entry.value;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$sn. ',
                              style: const TextStyle(
                                color: BrowserConfig.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              domain,
                              style: const TextStyle(
                                color: BrowserConfig.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }),
                    ];
                  },
                  items: [
                    // Top Item: Refresh Button inside dropdown
                    DropdownMenuItem<String>(
                      value: '__REFRESH_ALLOWLIST__',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            if (settings.isFetchingAllowlist)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(BrowserConfig.accentColor),
                                ),
                              )
                            else
                              const Icon(Icons.sync, color: BrowserConfig.accentColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                settings.isFetchingAllowlist ? 'Updating allowlist...' : 'Refresh Allowlist',
                                style: const TextStyle(
                                  color: BrowserConfig.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: BrowserConfig.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: BrowserConfig.accentColor.withValues(alpha: 0.6), width: 0.5),
                              ),
                              child: Text(
                                '${allowedDomains.length}',
                                style: const TextStyle(
                                  color: BrowserConfig.textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // All Allowlisted Websites
                    ...allowedDomains.asMap().entries.map<DropdownMenuItem<String>>((entry) {
                      int sn = entry.key + 1;
                      String domain = entry.value;
                      return DropdownMenuItem<String>(
                        value: domain,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: BrowserConfig.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: BrowserConfig.accentColor.withValues(alpha: 0.6), width: 0.5),
                              ),
                              child: Text(
                                '$sn.',
                                style: const TextStyle(
                                  color: BrowserConfig.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              domain,
                              style: const TextStyle(
                                color: BrowserConfig.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 2. CENTER (MID): Location Bar (Editable = false / Read Only!)
            Expanded(
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: BrowserConfig.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHttps ? BrowserConfig.accentColor.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHttps ? Icons.lock : Icons.lock_open,
                      color: isHttps ? BrowserConfig.accentColor : BrowserConfig.warningColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        currentUrl,
                        style: const TextStyle(
                          color: BrowserConfig.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 3. RIGHT: Three Vertical Dots (Settings Menu)
            SettingsMenu(
              currentUrl: currentUrl,
              onRefresh: onRefresh,
              onHome: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
