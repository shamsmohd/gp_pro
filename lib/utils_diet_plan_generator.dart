import 'dart:math';

// ── Models ────────────────────────────────────────────────────────────────────

class FoodItem {
  const FoodItem({
    required this.name,
    required this.emoji,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealTypes,
    this.excludeTags = const [],
  });

  final String name;
  final String emoji;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  // 'breakfast', 'lunch', 'dinner'
  final List<String> mealTypes;
  // disease exclusion tags: 'high_sugar', 'refined_carb', 'high_sodium', 'high_sat_fat', 'goitrogen'
  final List<String> excludeTags;
}

class PlannedMeal {
  const PlannedMeal({
    required this.label,
    required this.emoji,
    required this.targetCalories,
    required this.items,
  });

  final String label;
  final String emoji;
  final int targetCalories;
  final List<FoodItem> items;

  int get totalCalories => items.fold(0, (s, f) => s + f.calories);
  int get totalProteinG => items.fold(0, (s, f) => s + f.proteinG);
  int get totalCarbsG => items.fold(0, (s, f) => s + f.carbsG);
  int get totalFatG => items.fold(0, (s, f) => s + f.fatG);
}

class DietPlan {
  const DietPlan({
    required this.meals,
    required this.tipTitle,
    required this.tipBody,
    required this.dailyCalories,
    required this.dailyProteinG,
    required this.dailyCarbsG,
    required this.dailyFatG,
    required this.waterLiters,
  });

  final List<PlannedMeal> meals;
  final String tipTitle;
  final String tipBody;
  final int dailyCalories;
  final int dailyProteinG;
  final int dailyCarbsG;
  final int dailyFatG;
  final double waterLiters;
}

// ── Food database ─────────────────────────────────────────────────────────────

