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
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  Future<void> _saveSettings() async {
    setState(() {
      isSaving = true;
    });

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

      appThemeMode.value = darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF7F6FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
              Color(0xFF1A1625),
              Color(0xFF171320),
              Color(0xFF120F18),
            ]
                : const [
              Color(0xFFF6F4FA),
              Color(0xFFF4F1FB),
              Color(0xFFEDE7F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 30),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SettingsCard(
                    child: Column(
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Receive general app notifications',
                          value: notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              notificationsEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _SettingsSwitchTile(
                          icon: Icons.favorite_outline,
                          title: 'Health reminders',
                          subtitle:
                          'Daily reminders for water, sleep and activity',
                          value: healthRemindersEnabled,
                          onChanged: (value) {
                            setState(() {
                              healthRemindersEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _SettingsSwitchTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark mode',
                          subtitle: 'Save your theme preference',
                          value: darkModeEnabled,
                          onChanged: (value) {
                            setState(() {
                              darkModeEnabled = value;
                            });

                            appThemeMode.value =
                            value ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                        const SizedBox(height: 14),
                        _SettingsSwitchTile(
                          icon: Icons.sync_outlined,
                          title: 'Sync on mobile data',
                          subtitle:
                          'Allow syncing when Wi-Fi is unavailable',
                          value: syncOnMobileData,
                          onChanged: (value) {
                            setState(() {
                              syncOnMobileData = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'These settings are saved in your Supabase user profile metadata.',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF7E7E87),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isSaving ? null : _saveSettings,
                      child: Text(
                        isSaving ? 'Saving...' : 'Save settings',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
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
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5E35B1),
              size: 26,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
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
          Switch(
            value: value,
            activeColor: const Color(0xFF5E35B1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}