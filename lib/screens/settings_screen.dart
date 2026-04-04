import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool healthRemindersEnabled = true;
  bool syncOnMobileData = false;

  Timer? _saveTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};

    if (!mounted) return;

    setState(() {
      notificationsEnabled = metadata['notifications_enabled'] is bool
          ? metadata['notifications_enabled'] as bool
          : true;
      darkModeEnabled = metadata['dark_mode_enabled'] is bool
          ? metadata['dark_mode_enabled'] as bool
          : false;
      healthRemindersEnabled = metadata['health_reminders_enabled'] is bool
          ? metadata['health_reminders_enabled'] as bool
          : true;
      syncOnMobileData = metadata['sync_on_mobile_data'] is bool
          ? metadata['sync_on_mobile_data'] as bool
          : false;
    });

    appThemeMode.value = darkModeEnabled ? ThemeMode.dark : ThemeMode.light;
  }

  void _onSettingChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _saveSettings);
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'notifications_enabled': notificationsEnabled,
            'dark_mode_enabled': darkModeEnabled,
            'health_reminders_enabled': healthRemindersEnabled,
            'sync_on_mobile_data': syncOnMobileData,
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    final backgroundGradient = isDark
        ? const [Color(0xFF1A1625), Color(0xFF171320), Color(0xFF120F18)]
        : const [Color(0xFFF6F4FA), Color(0xFFF4F1FB), Color(0xFFEDE7F6)];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadSettings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, size: 30, color: textColor),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notifications section
                  _SectionLabel(text: 'Notifications', color: textColor),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Push notifications',
                          subtitle: 'Receive general app notifications',
                          value: notificationsEnabled,
                          onChanged: (value) {
                            setState(() => notificationsEnabled = value);
                            _onSettingChanged();
                          },
                        ),
                        const SizedBox(height: 12),
                        _SettingsSwitchTile(
                          icon: Icons.favorite_outline,
                          title: 'Health reminders',
                          subtitle: 'Daily reminders for water, sleep and activity',
                          value: healthRemindersEnabled,
                          onChanged: (value) {
                            setState(() => healthRemindersEnabled = value);
                            _onSettingChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Appearance section
                  _SectionLabel(text: 'Appearance', color: textColor),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      subtitle: 'Switch between light and dark theme',
                      value: darkModeEnabled,
                      onChanged: (value) {
                        setState(() => darkModeEnabled = value);
                        appThemeMode.value =
                            value ? ThemeMode.dark : ThemeMode.light;
                        _onSettingChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data section
                  _SectionLabel(text: 'Data & sync', color: textColor),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SettingsSwitchTile(
                      icon: Icons.sync_outlined,
                      title: 'Sync on mobile data',
                      subtitle: 'Allow syncing when Wi-Fi is unavailable',
                      value: syncOnMobileData,
                      onChanged: (value) {
                        setState(() => syncOnMobileData = value);
                        _onSettingChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App info
                  Center(
                    child: Text(
                      'gp_pro v1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF5E35B1).withValues(alpha: 0.2)
                  : const Color(0xFFF1EBFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5E35B1),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF7E7E87),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF5E35B1),
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
