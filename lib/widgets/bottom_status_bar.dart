import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/browser_config.dart';
import '../models/browser_settings.dart';

class BottomStatusBar extends StatelessWidget {
  final String pageTitle;

  const BottomStatusBar({
    super.key,
    required this.pageTitle,
  });

  void _showStatsDialog(BuildContext context, BrowserSettings settings) {
    final stats = settings.blockedStats;
    showModalBottomSheet(
      context: context,
      backgroundColor: BrowserConfig.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, color: BrowserConfig.accentColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Blocking Protection Stats',
                    style: TextStyle(
                      color: BrowserConfig.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Ads Blocked', stats['ads'] ?? 0, Icons.ad_units),
              _buildStatRow('Trackers Blocked', stats['trackers'] ?? 0, Icons.track_changes),
              _buildStatRow('Popups Blocked', stats['popups'] ?? 0, Icons.open_in_new_off),
              _buildStatRow('Redirects Blocked', stats['redirects'] ?? 0, Icons.alt_route),
              _buildStatRow('External Intents Blocked', stats['externalIntents'] ?? 0, Icons.launch),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    settings.resetAdCount();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh, color: BrowserConfig.errorColor, size: 18),
                  label: const Text('Reset Stats', style: TextStyle(color: BrowserConfig.errorColor)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: BrowserConfig.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                color: BrowserConfig.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<BrowserSettings>(context);
    final stats = settings.blockedStats;
    int totalBlocked = (stats['ads'] ?? 0) + (stats['popups'] ?? 0) + (stats['redirects'] ?? 0);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: BrowserConfig.primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Current Page Title
          Expanded(
            child: Text(
              pageTitle.isEmpty ? 'Secure Browser' : pageTitle,
              style: const TextStyle(
                color: BrowserConfig.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          const SizedBox(width: 10),

          // Right side: Interactive Ad & Redirect Counter Badge
          InkWell(
            onTap: () => _showStatsDialog(context, settings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: BrowserConfig.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                '🛑 Blocked: $totalBlocked',
                style: const TextStyle(
                  color: BrowserConfig.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
