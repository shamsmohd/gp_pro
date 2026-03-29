import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/exercise_videos.dart';
import '../utils_nutrition_calculator.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.hideBottomNav = false});

  final bool hideBottomNav;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int selectedTab = 0; // 0 = Daily, 1 = Weekly, 2 = Monthly

  late Future<Map<String, dynamic>?> _activityFuture;
  late ExerciseVideo _dailyVideo;

  @override
  void initState() {
    super.initState();
    _dailyVideo = _pickDailyVideo();
    _loadData();
  }

  ExerciseVideo _pickDailyVideo() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);
    return exerciseVideos[random.nextInt(exerciseVideos.length)];
  }

  void _loadData() {
    _activityFuture = _fetchActivity();
  }

  Future<Map<String, dynamic>?> _fetchActivity() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (selectedTab == 0) {
      // Daily: fetch latest single row
      final data = await Supabase.instance.client
          .from('daily_activity')
          .select()
          .eq('user_id', user.id)
          .order('activity_date', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    }

    // Weekly or Monthly range
    final String startDate;
    if (selectedTab == 1) {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      startDate = weekStart.toIso8601String().split('T').first;
    } else {
      final monthStart = DateTime(today.year, today.month, 1);
      startDate = monthStart.toIso8601String().split('T').first;
    }
    final endDate = today.toIso8601String().split('T').first;

    final rows = await Supabase.instance.client
        .from('daily_activity')
        .select()
        .eq('user_id', user.id)
        .gte('activity_date', startDate)
        .lte('activity_date', endDate)
        .order('activity_date', ascending: false);

    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;

    // Aggregate totals across the period; use goals from the most recent row
    final latest = list.first;
    int totalCalories = 0;
    int totalCarbs = 0;
    int totalProtein = 0;
    int totalFat = 0;

    for (final row in list) {
      totalCalories += ((row['calories'] ?? 0) as num).toInt();
      totalCarbs += ((row['carbs'] ?? 0) as num).toInt();
      totalProtein += ((row['protein'] ?? 0) as num).toInt();
      totalFat += ((row['fat'] ?? 0) as num).toInt();
    }

    final days = list.length;
    return {
      ...latest,
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
      'calories_goal': ((latest['calories_goal'] ?? 0) as num).toInt() * days,
      'carbs_goal': ((latest['carbs_goal'] ?? 0) as num).toInt() * days,
      'protein_goal': ((latest['protein_goal'] ?? 0) as num).toInt() * days,
      'fat_goal': ((latest['fat_goal'] ?? 0) as num).toInt() * days,
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _activityFuture;
  }

  String _formatActivityDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'No date';

    try {
      final date = DateTime.parse(rawDate);

      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _openVideo(ExerciseVideo video) async {
    final uri = Uri.parse(video.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Map<String, dynamic> _profileMetrics(User? user) {
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    final gender = (metadata['gender'] ?? '').toString();
    final birthDateRaw = metadata['birth_date']?.toString();
    final height = (metadata['height_cm'] as num?)?.toDouble();
    final weight = (metadata['weight_kg'] as num?)?.toDouble();
    final exercisesPerDay = (metadata['exercise_per_day'] as num?)?.toInt() ?? 0;
    final goal = (metadata['goal'] ?? 'maintain_weight').toString();
    final sleepHours = (metadata['sleep_hours'] as num?)?.toDouble() ?? 8;

    NutritionPlan? plan;
    if (gender.isNotEmpty && birthDateRaw != null && height != null && weight != null) {
      try {
        final birthDate = DateTime.parse(birthDateRaw);
        final age = _calculateAge(birthDate);
        plan = NutritionCalculator.calculate(
          gender: gender,
          age: age,
          heightCm: height,
          weightKg: weight,
          exercisesPerDay: exercisesPerDay,
          goal: goal,
          sleepHours: sleepHours,
        );
      } catch (_) {}
    }

    return {
      'gender': gender,
      'goal': goal,
      'sleep_hours': sleepHours,
      'exercise_per_day': exercisesPerDay,
      'meal_order': metadata['meal_order'] ?? const [],
      'weight_kg': weight,
      'height_cm': height,
      'recommended': plan,
    };
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    final hasHadBirthday = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthday) age -= 1;
    return age;
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Lose weight';
      case 'gain_weight':
        return 'Gain weight';
      default:
        return 'Maintain';
    }
  }

  String _genderLabel(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Not set';
    }
  }

  String _mealOrderLabel(dynamic mealOrder) {
    if (mealOrder is! List || mealOrder.isEmpty) return 'Breakfast > Lunch > Dinner';
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

  @override
  Widget build(BuildContext context) {
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

    final cardColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = theme.textTheme.bodySmall?.color ?? const Color(0xFF7B7B7B);

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
            onRefresh: _refresh,
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      widget.hideBottomNav ? 120 : 24,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 100),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Error loading activity data:\n${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                final activity = snapshot.data;

                final user = Supabase.instance.client.auth.currentUser;
                final profileMetrics = _profileMetrics(user);
                final recommended = profileMetrics['recommended'] as NutritionPlan?;

                final calories = ((activity?['calories'] ?? 0) as num).toInt();
                final caloriesGoal = ((activity?['calories_goal'] ?? recommended?.targetCalories ?? 1800) as num).toInt();
                final carbs = ((activity?['carbs'] ?? 0) as num).toInt();
                final carbsGoal = ((activity?['carbs_goal'] ?? recommended?.carbsGrams ?? 60) as num).toInt();
                final protein = ((activity?['protein'] ?? 0) as num).toInt();
                final proteinGoal = ((activity?['protein_goal'] ?? recommended?.proteinGrams ?? 60) as num).toInt();
                final fat = ((activity?['fat'] ?? 0) as num).toInt();
                final fatGoal = ((activity?['fat_goal'] ?? recommended?.fatGrams ?? 60) as num).toInt();
                final streakDays = ((activity?['streak_days'] ?? 1) as num).toInt();

                final String activityDate;
                if (selectedTab == 0) {
                  activityDate = _formatActivityDate(
                    activity?['activity_date']?.toString() ?? DateTime.now().toIso8601String(),
                  );
                } else if (selectedTab == 1) {
                  activityDate = 'This Week';
                } else {
                  activityDate = 'This Month';
                }

                final progress = caloriesGoal <= 0 ? 0.0 : (calories / caloriesGoal).clamp(0.0, 1.0);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    widget.hideBottomNav ? 120 : 24,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            'Activity',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _PeriodTab(
                              title: 'Daily',
                              selected: selectedTab == 0,
                              onTap: () {
                                setState(() {
                                  selectedTab = 0;
                                  _loadData();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _PeriodTab(
                              title: 'Weekly',
                              selected: selectedTab == 1,
                              onTap: () {
                                setState(() {
                                  selectedTab = 1;
                                  _loadData();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _PeriodTab(
                              title: 'Monthly',
                              selected: selectedTab == 2,
                              onTap: () {
                                setState(() {
                                  selectedTab = 2;
                                  _loadData();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2B1D4A) : const Color(0xFF40236F),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activityDate,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$streakDays Day Streak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 220,
                              width: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 220,
                                    width: 220,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 14,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFB794F6),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$calories kcal',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'of $caloriesGoal kcal',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _MacroBox(
                                    title: 'Carb',
                                    value: carbs,
                                    goal: carbsGoal,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _MacroBox(
                                    title: 'Protein',
                                    value: protein,
                                    goal: proteinGoal,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _MacroBox(
                                    title: 'Fat',
                                    value: fat,
                                    goal: fatGoal,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (recommended != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calculated plan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Gender',
                                      value: _genderLabel(profileMetrics['gender'].toString()),
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Goal',
                                      value: _goalLabel(profileMetrics['goal'].toString()),
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'BMR',
                                      value: '${recommended.bmr} kcal',
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'TDEE',
                                      value: '${recommended.tdee} kcal',
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Workout/day',
                                      value: '${profileMetrics['exercise_per_day']}',
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Sleep',
                                      value: '${(profileMetrics['sleep_hours'] as num).toStringAsFixed(1)} h',
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _WideInfoChip(
                                label: 'Meals order',
                                value: _mealOrderLabel(profileMetrics['meal_order']),
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Water',
                                      value: '${recommended.waterLiters.toStringAsFixed(1)} L',
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InfoChip(
                                      label: 'Sleep score',
                                      value: '${recommended.sleepScore}%',
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Today\'s Workout',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _VideoCard(
                        video: _dailyVideo,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () => _openVideo(_dailyVideo),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5E35B1) : (isDark ? const Color(0xFF1E1E22) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  const _MacroBox({
    required this.title,
    required this.value,
    required this.goal,
    required this.isDark,
  });

  final String title;
  final int value;
  final int goal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2761) : const Color(0xFF5A3397),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value / ${goal}g',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF6F1FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF6E5D8C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2F214B),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInfoChip extends StatelessWidget {
  const _WideInfoChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF6F1FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF6E5D8C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2F214B),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  final ExerciseVideo video;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF2B1D4A) : const Color(0xFFEDE7F6),
                        child: const Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Color(0xFF5E35B1),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${video.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 15,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 24,
                    color: Color(0xFF5E35B1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}