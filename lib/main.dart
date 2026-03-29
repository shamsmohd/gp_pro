import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'services/local_notification_service.dart';
import 'theme.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gmdosbaezuykmyuiidhk.supabase.co',

    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtZG9zYmFlenV5a215dWlpZGhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNzg5NjYsImV4cCI6MjA4ODc1NDk2Nn0.w1_wDYwuOSoX3QpaDjryGdV86j2qrNKJrAxMSKLM-a0',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  await LocalNotificationService.instance.init();
  await _loadInitialThemeMode();

  runApp(const MyApp());
}

Future<void> _loadInitialThemeMode() async {
  final user = Supabase.instance.client.auth.currentUser;
  final metadata = user?.userMetadata ?? const <String, dynamic>{};

  final darkModeEnabled = metadata['dark_mode_enabled'];
  if (darkModeEnabled is bool && darkModeEnabled) {
    appThemeMode.value = ThemeMode.dark;
  } else {
    appThemeMode.value = ThemeMode.light;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SupabaseClient _supabase;
  RealtimeChannel? _userRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _setupAuthListener();
    _setupRealtimeForCurrentUser();
  }

  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        _setupRealtimeForCurrentUser();
      }

      if (event == AuthChangeEvent.signedOut) {
        _removeRealtimeChannel();
      }
    });
  }

  void _setupRealtimeForCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _removeRealtimeChannel();

    _userRealtimeChannel = _supabase.channel('user-realtime-${user.id}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'daily_activity',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) async {
          final newRecord = payload.newRecord;
          final caloriesGoal = _readInt(newRecord['calories_goal'], 0);

          await LocalNotificationService.instance.showRealtimeUpdate(
            'Activity Updated',
            caloriesGoal > 0
                ? 'Your calorie goal is now $caloriesGoal kcal.'
                : 'Your daily activity has been updated.',
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'health_metrics',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) async {
          await LocalNotificationService.instance.showRealtimeUpdate(
            'Health Metrics Updated',
            'A new health reading has been synced in real time.',
          );
        },
      )
      ..subscribe();
  }

  void _removeRealtimeChannel() {
    if (_userRealtimeChannel != null) {
      _supabase.removeChannel(_userRealtimeChannel!);
      _userRealtimeChannel = null;
    }
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  @override
  void dispose() {
    _removeRealtimeChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'gp_pro',
          theme: appTheme,
          darkTheme: darkAppTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}