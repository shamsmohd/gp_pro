import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils_nutrition_calculator.dart';
import 'root_screen.dart';
import 'sign_in_screen.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final PageController _pageController = PageController();
  final supabase = Supabase.instance.client;

  int _currentPage = 0;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedGender;
  DateTime? _birthDate;
  String _selectedDisease = 'none';
  String _selectedGoal = 'lose_weight';
  int _exercisePerDay = 0;
  double _sleepHours = 8;

  bool _breakfastChecked = true;
  bool _lunchChecked = true;
  bool _dinnerChecked = true;
  bool _loading = false;

  final List<String> _diseaseOptions = const [
    'none',
    'diabetes',
    'hypertension',
    'heart_disease',
    'thyroid_disorder',
    'other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int get _totalPages => 6;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveOnboardingData();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canContinue {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _weightController.text.trim().isNotEmpty &&
            _heightController.text.trim().isNotEmpty;
      case 2:
        return _selectedGender != null && _birthDate != null;
      case 3:
        return true;
      case 4:
        return _breakfastChecked || _lunchChecked || _dinnerChecked;
      case 5:
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
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
        return 'Maintain weight';
    }
  }

  String _diseaseLabel(String disease) {
    switch (disease) {
      case 'diabetes':
        return 'Diabetes';
      case 'hypertension':
        return 'Hypertension';
      case 'heart_disease':
        return 'Heart disease';
      case 'thyroid_disorder':
        return 'Thyroid disorder';
      case 'other':
        return 'Other';
      default:
        return 'None';
    }
  }

  List<String> get _mealOrder {
    final meals = <String>[];
    if (_breakfastChecked) meals.add('breakfast');
    if (_lunchChecked) meals.add('lunch');
    if (_dinnerChecked) meals.add('dinner');
    return meals;
  }

  Future<void> _saveOnboardingData() async {
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid weight and height')),
      );
      return;
    }

    if (_selectedGender == null || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (session == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final age = _calculateAge(_birthDate!);
      final plan = NutritionCalculator.calculate(
        gender: _selectedGender!,
        age: age,
        heightCm: height,
        weightKg: weight,
        exercisesPerDay: _exercisePerDay,
        goal: _selectedGoal,
        sleepHours: _sleepHours,
      );

      final metadata = {
        'onboarding_completed': true,
        'height_cm': height.round(),
        'weight_kg': weight.round(),
        'chronic_disease': _selectedDisease,
        'gender': _selectedGender,
        'birth_date': _birthDate!.toIso8601String().split('T').first,
        'goal': _selectedGoal,
        'exercise_per_day': _exercisePerDay,
        'sleep_hours': _sleepHours,
        'meal_order': _mealOrder,
        'recommended_calories': plan.targetCalories,
        'recommended_protein': plan.proteinGrams,
        'recommended_carbs': plan.carbsGrams,
        'recommended_fat': plan.fatGrams,
        'recommended_bmr': plan.bmr,
        'recommended_tdee': plan.tdee,
        'recommended_water_liters': plan.waterLiters,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.auth.updateUser(UserAttributes(data: metadata));

      await supabase.from('daily_activity').insert({
        'user_id': user.id,
        'activity_date': DateTime.now().toIso8601String().split('T').first,
        'calories': 0,
        'calories_goal': plan.targetCalories,
        'carbs': 0,
        'carbs_goal': plan.carbsGrams,
        'protein': 0,
        'protein_goal': plan.proteinGrams,
        'fat': 0,
        'fat_goal': plan.fatGrams,
        'streak_days': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final active = index == _currentPage;
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF5E35B1) : const Color(0xFFD1C4E9),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPageTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Let\'s get started',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Tell us a few details so we can calculate your calories and activity goals accurately.',
            style: TextStyle(fontSize: 20, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageTitle(
          'Weight & height',
          'We use them to calculate your burn rate and recommended calories.',
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '70',
              labelText: 'Weight',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '167',
              labelText: 'Height',
              suffixText: 'cm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageTitle(
          'Gender & age',
          'Calories are calculated differently for males and females.',
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: InkWell(
            onTap: _pickBirthDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5E35B1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _birthDate == null
                    ? 'Select birth date'
                    : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Expanded(
                child: _GenderBox(
                  title: 'Male',
                  selected: _selectedGender == 'male',
                  onTap: () => setState(() => _selectedGender = 'male'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderBox(
                  title: 'Female',
                  selected: _selectedGender == 'female',
                  onTap: () => setState(() => _selectedGender = 'female'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifestylePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageTitle(
          'Daily routine',
          'Set your activity, goal, chronic disease, and average sleep.',
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: DropdownButtonFormField<int>(
            value: _exercisePerDay,
            decoration: InputDecoration(
              labelText: 'How many workouts per day?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: const [0, 1, 2, 3]
                .map(
                  (value) => DropdownMenuItem(
                value: value,
                child: Text(value == 3 ? '3+' : '$value'),
              ),
            )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _exercisePerDay = value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: DropdownButtonFormField<String>(
            value: _selectedGoal,
            decoration: InputDecoration(
              labelText: 'What is your goal?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'lose_weight',
                child: Text('Lose weight'),
              ),
              DropdownMenuItem(
                value: 'gain_weight',
                child: Text('Gain weight'),
              ),
              DropdownMenuItem(
                value: 'maintain_weight',
                child: Text('Maintain weight'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedGoal = value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: DropdownButtonFormField<String>(
            value: _selectedDisease,
            decoration: InputDecoration(
              labelText: 'Chronic disease',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: _diseaseOptions
                .map(
                  (disease) => DropdownMenuItem(
                value: disease,
                child: Text(_diseaseLabel(disease)),
              ),
            )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDisease = value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average sleep: ${_sleepHours.toStringAsFixed(1)} hours',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _sleepHours,
                min: 3,
                max: 12,
                divisions: 18,
                label: _sleepHours.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _sleepHours = value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealsPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageTitle(
          'Meal order',
          'Choose the main meals ترتيب الوجبات الرئيسية: فطور ثم غداء ثم عشاء.',
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              _MealCheckboxTile(
                title: 'Breakfast',
                subtitle: '1st main meal',
                value: _breakfastChecked,
                onChanged: (value) {
                  setState(() => _breakfastChecked = value ?? false);
                },
              ),
              const SizedBox(height: 12),
              _MealCheckboxTile(
                title: 'Lunch',
                subtitle: '2nd main meal',
                value: _lunchChecked,
                onChanged: (value) {
                  setState(() => _lunchChecked = value ?? false);
                },
              ),
              const SizedBox(height: 12),
              _MealCheckboxTile(
                title: 'Dinner',
                subtitle: '3rd main meal',
                value: _dinnerChecked,
                onChanged: (value) {
                  setState(() => _dinnerChecked = value ?? false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageTitle(
          'Ready to calculate',
          'We will generate your daily calorie target and show it on Activity screen.',
        ),
        const SizedBox(height: 28),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFB),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(label: 'Weight', value: '${_weightController.text} kg'),
              _ReviewRow(label: 'Height', value: '${_heightController.text} cm'),
              _ReviewRow(
                label: 'Goal',
                value: _goalLabel(_selectedGoal),
              ),
              _ReviewRow(
                label: 'Exercise/day',
                value: _exercisePerDay == 3 ? '3+' : '$_exercisePerDay',
              ),
              _ReviewRow(
                label: 'Sleep',
                value: '${_sleepHours.toStringAsFixed(1)} h',
              ),
              _ReviewRow(
                label: 'Disease',
                value: _diseaseLabel(_selectedDisease),
              ),
              _ReviewRow(
                label: 'Meals',
                value: _mealOrder.join(' > '),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _currentPage == _totalPages - 1 ? 'Finish' : 'Continue';

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _prevPage();
          return false;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _currentPage > 0
              ? IconButton(
            onPressed: _prevPage,
            icon: const Icon(Icons.arrow_back),
          )
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildBodyPage(),
                    _buildPersonalPage(),
                    _buildLifestylePage(),
                    _buildMealsPage(),
                    _buildReviewPage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProgress(),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_canContinue && !_loading) ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E35B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
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

class _GenderBox extends StatelessWidget {
  const _GenderBox({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF5E35B1)),
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFFEDE7F6) : Colors.white,
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _MealCheckboxTile extends StatelessWidget {
  const _MealCheckboxTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1C4E9)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF5E35B1),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF40236F),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}