import 'package:flutter/material.dart';
import '../models/browser_config.dart';
import '../screens/settings_screen.dart';

class SettingsMenu extends StatelessWidget {
  final String currentUrl;
  final VoidCallback onRefresh;
  final VoidCallback onHome;

  const SettingsMenu({
    super.key,
    required this.currentUrl,
    required this.onRefresh,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: BrowserConfig.textColor),
      color: BrowserConfig.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2A4A), width: 1),
      ),
      onSelected: (value) {
        if (value == 'refresh') {
          onRefresh();
        } else if (value == 'home') {
          onHome();
        } else if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        // Settings Option
        PopupMenuItem<String>(
          value: 'settings',
          child: const Row(
            children: [
              Icon(Icons.settings, color: BrowserConfig.accentColor, size: 20),
              SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Refresh Item
        PopupMenuItem<String>(
          value: 'refresh',
          child: const Row(
            children: [
              Icon(Icons.refresh, color: BrowserConfig.textColor, size: 20),
              SizedBox(width: 12),
              Text('Refresh', style: TextStyle(color: BrowserConfig.textColor)),
            ],
          ),
        ),

        // Go Home Item
        PopupMenuItem<String>(
          value: 'home',
          child: const Row(
            children: [
              Icon(Icons.home, color: BrowserConfig.textColor, size: 20),
              SizedBox(width: 12),
              Text('Go Home', style: TextStyle(color: BrowserConfig.textColor)),
            ],
          ),
        ),
      ],
    );
  }
}
