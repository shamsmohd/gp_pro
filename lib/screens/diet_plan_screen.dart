import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils_diet_plan_generator.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key, this.hideBottomNav = false});

  final bool hideBottomNav;

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  int _seed = int.parse(
    DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', ''),
  );

  void _refreshPlan() {
    setState(() {
      _seed = DateTime.now().millisecondsSinceEpoch;
    });
  }

  DietPlan _buildPlan() {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return DietPlanGenerator.generate(metadata, seed: _seed);
  }

  String _goalLabel(Map<String, dynamic> metadata) {
    switch (metadata['goal'] as String?) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'gain_weight':
        return 'Gain Weight';
      case 'maintain_weight':
        return 'Maintain Weight';
      default:
        return 'Balanced Diet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final hPad = max(14.0, 20.0 * scale);

    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);
    final backgroundGradient = isDark
        ? const [Color(0xFF1A1625), Color(0xFF171320), Color(0xFF120F18)]
        : const [Color(0xFFF6F4FA), Color(0xFFF1EEFA), Color(0xFFEDE7F6)];

    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final plan = _buildPlan();
    final bmr = metadata['recommended_bmr'] as int? ?? 0;
    final tdee = metadata['recommended_tdee'] as int? ?? 0;

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
                // ── Header ──────────────────────────────────────────────────
                Semantics(
                  header: true,
                  child: Text(
                    'Diet Plan',
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  'Personalised for your goal',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ── Hero goal banner ─────────────────────────────────────────
                Semantics(
                  label:
                      'Goal: ${_goalLabel(metadata)}. Daily target: ${plan.dailyCalories} calories.',
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20 * scale),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E35B1), Color(0xFF40236F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E35B1).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _goalLabel(metadata),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${plan.dailyCalories}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42 * scale,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6 * scale, left: 6 * scale),
                              child: Text(
                                'kcal / day',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14 * scale),
                        Row(
                          children: [
                            _HeroPill(label: 'BMR', value: '$bmr kcal', scale: scale),
                            SizedBox(width: 10 * scale),
                            _HeroPill(label: 'TDEE', value: '$tdee kcal', scale: scale),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                // ── Macro pills row ──────────────────────────────────────────
                Semantics(
                  label:
                      'Daily macros: ${plan.dailyProteinG} grams protein, ${plan.dailyCarbsG} grams carbs, ${plan.dailyFatG} grams fat.',
                  excludeSemantics: true,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16 * scale),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E35B1), Color(0xFF40236F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Row(
                      children: [
                        _MacroPill(
                          icon: Icons.local_fire_department_rounded,
                          value: '${plan.dailyProteinG}g',
                          label: 'Protein',
                          scale: scale,
                        ),
                        SizedBox(width: 8 * scale),
                        _MacroPill(
                          icon: Icons.grain_rounded,
                          value: '${plan.dailyCarbsG}g',
                          label: 'Carbs',
                          scale: scale,
                        ),
                        SizedBox(width: 8 * scale),
                        _MacroPill(
                          icon: Icons.water_drop_outlined,
                          value: '${plan.dailyFatG}g',
                          label: 'Fat',
                          scale: scale,
                        ),
                        SizedBox(width: 8 * scale),
                        _MacroPill(
                          icon: Icons.water_drop_rounded,
                          value: '${plan.waterLiters.toStringAsFixed(1)}L',
                          label: 'Water',
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24 * scale),

                // ── Meal plan section ────────────────────────────────────────
                Text(
                  'Today\'s Meal Plan',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 12 * scale),

                ...plan.meals.map(
                  (meal) => Padding(
                    padding: EdgeInsets.only(bottom: 12 * scale),
                    child: _MealCard(
                      meal: meal,
                      cardColor: cardColor,
                      cardBorder: cardBorder,
                      isDark: isDark,
                      scale: scale,
                    ),
                  ),
                ),

                SizedBox(height: 12 * scale),

                // ── Tip card ─────────────────────────────────────────────────
                Text(
                  'Your Tip',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 12 * scale),
                _TipCard(
                  title: plan.tipTitle,
                  body: plan.tipBody,
                  isDark: isDark,
                  scale: scale,
                ),
                SizedBox(height: 20 * scale),

                // ── Refresh button ───────────────────────────────────────────
                Semantics(
                  button: true,
                  label: 'Refresh my meal plan',
                  child: SizedBox(
                    width: double.infinity,
                    height: 54 * scale,
                    child: OutlinedButton.icon(
                      onPressed: _refreshPlan,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(
                        'Refresh My Plan',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C3CCF),
                        side: const BorderSide(color: Color(0xFF6C3CCF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value, required this.scale});

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.scale,
  });

  final IconData icon;
  final String value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18 * scale),
            SizedBox(height: 4 * scale),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.cardColor,
    required this.cardBorder,
    required this.isDark,
    required this.scale,
  });

  final PlannedMeal meal;
  final Color cardColor;
  final Color cardBorder;
  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final itemNames = meal.items.map((f) => f.name).join(', ');

    return Semantics(
      label:
          'Meal: ${meal.label}, target ${meal.targetCalories} calories. Contains: $itemNames.',
      child: Container(
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
            // Card header
            Padding(
              padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 12 * scale),
              child: Row(
                children: [
                  Text(meal.emoji, style: TextStyle(fontSize: 22 * scale)),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Text(
                      meal.label,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 4 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3CCF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Text(
                      '~${meal.totalCalories} kcal',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C3CCF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),

            // Food items
            ...meal.items.map(
              (food) => _FoodItemRow(
                food: food,
                isDark: isDark,
                scale: scale,
                subColor: subColor,
                textColor: textColor,
                isLast: food == meal.items.last,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodItemRow extends StatelessWidget {
  const _FoodItemRow({
    required this.food,
    required this.isDark,
    required this.scale,
    required this.subColor,
    required this.textColor,
    required this.isLast,
  });

  final FoodItem food;
  final bool isDark;
  final double scale;
  final Color subColor;
  final Color textColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${food.name}: ${food.calories} calories, ${food.proteinG}g protein, ${food.carbsG}g carbs, ${food.fatG}g fat.',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          10 * scale,
          16 * scale,
          isLast ? 14 * scale : 10 * scale,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(food.emoji, style: TextStyle(fontSize: 20 * scale)),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Row(
                    children: [
                      _MacroTag(
                        label: '${food.proteinG}g P',
                        color: const Color(0xFFE53935),
                        scale: scale,
                      ),
                      SizedBox(width: 4 * scale),
                      _MacroTag(
                        label: '${food.carbsG}g C',
                        color: const Color(0xFFF59E0B),
                        scale: scale,
                      ),
                      SizedBox(width: 4 * scale),
                      _MacroTag(
                        label: '${food.fatG}g F',
                        color: const Color(0xFF10B981),
                        scale: scale,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            Text(
              '${food.calories}',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              ' kcal',
              style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({required this.label, required this.color, required this.scale});

  final String label;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5 * scale),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.body,
    required this.isDark,
    required this.scale,
  });

  final String title;
  final String body;
  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : const Color(0xFF374151);

    return Semantics(
      label: 'Tip: $title. $body',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF6C3CCF).withValues(alpha: isDark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(20 * scale),
          border: Border.all(
            color: const Color(0xFF6C3CCF).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF6C3CCF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                color: const Color(0xFF6C3CCF),
                size: 22 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w400,
                      color: subColor,
                      height: 1.5,
                    ),
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