const _foods = <FoodItem>[
  // ── Breakfast ──────────────────────────────────────────────────────────────
  FoodItem(name: 'Oatmeal with berries', emoji: '🥣', calories: 320, proteinG: 10, carbsG: 55, fatG: 6, mealTypes: ['breakfast']),
  FoodItem(name: 'Greek yogurt with honey', emoji: '🍯', calories: 210, proteinG: 17, carbsG: 22, fatG: 5, mealTypes: ['breakfast'], excludeTags: ['high_sugar']),
  FoodItem(name: 'Scrambled eggs (2)', emoji: '🍳', calories: 200, proteinG: 14, carbsG: 2, fatG: 15, mealTypes: ['breakfast']),
  FoodItem(name: 'Whole-grain toast', emoji: '🍞', calories: 140, proteinG: 5, carbsG: 26, fatG: 2, mealTypes: ['breakfast']),
  FoodItem(name: 'Avocado toast', emoji: '🥑', calories: 270, proteinG: 6, carbsG: 28, fatG: 15, mealTypes: ['breakfast'], excludeTags: ['high_sat_fat']),
  FoodItem(name: 'Banana', emoji: '🍌', calories: 90, proteinG: 1, carbsG: 23, fatG: 0, mealTypes: ['breakfast', 'lunch']),
  FoodItem(name: 'Boiled egg', emoji: '🥚', calories: 78, proteinG: 6, carbsG: 1, fatG: 5, mealTypes: ['breakfast', 'lunch']),
  FoodItem(name: 'Cottage cheese (½ cup)', emoji: '🧀', calories: 110, proteinG: 14, carbsG: 4, fatG: 5, mealTypes: ['breakfast']),
  FoodItem(name: 'Whole-milk yogurt', emoji: '🥛', calories: 150, proteinG: 8, carbsG: 12, fatG: 8, mealTypes: ['breakfast'], excludeTags: ['high_sat_fat']),
  FoodItem(name: 'Smoothie bowl', emoji: '🍓', calories: 280, proteinG: 8, carbsG: 46, fatG: 7, mealTypes: ['breakfast']),
  FoodItem(name: 'Peanut butter on toast', emoji: '🥜', calories: 310, proteinG: 12, carbsG: 30, fatG: 16, mealTypes: ['breakfast'], excludeTags: ['high_sat_fat']),
  FoodItem(name: 'Overnight oats', emoji: '🌾', calories: 350, proteinG: 12, carbsG: 58, fatG: 8, mealTypes: ['breakfast']),
  FoodItem(name: 'Fruit salad', emoji: '🍇', calories: 120, proteinG: 2, carbsG: 30, fatG: 1, mealTypes: ['breakfast', 'lunch']),
  FoodItem(name: 'Whole-wheat pancakes (2)', emoji: '🥞', calories: 360, proteinG: 10, carbsG: 52, fatG: 10, mealTypes: ['breakfast'], excludeTags: ['high_sugar', 'refined_carb']),
  FoodItem(name: 'Almonds (30 g)', emoji: '🌰', calories: 170, proteinG: 6, carbsG: 6, fatG: 15, mealTypes: ['breakfast', 'lunch', 'dinner']),
  FoodItem(name: 'Low-fat milk (240 ml)', emoji: '🥛', calories: 100, proteinG: 8, carbsG: 12, fatG: 2, mealTypes: ['breakfast']),

  // ── Lunch ──────────────────────────────────────────────────────────────────
  FoodItem(name: 'Grilled chicken breast', emoji: '🍗', calories: 230, proteinG: 43, carbsG: 0, fatG: 5, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Brown rice (1 cup)', emoji: '🍚', calories: 215, proteinG: 5, carbsG: 45, fatG: 2, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Lentil soup', emoji: '🍲', calories: 230, proteinG: 18, carbsG: 38, fatG: 1, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Mixed green salad', emoji: '🥗', calories: 110, proteinG: 4, carbsG: 12, fatG: 5, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Tuna wrap (whole wheat)', emoji: '🫔', calories: 340, proteinG: 28, carbsG: 34, fatG: 8, mealTypes: ['lunch']),
  FoodItem(name: 'Vegetable stir-fry', emoji: '🥦', calories: 190, proteinG: 6, carbsG: 28, fatG: 6, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Chickpea salad', emoji: '🫘', calories: 270, proteinG: 14, carbsG: 38, fatG: 6, mealTypes: ['lunch']),
  FoodItem(name: 'Quinoa bowl', emoji: '🥙', calories: 290, proteinG: 12, carbsG: 48, fatG: 6, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Turkey sandwich (whole wheat)', emoji: '🥪', calories: 370, proteinG: 28, carbsG: 38, fatG: 10, mealTypes: ['lunch'], excludeTags: ['high_sodium']),
  FoodItem(name: 'Sweet potato (baked)', emoji: '🍠', calories: 180, proteinG: 4, carbsG: 41, fatG: 0, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Hummus with veggie sticks', emoji: '🥕', calories: 190, proteinG: 7, carbsG: 22, fatG: 8, mealTypes: ['lunch']),
  FoodItem(name: 'Egg white omelette', emoji: '🍳', calories: 150, proteinG: 22, carbsG: 2, fatG: 4, mealTypes: ['lunch']),
  FoodItem(name: 'Steamed broccoli', emoji: '🥦', calories: 55, proteinG: 4, carbsG: 11, fatG: 1, mealTypes: ['lunch', 'dinner']),
  FoodItem(name: 'Bean tacos (2, corn)', emoji: '🌮', calories: 310, proteinG: 12, carbsG: 48, fatG: 8, mealTypes: ['lunch']),
  FoodItem(name: 'Watermelon (2 slices)', emoji: '🍉', calories: 85, proteinG: 2, carbsG: 21, fatG: 0, mealTypes: ['lunch'], excludeTags: ['high_sugar']),

  // ── Dinner ─────────────────────────────────────────────────────────────────
  FoodItem(name: 'Baked salmon', emoji: '🐟', calories: 280, proteinG: 39, carbsG: 0, fatG: 13, mealTypes: ['dinner']),
  FoodItem(name: 'Grilled beef steak (lean)', emoji: '🥩', calories: 320, proteinG: 42, carbsG: 0, fatG: 16, mealTypes: ['dinner'], excludeTags: ['high_sat_fat']),
  FoodItem(name: 'Baked chicken thigh', emoji: '🍗', calories: 260, proteinG: 30, carbsG: 0, fatG: 15, mealTypes: ['dinner'], excludeTags: ['high_sat_fat']),
  FoodItem(name: 'Pasta with tomato sauce', emoji: '🍝', calories: 380, proteinG: 14, carbsG: 70, fatG: 5, mealTypes: ['dinner'], excludeTags: ['refined_carb']),
  FoodItem(name: 'Grilled shrimp skewers', emoji: '🍢', calories: 200, proteinG: 30, carbsG: 4, fatG: 6, mealTypes: ['dinner']),
  FoodItem(name: 'Vegetable curry with rice', emoji: '🍛', calories: 420, proteinG: 12, carbsG: 68, fatG: 10, mealTypes: ['dinner']),
  FoodItem(name: 'Baked cod with herbs', emoji: '🐠', calories: 190, proteinG: 32, carbsG: 2, fatG: 5, mealTypes: ['dinner']),
  FoodItem(name: 'Stuffed bell peppers', emoji: '🫑', calories: 290, proteinG: 18, carbsG: 34, fatG: 8, mealTypes: ['dinner']),
  FoodItem(name: 'Tofu stir-fry', emoji: '🟨', calories: 240, proteinG: 18, carbsG: 20, fatG: 11, mealTypes: ['dinner']),
  FoodItem(name: 'Cauliflower rice bowl', emoji: '🥗', calories: 200, proteinG: 10, carbsG: 28, fatG: 6, mealTypes: ['dinner']),
  FoodItem(name: 'Grilled tuna steak', emoji: '🐟', calories: 250, proteinG: 44, carbsG: 0, fatG: 7, mealTypes: ['dinner']),
  FoodItem(name: 'Roasted vegetables & beans', emoji: '🫘', calories: 310, proteinG: 16, carbsG: 48, fatG: 6, mealTypes: ['dinner']),
  FoodItem(name: 'Mushroom & spinach omelette', emoji: '🍄', calories: 220, proteinG: 18, carbsG: 6, fatG: 13, mealTypes: ['dinner']),
  FoodItem(name: 'Cabbage rolls (stuffed)', emoji: '🥬', calories: 260, proteinG: 16, carbsG: 28, fatG: 8, mealTypes: ['dinner'], excludeTags: ['goitrogen']),
  FoodItem(name: 'Lemon herb baked chicken', emoji: '🍋', calories: 240, proteinG: 36, carbsG: 3, fatG: 9, mealTypes: ['dinner']),
];

// ── Disease exclusion rules ───────────────────────────────────────────────────

const _diseaseExclusions = <String, List<String>>{
  'diabetes': ['high_sugar', 'refined_carb'],
  'hypertension': ['high_sodium'],
  'heart_disease': ['high_sat_fat'],
  'thyroid_disorder': ['goitrogen'],
  'none': [],
};

// ── Tips ──────────────────────────────────────────────────────────────────────

const _tips = <String, Map<String, String>>{
  'diabetes': {
    'title': 'Managing Blood Sugar',
    'body':
        'Choose low-GI foods like oats, legumes, and non-starchy vegetables. Spread meals evenly throughout the day to keep glucose stable. Limit refined carbs, sugary drinks, and processed snacks.',
  },
  'hypertension': {
    'title': 'Heart-Healthy Eating',
    'body':
        'Follow a DASH-style diet rich in fruits, vegetables, whole grains, and potassium-rich foods like bananas and leafy greens. Limit added salt to under 2,300 mg per day and avoid processed meats.',
  },
  'heart_disease': {
    'title': 'Protecting Your Heart',
    'body':
        'Prioritise omega-3-rich fish (salmon, mackerel) at least twice a week, choose lean proteins, and replace saturated fats with healthy unsaturated fats from nuts, seeds, and olive oil.',
  },
  'thyroid_disorder': {
    'title': 'Supporting Thyroid Health',
    'body':
        'Include iodine-rich foods like seafood and eggs. Selenium from Brazil nuts and tuna supports thyroid function. Limit raw goitrogenic foods (cabbage, kale) in large quantities.',
  },
  'lose_weight': {
    'title': 'Smart Calorie Deficit',
    'body':
        'Fill half your plate with vegetables at each meal — they add volume and fibre with few calories. Eat slowly, use smaller plates, and front-load calories early in the day for better energy.',
  },
  'gain_weight': {
    'title': 'Building Lean Mass',
    'body':
        'Add calorie-dense, nutrient-rich foods like nuts, avocados, whole grains, and legumes. Aim for 1.6–2.2 g of protein per kg of body weight and time carb-rich meals around your workouts.',
  },
  'maintain_weight': {
    'title': 'Balanced Nutrition',
    'body':
        'Focus on variety and consistency. Eat a rainbow of vegetables, choose whole grains over refined ones, and keep portion sizes steady. Stay well hydrated — thirst is often mistaken for hunger.',
  },
};

// ── Generator ─────────────────────────────────────────────────────────────────

class DietPlanGenerator {
  DietPlanGenerator._();

  static DietPlan generate(Map<String, dynamic> metadata, {int? seed}) {
    final calories = _readInt(metadata['recommended_calories'], 2000);
    final proteinG = _readInt(metadata['recommended_protein'], 120);
    final carbsG = _readInt(metadata['recommended_carbs'], 250);
    final fatG = _readInt(metadata['recommended_fat'], 65);
    final waterL = _readDouble(metadata['recommended_water_liters'], 2.5);
    final disease = (metadata['chronic_disease'] as String?) ?? 'none';
    final goal = (metadata['goal'] as String?) ?? 'maintain_weight';
    final mealOrder =
        (metadata['meal_order'] as List?)?.cast<String>() ?? ['breakfast', 'lunch', 'dinner'];

    final exclusions = {
      ...(_diseaseExclusions[disease] ?? []),
    };

    final eligibleFoods = _foods
        .where((f) => f.excludeTags.every((t) => !exclusions.contains(t)))
        .toList();

    // Date-seeded so the plan is consistent all day but changes each new day
    final dateSeed = seed ??
        int.parse(
          DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', ''),
        );
    final rng = Random(dateSeed);

    // Calorie split: breakfast 25%, lunch 40%, dinner 35%
    const splits = {'breakfast': 0.25, 'lunch': 0.40, 'dinner': 0.35};

    final meals = mealOrder.map((type) {
      final share = splits[type] ?? 0.33;
      final target = (calories * share).round();
      final label = _mealLabel(type);
      final emoji = _mealEmoji(type);
      final eligible = eligibleFoods.where((f) => f.mealTypes.contains(type)).toList()
        ..shuffle(rng);

      final picked = <FoodItem>[];
      var remaining = target;

      for (final food in eligible) {
        if (picked.length >= 5) break;
        if (food.calories <= remaining + 80) {
          picked.add(food);
          remaining -= food.calories;
        }
      }

      // Ensure at least 2 items even if over budget
      if (picked.isEmpty && eligible.isNotEmpty) {
        picked.add(eligible.first);
      }
      if (picked.length < 2 && eligible.length > 1) {
        final next = eligible.firstWhere((f) => !picked.contains(f), orElse: () => eligible.last);
        picked.add(next);
      }

      return PlannedMeal(label: label, emoji: emoji, targetCalories: target, items: picked);
    }).toList();

    final tipKey = _diseaseExclusions.containsKey(disease) && disease != 'none'
        ? disease
        : goal;
    final tip = _tips[tipKey] ?? _tips['maintain_weight']!;

    return DietPlan(
      meals: meals,
      tipTitle: tip['title']!,
      tipBody: tip['body']!,
      dailyCalories: calories,
      dailyProteinG: proteinG,
      dailyCarbsG: carbsG,
      dailyFatG: fatG,
      waterLiters: waterL,
    );
  }

  static String _mealLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  static String _mealEmoji(String type) {
    switch (type) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  static int _readInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  static double _readDouble(dynamic v, double fallback) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return fallback;
  }
}
