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
  late Future<HealthData> _healthFuture;
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _healthFuture = fetchLatestHealthData();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStream.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated && mounted) {
        setState(() {});
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  String _getUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final fullName = metadata?['full_name'];

    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
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

  Future<HealthData> fetchLatestHealthData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return HealthData.empty();
    }

    final response = await Supabase.instance.client
        .from('health_metrics')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return HealthData.empty();
    }

    return HealthData.fromMap(response);
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final avatarUrl = _getAvatarUrl();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const [
      Color(0xFF1A1625),
      Color(0xFF171320),
      Color(0xFF120F18),
    ]
        : const [
      Color(0xFFF6F4FA),
      Color(0xFFF1EEFA),
      Color(0xFFEDE7F6),
    ];

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280);

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
          child: FutureBuilder<HealthData>(
            future: _healthFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? HealthData.empty();

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _healthFuture = fetchLatestHealthData();
                  });
                  await _healthFuture;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    widget.hideBottomNav ? 120 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderSection(
                        greeting: _getGreeting(),
                        userName: userName,
                        avatarUrl: avatarUrl,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Track your health,\nImprove your life',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (snapshot.hasError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Error loading health data:\n${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 0.78,
                          children: [
                            HealthCard(
                              title: 'Heart rate',
                              topRightLabel: 'BP',
                              emoji: '❤️',
                              subtitle: 'Track blood pressure\nand oxygen.',
                              value:
                              '${data.bloodPressureSys} / ${data.bloodPressureDia} mmHg',
                            ),
                            HealthCard(
                              title: 'Blood sugar',
                              topRightLabel: 'BS',
                              emoji: '🩸',
                              subtitle: 'Manage your blood\nsugar wisely',
                              value: '${data.bloodSugar} mg/dl',
                            ),
                            HealthCard(
                              title: 'Temp',
                              emoji: '🌡️',
                              subtitle: 'Check temperature\nlevels',
                              value:
                              '${data.temperature.toStringAsFixed(1)} °C',
                            ),
                            HealthCard(
                              title: 'Activity',
                              emoji: '🏃',
                              subtitle: 'Stay active and\nenergized',
                              value: 'Calories: ${data.calories} kcal',
                            ),
                            HealthCard(
                              title: 'Hydration',
                              emoji: '💧',
                              subtitle: 'Keep your body\nhydrated',
                              value: '${data.hydration.toStringAsFixed(1)} L',
                            ),
                            HealthCard(
                              title: 'Sleep',
                              emoji: '😴',
                              subtitle: 'Sleep well and\nrecover',
                              value: '${data.sleepHours} Hr',
                            ),
                          ],
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.greeting,
    required this.userName,
    required this.avatarUrl,
  });

  final String greeting;
  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280);

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 30,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 30,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 15,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.78),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.95),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.notifications_none_rounded,
                size: 30,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HealthCard extends StatelessWidget {
  const HealthCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.emoji,
    this.topRightLabel,
  });

  final String title;
  final String value;
  final String subtitle;
  final String emoji;
  final String? topRightLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E22)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (topRightLabel != null)
                Text(
                  topRightLabel!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 52),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthData {
  final int bloodPressureSys;
  final int bloodPressureDia;
  final int bloodSugar;
  final double temperature;
  final int calories;
  final double hydration;
  final int sleepHours;

  HealthData({
    required this.bloodPressureSys,
    required this.bloodPressureDia,
    required this.bloodSugar,
    required this.temperature,
    required this.calories,
    required this.hydration,
    required this.sleepHours,
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

    return HealthData(
      bloodPressureSys: readInt(map['blood_pressure_sys'], 120),
      bloodPressureDia: readInt(map['blood_pressure_dia'], 80),
      bloodSugar: readInt(map['blood_sugar'], 95),
      temperature: readDouble(map['temperature'], 36.7),
      calories: readInt(map['calories'], 320),
      hydration: readDouble(map['hydration'], 2.5),
      sleepHours: readInt(map['sleep_hours'], 8),
    );
  }
}