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
                  icon: const Icon(Icons.arrow_drop_down, color: BrowserConfig.textColor, size: 20),
                  dropdownColor: BrowserConfig.cardColor,
                  hint: Text(
                    '${allowedDomains.length} Sites',
                    style: const TextStyle(color: BrowserConfig.textColor, fontSize: 12),
                  ),
                  style: const TextStyle(color: BrowserConfig.textColor, fontSize: 12),
                  onChanged: (String? selectedDomain) {
                    if (selectedDomain != null && selectedDomain.isNotEmpty) {
                      onNavigate(UrlUtils.formatUrl(selectedDomain));
                    }
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return allowedDomains.asMap().entries.map<Widget>((entry) {
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
                    }).toList();
                  },
                  items: allowedDomains.asMap().entries.map<DropdownMenuItem<String>>((entry) {
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
                  }).toList(),
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
