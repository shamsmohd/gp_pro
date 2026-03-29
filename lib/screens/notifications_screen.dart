import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.hideBottomNav = false,
    this.onBackToHome,
  });

  final bool hideBottomNav;
  final VoidCallback? onBackToHome;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;

  List<_AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _notifications = _buildBasicNotifications();
  }

  List<_AppNotification> _buildBasicNotifications() {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    final double sleepHours =
        (metadata['sleep_hours'] as num?)?.toDouble() ?? 8.0;
    final int exercisePerDay =
        (metadata['exercise_per_day'] as num?)?.toInt() ?? 0;
    final dynamic mealOrderRaw = metadata['meal_order'];
    final double weightKg =
        (metadata['weight_kg'] as num?)?.toDouble() ?? 70.0;

    final waterLiters = (weightKg * 0.033).clamp(1.5, 4.0);
    final mealOrder = _mealOrderLabel(mealOrderRaw);

    final notifications = <_AppNotification>[
      _AppNotification(
        title: 'Drink Water',
        message:
        'Try to drink about ${waterLiters.toStringAsFixed(1)} liters of water today to stay hydrated.',
        time: 'Now',
        icon: Icons.water_drop_outlined,
      ),
      _AppNotification(
        title: 'Organize Your Meals',
        message: 'Your main meal order is: $mealOrder.',
        time: 'Today',
        icon: Icons.restaurant_menu_outlined,
      ),
    ];

    if (sleepHours < 7) {
      notifications.add(
        _AppNotification(
          title: 'Improve Your Sleep',
          message:
          'Your average sleep is ${sleepHours.toStringAsFixed(1)} hours. Try to get between 7 and 9 hours.',
          time: 'Reminder',
          icon: Icons.bedtime_outlined,
        ),
      );
    } else {
      notifications.add(
        _AppNotification(
          title: 'Great Sleep',
          message:
          'Keep it up. Your average sleep is ${sleepHours.toStringAsFixed(1)} hours, which is very good.',
          time: 'Update',
          icon: Icons.nightlight_round,
        ),
      );
    }

    if (exercisePerDay <= 0) {
      notifications.add(
        _AppNotification(
          title: 'Move a Little',
          message:
          'No activity is recorded today. Even 15 to 20 minutes of walking can make a big difference.',
          time: 'Today',
          icon: Icons.directions_walk_outlined,
        ),
      );
    } else {
      notifications.add(
        _AppNotification(
          title: 'Stay Active',
          message:
          'You have $exercisePerDay workout(s) per day. Great job, keep going.',
          time: 'Today',
          icon: Icons.local_fire_department_outlined,
        ),
      );
    }

    notifications.add(
      const _AppNotification(
        title: 'Track Your Health Daily',
        message:
        'Keep entering your data regularly so the app can provide more accurate recommendations.',
        time: 'Important',
        icon: Icons.favorite_outline,
      ),
    );

    return notifications;
  }

  String _mealOrderLabel(dynamic mealOrder) {
    if (mealOrder is! List || mealOrder.isEmpty) {
      return 'Breakfast > Lunch > Dinner';
    }

    return mealOrder.map((meal) {
      switch (meal.toString()) {
        case 'breakfast':
          return 'Breakfast';
        case 'lunch':
          return 'Lunch';
        case 'dinner':
          return 'Dinner';
        default:
          return meal.toString();
      }
    }).join(' > ');
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = isDark
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              widget.hideBottomNav ? 120 : 24,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _handleBack(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.iconTheme.color,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Your daily essentials and real-time updates',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ..._notifications.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _NotificationCard(
                    title: item.title,
                    message: item.message,
                    time: item.time,
                    icon: item.icon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppNotification {
  const _AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF7B7B7B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3FC8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C3FC8),
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
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF6C3FC8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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