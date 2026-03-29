import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'onboarding_profile_screen.dart';
import 'root_screen.dart';
import 'sign_in_screen.dart';

class AppEntryRouter extends StatefulWidget {
  const AppEntryRouter({super.key});

  @override
  State<AppEntryRouter> createState() => _AppEntryRouterState();
}

class _AppEntryRouterState extends State<AppEntryRouter> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (!mounted) return;

    if (session == null || user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      return;
    }

    final completed = user.userMetadata?['onboarding_completed'] == true;

    if (completed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}