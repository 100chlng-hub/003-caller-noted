import 'package:flutter/material.dart';
import 'models/user_settings.dart';
import 'services/settings_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final settings = await settingsService.loadSettings();

  runApp(CallerNotedApp(initialSettings: settings));
}

class CallerNotedApp extends StatelessWidget {
  final UserSettings initialSettings;

  const CallerNotedApp({super.key, required this.initialSettings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caller-Noted',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: initialSettings.isOnboardingCompleted
          ? HomeScreen(settings: initialSettings)
          : OnboardingScreen(settings: initialSettings),
    );
  }
}
