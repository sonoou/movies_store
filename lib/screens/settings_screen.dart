import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/browser_config.dart';
import '../models/browser_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<BrowserSettings>(context);

    return Scaffold(
      backgroundColor: BrowserConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: BrowserConfig.primaryColor,
        title: const Text(
          'Settings',
          style: TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrowserConfig.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('DISPLAY & IMMERSIVE', Icons.fullscreen),
          const SizedBox(height: 8),

          // Desktop Mode
          _buildSwitchTile(
            title: 'Desktop Mode',
            value: settings.desktopMode,
            icon: Icons.desktop_windows,
            onChanged: (val) => settings.toggleDesktopMode(val),
          ),

          const SizedBox(height: 8),

          // Landscape Auto-Hide Bars
          _buildSwitchTile(
            title: 'Landscape Auto-Hide Bars',
            value: settings.hideBarsInLandscape,
            icon: Icons.landscape,
            onChanged: (val) => settings.toggleHideBarsInLandscape(val),
          ),

          const SizedBox(height: 8),

          // Tilt Auto-Rotate
          _buildSwitchTile(
            title: 'Tilt Auto-Rotate',
            value: settings.appAutoRotate,
            icon: Icons.screen_rotation,
            onChanged: (val) => settings.toggleAppAutoRotate(val),
          ),

          const SizedBox(height: 8),

          // System UI Auto-Hide
          _buildSwitchTile(
            title: 'System UI Auto-Hide',
            value: settings.autoHideSystemUi,
            icon: Icons.aspect_ratio,
            onChanged: (val) => settings.toggleAutoHideSystemUi(val),
          ),

          const SizedBox(height: 8),

          // Auto-Hide Delay
          _buildCard(
            child: ListTile(
              leading: const Icon(Icons.timer, color: BrowserConfig.accentColor),
              title: const Text(
                'Auto-Hide Delay',
                style: TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              trailing: DropdownButton<int>(
                value: settings.autoHideDelaySeconds,
                dropdownColor: BrowserConfig.cardColor,
                underline: const SizedBox(),
                style: const TextStyle(color: BrowserConfig.accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3s')),
                  DropdownMenuItem(value: 5, child: Text('5s')),
                  DropdownMenuItem(value: 8, child: Text('8s')),
                  DropdownMenuItem(value: 10, child: Text('10s')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settings.setAutoHideDelaySeconds(val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Refresh Rate
          _buildCard(
            child: ListTile(
              leading: const Icon(Icons.speed, color: BrowserConfig.accentColor),
              title: const Text(
                'Refresh Rate',
                style: TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              trailing: DropdownButton<String>(
                value: settings.fpsOption,
                dropdownColor: BrowserConfig.cardColor,
                underline: const SizedBox(),
                style: const TextStyle(color: BrowserConfig.accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'MAX', child: Text('Max FPS')),
                  DropdownMenuItem(value: '60', child: Text('60 FPS')),
                  DropdownMenuItem(value: '90', child: Text('90 FPS')),
                  DropdownMenuItem(value: '120', child: Text('120 FPS')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settings.setFpsOption(val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('MENU FLOATING BUTTON', Icons.touch_app),
          const SizedBox(height: 8),

          // Menu Button Size Slider
          _buildSizeSliderTile(
            title: 'Size',
            value: settings.fabSize,
            icon: Icons.radio_button_checked,
            onChanged: (v) => settings.setFabSize(v),
          ),

          const SizedBox(height: 8),

          // Menu Button Opacity Slider (0% - 100%)
          _buildSliderTile(
            title: 'Opacity',
            value: settings.fabOpacity,
            icon: Icons.opacity,
            onChanged: (v) => settings.setFabOpacity(v),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('ROTATION FLOATING BUTTON', Icons.screen_rotation),
          const SizedBox(height: 8),

          // Rotation Button Size Slider
          _buildSizeSliderTile(
            title: 'Size',
            value: settings.rotationBtnSize,
            icon: Icons.crop_rotate,
            onChanged: (v) => settings.setRotationBtnSize(v),
          ),

          const SizedBox(height: 8),

          // Rotation Button Opacity Slider (0% - 100%)
          _buildSliderTile(
            title: 'Opacity',
            value: settings.rotationBtnOpacity,
            icon: Icons.opacity,
            onChanged: (v) => settings.setRotationBtnOpacity(v),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('VOLUME BOOSTER BUTTON', Icons.volume_up),
          const SizedBox(height: 8),

          // Volume Button Size Slider
          _buildSizeSliderTile(
            title: 'Button Size',
            value: settings.volumeBtnSize,
            icon: Icons.volume_up,
            onChanged: (v) => settings.setVolumeBtnSize(v),
          ),

          const SizedBox(height: 8),

          // Volume Button Opacity Slider (0% - 100%)
          _buildSliderTile(
            title: 'Button Opacity',
            value: settings.volumeBtnOpacity,
            icon: Icons.opacity,
            onChanged: (v) => settings.setVolumeBtnOpacity(v),
          ),

          const SizedBox(height: 8),

          // Volume Slider Opacity Slider (0% - 100%)
          _buildSliderTile(
            title: 'Slider Opacity',
            value: settings.volumeSliderOpacity,
            icon: Icons.tune,
            onChanged: (v) => settings.setVolumeSliderOpacity(v),
          ),

          const SizedBox(height: 8),

          // Slider Visibility Mode Card (Auto vs Manual)
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility, color: BrowserConfig.accentColor, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Slider Mode',
                        style: TextStyle(
                          color: BrowserConfig.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'AUTO',
                            label: Text('Auto', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment(
                            value: 'MANUAL',
                            label: Text('Manual', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        selected: {settings.volumeSliderMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          settings.setVolumeSliderMode(newSelection.first);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return BrowserConfig.accentColor.withValues(alpha: 0.25);
                            }
                            return Colors.transparent;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return BrowserConfig.accentColor;
                            }
                            return Colors.white70;
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (settings.volumeSliderMode == 'AUTO') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 32),
                        const Expanded(
                          child: Text(
                            'Auto-Hide Delay',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        DropdownButton<int>(
                          value: settings.volumeSliderAutoDelay,
                          dropdownColor: BrowserConfig.cardColor,
                          underline: const SizedBox(),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3s', style: TextStyle(color: BrowserConfig.textColor, fontSize: 13))),
                            DropdownMenuItem(value: 5, child: Text('5s', style: TextStyle(color: BrowserConfig.textColor, fontSize: 13))),
                            DropdownMenuItem(value: 7, child: Text('7s', style: TextStyle(color: BrowserConfig.textColor, fontSize: 13))),
                            DropdownMenuItem(value: 10, child: Text('10s', style: TextStyle(color: BrowserConfig.textColor, fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) settings.setVolumeSliderAutoDelay(val);
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text(
                        'Click to show and hide',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('SLEEP TIMER (KILL APP)', Icons.timer_outlined),
          const SizedBox(height: 8),

          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.isKillTimerActive) ...[
                    Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: BrowserConfig.accentColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'App Closing In:',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                settings.formattedKillTimerRemaining,
                                style: const TextStyle(
                                  color: BrowserConfig.accentColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrowserConfig.errorColor,
                            side: const BorderSide(color: BrowserConfig.errorColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.stop_circle_outlined, size: 16),
                          label: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            settings.resetKillTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kill timer cancelled'),
                                backgroundColor: BrowserConfig.primaryColor,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: settings.killTimerProgress,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(BrowserConfig.accentColor),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                  ],

                  const Text(
                    'Select Duration to Auto-Kill App:',
                    style: TextStyle(color: BrowserConfig.textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  // Options: 10m, 20m, 30m, 40m, 60m, Custom, Reset
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final minutes in [10, 20, 30, 40, 60])
                        ChoiceChip(
                          label: Text('${minutes}m'),
                          selected: settings.selectedKillAppMinutes == minutes && settings.isKillTimerActive,
                          selectedColor: BrowserConfig.accentColor,
                          backgroundColor: BrowserConfig.backgroundColor,
                          labelStyle: TextStyle(
                            color: settings.selectedKillAppMinutes == minutes && settings.isKillTimerActive
                                ? Colors.black
                                : BrowserConfig.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              settings.startKillTimer(minutes);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('App will close in $minutes minutes'),
                                  backgroundColor: BrowserConfig.primaryColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              settings.resetKillTimer();
                            }
                          },
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.edit, size: 14, color: BrowserConfig.accentColor),
                        label: const Text('Custom'),
                        backgroundColor: BrowserConfig.backgroundColor,
                        labelStyle: const TextStyle(color: BrowserConfig.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                        onPressed: () => _showCustomTimerDialog(context, settings),
                      ),
                      if (settings.isKillTimerActive)
                        ActionChip(
                          avatar: const Icon(Icons.close, size: 14, color: BrowserConfig.errorColor),
                          label: const Text('Reset'),
                          backgroundColor: BrowserConfig.backgroundColor,
                          labelStyle: const TextStyle(color: BrowserConfig.errorColor, fontWeight: FontWeight.bold, fontSize: 12),
                          onPressed: () => settings.resetKillTimer(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'A floating moveable countdown widget will appear on screen when timer is active.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('ADBLOCK & PRIVACY', Icons.security),
          const SizedBox(height: 8),

          // Ad Blocker
          _buildSwitchTile(
            title: 'Ad Blocker',
            value: settings.adBlockerEnabled,
            icon: Icons.block,
            onChanged: (val) => settings.toggleAdBlocker(val),
          ),

          const SizedBox(height: 8),

          // JavaScript
          _buildSwitchTile(
            title: 'JavaScript',
            value: settings.javaScriptEnabled,
            icon: Icons.code,
            onChanged: (val) => settings.toggleJavaScript(val),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('RESET & DATA', Icons.cleaning_services),
          const SizedBox(height: 8),

          // Reset Protection Stats Card
          _buildCard(
            child: ListTile(
              leading: const Icon(Icons.refresh, color: BrowserConfig.errorColor),
              title: const Text(
                'Reset Protection Stats',
                style: TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onTap: () {
                settings.resetAdCount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Protection stats reset!'),
                    backgroundColor: BrowserConfig.primaryColor,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Secure Browser v1.0.0',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrowserConfig.accentColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: BrowserConfig.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: BrowserConfig.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildCard(
      child: SwitchListTile(
        activeTrackColor: BrowserConfig.accentColor,
        secondary: Icon(icon, color: BrowserConfig.accentColor),
        title: Text(
          title,
          style: const TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    final int percent = (value * 100).round();
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: BrowserConfig.accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            SizedBox(
              width: 130,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: BrowserConfig.accentColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: BrowserConfig.accentColor,
                  overlayColor: BrowserConfig.accentColor.withValues(alpha: 0.2),
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$percent%',
                textAlign: TextAlign.end,
                style: const TextStyle(color: BrowserConfig.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSliderTile({
    required String title,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
    double min = 30.0,
    double max = 70.0,
  }) {
    final int sizeDp = value.round();
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: BrowserConfig.accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: BrowserConfig.textColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            SizedBox(
              width: 120,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: BrowserConfig.accentColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: BrowserConfig.accentColor,
                  overlayColor: BrowserConfig.accentColor.withValues(alpha: 0.2),
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${sizeDp}dp',
                textAlign: TextAlign.end,
                style: const TextStyle(color: BrowserConfig.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context, BrowserSettings settings) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BrowserConfig.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer_outlined, color: BrowserConfig.accentColor),
              SizedBox(width: 8),
              Text(
                'Custom Kill Timer',
                style: TextStyle(color: BrowserConfig.textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter duration in minutes to auto-close the app:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: BrowserConfig.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. 45',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: 'mins',
                  suffixStyle: const TextStyle(color: BrowserConfig.accentColor),
                  filled: true,
                  fillColor: BrowserConfig.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BrowserConfig.accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final int? minutes = int.tryParse(controller.text.trim());
                if (minutes != null && minutes > 0) {
                  settings.startKillTimer(minutes);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App will close in $minutes minutes'),
                      backgroundColor: BrowserConfig.primaryColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Start Timer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
