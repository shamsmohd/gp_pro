# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**gp_pro** is a Flutter health-tracking mobile app using Supabase as the backend. It tracks health metrics (blood pressure, blood sugar, temperature, calories, hydration, sleep), provides nutrition planning with macro calculations, supports food image scanning/uploading, and delivers real-time notifications via Supabase Realtime channels.

## Common Commands

- **Run app:** `flutter run`
- **Run on specific device:** `flutter run -d <device_id>` (use `flutter devices` to list)
- **Analyze:** `flutter analyze`
- **Run all tests:** `flutter test`
- **Run single test:** `flutter test test/<file>.dart`
- **Get dependencies:** `flutter pub get`
- **Build Android APK:** `flutter build apk`
- **Build iOS:** `flutter build ios`

## Architecture

### Entry Flow
`main.dart` → initializes Supabase + local notifications + theme → `SplashScreen` → `AppEntryRouter` which checks auth session and onboarding status, routing to:
- `SignInScreen` / `CreateAccountScreen` (unauthenticated)
- `OnboardingProfileScreen` (authenticated, onboarding incomplete)
- `RootScreen` (authenticated, onboarding complete)

### Navigation
`RootScreen` uses an `IndexedStack` with a custom floating bottom nav bar (`AppBottomFloatingNav`). Five tabs: Home, Activity, Scanner, Notifications, Profile.

### Backend (Supabase)
- **Auth:** Email/password + Google OAuth with PKCE flow. User metadata stores profile fields (`full_name`, `avatar_url`, `dark_mode_enabled`, `onboarding_completed`, etc.).
- **Database tables:** `health_metrics`, `daily_activity`, `food_scans`
- **Storage:** `food-images` bucket for scanner uploads
- **Realtime:** Subscriptions on `daily_activity` and `health_metrics` tables trigger local notifications on changes

### Key Modules
- `lib/theme.dart` — `AppColors`, `appTheme`, `darkAppTheme` with Material 3 and Poppins font. Global `appThemeMode` ValueNotifier in `main.dart` drives light/dark switching.
- `lib/utils_nutrition_calculator.dart` — `NutritionCalculator` computes BMR (Mifflin-St Jeor), TDEE, macros, water intake, and sleep score from user profile data.
- `lib/services/local_notification_service.dart` — Singleton wrapping `flutter_local_notifications` for Android/iOS/macOS.
- `lib/widgets/` — Shared `buttons.dart` and `inputs.dart` used across auth screens.

### Dependencies
- `supabase_flutter` — Auth, database, storage, realtime
- `image_picker` — Camera/gallery for food scanner
- `flutter_local_notifications` — Push notifications
- Linting: `flutter_lints` (configured in `analysis_options.yaml`)

### SDK Requirements
- Dart SDK: `^3.6.0`
- Android minSdk: 21, namespace: `com.example.gp_pro`
