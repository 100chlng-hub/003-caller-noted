class UserSettings {
  String? defaultCalendarId;
  String? defaultCalendarName;
  String geminiApiKey;
  int minCallDurationSeconds;
  bool autoPromptSaveContact;
  int defaultEventDurationMinutes;
  bool isOnboardingCompleted;

  UserSettings({
    this.defaultCalendarId,
    this.defaultCalendarName,
    this.geminiApiKey = '',
    this.minCallDurationSeconds = 10,
    this.autoPromptSaveContact = true,
    this.defaultEventDurationMinutes = 60,
    this.isOnboardingCompleted = false,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      defaultCalendarId: map['defaultCalendarId'],
      defaultCalendarName: map['defaultCalendarName'],
      geminiApiKey: map['geminiApiKey'] ?? '',
      minCallDurationSeconds: map['minCallDurationSeconds'] ?? 10,
      autoPromptSaveContact: map['autoPromptSaveContact'] ?? true,
      defaultEventDurationMinutes: map['defaultEventDurationMinutes'] ?? 60,
      isOnboardingCompleted: map['isOnboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultCalendarId': defaultCalendarId,
      'defaultCalendarName': defaultCalendarName,
      'geminiApiKey': geminiApiKey,
      'minCallDurationSeconds': minCallDurationSeconds,
      'autoPromptSaveContact': autoPromptSaveContact,
      'defaultEventDurationMinutes': defaultEventDurationMinutes,
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  }
}
