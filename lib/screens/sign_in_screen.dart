import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import 'app_entry_router.dart';
import 'create_account_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  bool rememberMe = true;
  bool obscurePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final session = data.session;

          if (session != null && mounted && !_navigated) {
            _goToHome();
          }
        });

    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _navigated) return;
        _goToHome();
      });
    }
  }

  void _goToHome() {
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppEntryRouter()),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void goToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateAccountScreen(),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email';

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _googleRedirectTo() {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'io.supabase.gppro://login-callback';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  LaunchMode _googleLaunchMode() {
    if (kIsWeb) return LaunchMode.platformDefault;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return LaunchMode.externalApplication;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return LaunchMode.platformDefault;
    }
  }

  Future<void> signIn() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        isGoogleLoading = true;
      });

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _googleRedirectTo(),
        scopes: 'openid email profile',
        authScreenLaunchMode: _googleLaunchMode(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isGoogleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isGoogleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign in error: $e')),
      );
    }
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset password error: $e')),
      );
    }
  }

  Widget logo() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 36,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget divider() {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Or'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget rememberRow() {
    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          activeColor: AppColors.primary,
          onChanged: isLoading
              ? null
              : (value) {
            setState(() {
              rememberMe = value ?? false;
            });
          },
        ),
        const Text('Remember me'),
        const Spacer(),
        TextButton(
          onPressed: isLoading ? null : resetPassword,
          child: const Text(
            'Forgot password?',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget bottomText() {
    return Center(
      child: GestureDetector(
        onTap: goToCreateAccount,
        child: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black),
            children: [
              TextSpan(text: 'Don’t have an account? '),
              TextSpan(
                text: 'Create account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = isLoading || isGoogleLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 30),
                Center(child: logo()),
                const SizedBox(height: 50),
                const Text(
                  'Let’s Sign in',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get started to the healthy journey',
                  style: TextStyle(color: AppColors.textGray),
                ),
                const SizedBox(height: 30),
                const SectionLabel(text: 'Email'),
                const SizedBox(height: 10),
                AuthTextField(
                  controller: emailController,
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  hintText: 'Enter your email',
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                const SectionLabel(text: 'Password'),
                const SizedBox(height: 10),
                AuthTextField(
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  hintText: 'Enter your password',
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => signIn(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 15),
                rememberRow(),
                const SizedBox(height: 20),
                PrimaryAuthButton(
                  text: isLoading ? 'Loading...' : 'Sign in',
                  onPressed: isBusy ? null : signIn,
                ),
                const SizedBox(height: 25),
                divider(),
                const SizedBox(height: 25),
                GoogleAuthButton(
                  onPressed: isBusy ? null : signInWithGoogle,
                  text: isGoogleLoading
                      ? 'Loading...'
                      : 'Continue with Google',
                  imagePath: 'assets/images/google.png',
                ),
                const SizedBox(height: 60),
                bottomText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}