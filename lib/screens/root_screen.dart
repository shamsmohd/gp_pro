import 'package:flutter/material.dart';

import 'activity_screen.dart';
import 'diet_plan_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late int _currentIndex;

  void _goToHome() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex = 0;
    });
  }

  late final List<Widget> _screens = [
    const HomeScreen(hideBottomNav: true),
    const ActivityScreen(hideBottomNav: true),
    ScannerScreen(
      hideBottomNav: true,
      onBackToHome: _goToHome,
    ),
    const DietPlanScreen(hideBottomNav: true),
    ProfileScreen(
      hideBottomNav: true,
      onBackToHome: _goToHome,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: AppBottomFloatingNav(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomFloatingNav extends StatelessWidget {
  const AppBottomFloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF1E1E22).withValues(alpha: 0.95),
            const Color(0xFF2A2236).withValues(alpha: 0.95),
          ]
              : [
            Colors.white.withValues(alpha: 0.65),
            const Color(0xFFEDE7F6).withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            isActive: currentIndex == 0,
            inactiveColor: inactiveColor,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.assignment_outlined,
            isActive: currentIndex == 1,
            inactiveColor: inactiveColor,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.camera_alt_outlined,
            isActive: currentIndex == 2,
            inactiveColor: inactiveColor,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.restaurant_menu_rounded,
            isActive: currentIndex == 3,
            inactiveColor: inactiveColor,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            isActive: currentIndex == 4,
            inactiveColor: inactiveColor,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C3FC8) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: const Color(0xFF6C3FC8).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : inactiveColor,
          size: 28,
        ),
      ),
    );
  }
}