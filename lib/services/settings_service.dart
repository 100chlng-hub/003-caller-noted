import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

class SettingsService {
  static const String _keyDefaultCalendarId = 'default_calendar_id';
  static const String _keyDefaultCalendarName = 'default_calendar_name';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyMinCallDuration = 'min_call_duration';
  static const String _keyAutoPromptContact = 'auto_prompt_contact';
  static const String _keyDefaultDuration = 'default_event_duration';
  static const String _keyOnboardingDone = 'onboarding_done';

  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      defaultCalendarId: prefs.getString(_keyDefaultCalendarId),
      defaultCalendarName: prefs.getString(_keyDefaultCalendarName),
      geminiApiKey: prefs.getString(_keyGeminiApiKey) ?? '',
      minCallDurationSeconds: prefs.getInt(_keyMinCallDuration) ?? 10,
      autoPromptSaveContact: prefs.getBool(_keyAutoPromptContact) ?? true,
      defaultEventDurationMinutes: prefs.getInt(_keyDefaultDuration) ?? 60,
      isOnboardingCompleted: prefs.getBool(_keyOnboardingDone) ?? false,
    );
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (settings.defaultCalendarId != null) {
      await prefs.setString(_keyDefaultCalendarId, settings.defaultCalendarId!);
    }
    if (settings.defaultCalendarName != null) {
      await prefs.setString(_keyDefaultCalendarName, settings.defaultCalendarName!);
    }
    await prefs.setString(_keyGeminiApiKey, settings.geminiApiKey);
    await prefs.setInt(_keyMinCallDuration, settings.minCallDurationSeconds);
    await prefs.setBool(_keyAutoPromptContact, settings.autoPromptSaveContact);
    await prefs.setInt(_keyDefaultDuration, settings.defaultEventDurationMinutes);
    await prefs.setBool(_keyOnboardingDone, settings.isOnboardingCompleted);
  }
}
