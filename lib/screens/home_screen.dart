import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.hideBottomNav = false});

  final bool hideBottomNav;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HealthData _healthData = HealthData.empty();
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchAndSubscribe();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated && mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchAndSubscribe() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Initial fetch
    final response = await Supabase.instance.client
        .from('health_metrics')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _healthData = response != null ? HealthData.fromMap(response) : HealthData.empty();
        _loading = false;
      });
    }

    // Realtime subscription — updates UI whenever watch uploads a new row
    _channel = Supabase.instance.client
        .channel('home-health-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'health_metrics',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _healthData = HealthData.fromMap(payload.newRecord);
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserFirstName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final fullName = metadata?['full_name'];

    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }

    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  String? _getAvatarUrl() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final avatarUrl = metadata?['avatar_url'];

    if (avatarUrl is String && avatarUrl.trim().isNotEmpty) {
      return avatarUrl.trim().replaceFirst(
        '.storage.supabase.co',
        '.supabase.co/storage',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserFirstName();
    final avatarUrl = _getAvatarUrl();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale factor: 1.0 at 375px (iPhone SE), scales up/down proportionally
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final hPad = max(14.0, 20.0 * scale);

    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    final backgroundGradient = isDark
        ? const [Color(0xFF1A1625), Color(0xFF171320), Color(0xFF120F18)]
        : const [Color(0xFFF6F4FA), Color(0xFFF1EEFA), Color(0xFFEDE7F6)];

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final data = _healthData;

              return RefreshIndicator(
                onRefresh: () async {
                  await _fetchAndSubscribe();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    14 * scale,
                    hPad,
                    widget.hideBottomNav ? 120 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Header ----
                      Row(
                        children: [
                          Container(
                            width: 48 * scale,
                            height: 48 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF1E1E22)
                                  : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF5E35B1)
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(
                                      avatarUrl,
                                      width: 48 * scale,
                                      height: 48 * scale,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 24 * scale,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 24 * scale,
                                      color:
                                          isDark ? Colors.white70 : Colors.grey,
                                    ),
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()},',
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _IconButton(
                            icon: Icons.notifications_none_rounded,
                            isDark: isDark,
                            size: 44 * scale,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20 * scale),

                      // ---- Summary banner ----
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18 * scale),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5E35B1), Color(0xFF40236F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E35B1)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily overview',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            Row(
                              children: [
                                _SummaryPill(
                                  icon: Icons.local_fire_department_rounded,
                                  value: '${data.calories}',
                                  unit: 'kcal',
                                  scale: scale,
                                ),
                                SizedBox(width: 10 * scale),
                                _SummaryPill(
                                  icon: Icons.water_drop_rounded,
                                  value:
                                      data.hydration.toStringAsFixed(1),
                                  unit: 'L',
                                  scale: scale,
                                ),
                                SizedBox(width: 10 * scale),
                                _SummaryPill(
                                  icon: Icons.bedtime_rounded,
                                  value: '${data.sleepHours}',
                                  unit: 'hr',
                                  scale: scale,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24 * scale),

                      // ---- Section: Vitals ----
                      Text(
                        'Vitals',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      // Watch vitals row
                      Row(
                        children: [
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.monitor_heart_rounded,
                              iconColor: const Color(0xFFE53935),
                              title: 'Heart Rate',
                              value: data.heartRate != null
                                  ? data.heartRate!.toStringAsFixed(0)
                                  : '—',
                              unit: 'bpm',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.water_drop_rounded,
                              iconColor: const Color(0xFF1E88E5),
                              title: 'SpO2',
                              value: data.spo2 != null
                                  ? data.spo2!.toStringAsFixed(1)
                                  : '—',
                              unit: '%',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFE53935),
                              title: 'Blood pressure',
                              value:
                                  '${data.bloodPressureSys}/${data.bloodPressureDia}',
                              unit: 'mmHg',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.bloodtype_rounded,
                              iconColor: const Color(0xFFD32F2F),
                              title: 'Blood sugar',
                              value: '${data.bloodSugar}',
                              unit: 'mg/dl',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.thermostat_rounded,
                              iconColor: const Color(0xFFFF9800),
                              title: 'Temperature',
                              value:
                                  data.temperature.toStringAsFixed(1),
                              unit: '°C',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: _VitalCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFFFF5722),
                              title: 'Calories',
                              value: '${data.calories}',
                              unit: 'kcal',
                              cardColor: cardColor,
                              cardBorder: cardBorder,
                              isDark: isDark,
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24 * scale),

                      // ---- Section: Wellness ----
                      Text(
                        'Wellness',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      _WellnessRow(
                        icon: Icons.water_drop_rounded,
                        iconColor: const Color(0xFF2196F3),
                        title: 'Hydration',
                        value:
                            '${data.hydration.toStringAsFixed(1)} L',
                        progress: (data.hydration / 3.0).clamp(0.0, 1.0),
                        progressColor: const Color(0xFF2196F3),
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        isDark: isDark,
                        scale: scale,
                      ),
                      SizedBox(height: 10 * scale),
                      _WellnessRow(
                        icon: Icons.bedtime_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        title: 'Sleep',
                        value: '${data.sleepHours} hours',
                        progress: (data.sleepHours / 9.0).clamp(0.0, 1.0),
                        progressColor: const Color(0xFF7C4DFF),
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        isDark: isDark,
                        scale: scale,
                      ),

                      // ---- Loading state ----
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---- Reusable widgets ----

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.value,
    required this.unit,
    required this.scale,
  });

  final IconData icon;
  final String value;
  final String unit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14 * scale),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20 * scale),
            SizedBox(height: 6 * scale),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.cardColor,
    required this.cardBorder,
    required this.isDark,
    required this.scale,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;
  final Color cardColor;
  final Color cardBorder;
  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11 * scale),
            ),
            child: Icon(icon, color: iconColor, size: 20 * scale),
          ),
          SizedBox(height: 10 * scale),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
          ),
          SizedBox(height: 2 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                SizedBox(width: 3 * scale),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessRow extends StatelessWidget {
  const _WellnessRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.progress,
    required this.progressColor,
    required this.cardColor,
    required this.cardBorder,
    required this.isDark,
    required this.scale,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final double progress;
  final Color progressColor;
  final Color cardColor;
  final Color cardBorder;
  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Icon(icon, color: iconColor, size: 22 * scale),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * scale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5 * scale),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7 * scale,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Data model (unchanged) ----

class HealthData {
  final int bloodPressureSys;
  final int bloodPressureDia;
  final int bloodSugar;
  final double temperature;
  final int calories;
  final double hydration;
  final int sleepHours;
  // Watch fields
  final double? heartRate;
  final double? spo2;
  final int? steps;

  HealthData({
    required this.bloodPressureSys,
    required this.bloodPressureDia,
    required this.bloodSugar,
    required this.temperature,
    required this.calories,
    required this.hydration,
    required this.sleepHours,
    this.heartRate,
    this.spo2,
    this.steps,
  });

  factory HealthData.empty() {
    return HealthData(
      bloodPressureSys: 120,
      bloodPressureDia: 80,
      bloodSugar: 95,
      temperature: 36.7,
      calories: 320,
      hydration: 2.5,
      sleepHours: 8,
    );
  }

  factory HealthData.fromMap(Map<String, dynamic> map) {
    int readInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    double readDouble(dynamic value, double fallback) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return fallback;
    }

    double? readOptionalDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return null;
    }

    int? readOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return null;
    }

    return HealthData(
      bloodPressureSys: readInt(map['blood_pressure_sys'], 120),
      bloodPressureDia: readInt(map['blood_pressure_dia'], 80),
      bloodSugar: readInt(map['blood_sugar'], 95),
      temperature: readDouble(map['temperature'], 36.7),
      calories: readInt(map['calories'], 320),
      hydration: readDouble(map['hydration'], 2.5),
      sleepHours: readInt(map['sleep_hours'], 8),
      heartRate: readOptionalDouble(map['heart_rate']),
      spo2: readOptionalDouble(map['spo2']),
      steps: readOptionalInt(map['steps']),
    );
  }
}
