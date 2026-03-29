class NutritionPlan {
  const NutritionPlan({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.waterLiters,
    required this.sleepScore,
    required this.activityFactor,
  });

  final int bmr;
  final int tdee;
  final int targetCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final double waterLiters;
  final int sleepScore;
  final double activityFactor;
}

class NutritionCalculator {
  static NutritionPlan calculate({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required int exercisesPerDay,
    required String goal,
    required double sleepHours,
  }) {
    final isMale = gender.toLowerCase() == 'male';

    final bmrDouble = isMale
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

    final activityFactor = _activityFactor(exercisesPerDay);
    final sleepAdjustment = _sleepAdjustment(sleepHours);
    final tdeeDouble = bmrDouble * activityFactor * sleepAdjustment;

    double targetCalories = tdeeDouble;
    if (goal == 'lose_weight') {
      targetCalories -= 400;
    } else if (goal == 'gain_weight') {
      targetCalories += 300;
    }

    if (targetCalories < 1200) {
      targetCalories = 1200;
    }

    final ratios = _macroRatios(goal);
    final proteinGrams = ((targetCalories * ratios.$1) / 4).round();
    final carbsGrams = ((targetCalories * ratios.$2) / 4).round();
    final fatGrams = ((targetCalories * ratios.$3) / 9).round();

    return NutritionPlan(
      bmr: bmrDouble.round(),
      tdee: tdeeDouble.round(),
      targetCalories: targetCalories.round(),
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      waterLiters: (weightKg * 0.033),
      sleepScore: _sleepScore(sleepHours),
      activityFactor: activityFactor,
    );
  }

  static double _activityFactor(int exercisesPerDay) {
    if (exercisesPerDay <= 0) return 1.2;
    if (exercisesPerDay == 1) return 1.375;
    if (exercisesPerDay == 2) return 1.55;
    return 1.725;
  }

  static double _sleepAdjustment(double sleepHours) {
    if (sleepHours < 5) return 0.92;
    if (sleepHours < 6) return 0.96;
    if (sleepHours <= 9) return 1.0;
    return 0.98;
  }

  static int _sleepScore(double sleepHours) {
    if (sleepHours >= 7 && sleepHours <= 9) return 100;
    if (sleepHours >= 6) return 85;
    if (sleepHours >= 5) return 70;
    return 55;
  }

  static (double, double, double) _macroRatios(String goal) {
    switch (goal) {
      case 'lose_weight':
        return (0.35, 0.35, 0.30);
      case 'gain_weight':
        return (0.25, 0.45, 0.30);
      case 'maintain_weight':
      default:
        return (0.30, 0.40, 0.30);
    }
  }
}