import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import '../models/user_settings.dart';
import '../services/calendar_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserSettings settings;
  final Function(UserSettings) onSettingsUpdated;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CalendarService _calendarService = CalendarService();
  final SettingsService _settingsService = SettingsService();

  late TextEditingController _apiKeyController;
  late String? _selectedCalendarId;
  late double _minCallDuration;
  late bool _autoPromptContact;
  late int _defaultDuration;

  List<Calendar> _calendars = [];
  bool _isLoadingCalendars = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.settings.geminiApiKey);
    _selectedCalendarId = widget.settings.defaultCalendarId;
    _minCallDuration = widget.settings.minCallDurationSeconds.toDouble();
    _autoPromptContact = widget.settings.autoPromptSaveContact;
    _defaultDuration = widget.settings.defaultEventDurationMinutes;
    _loadCalendars();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoadingCalendars = true);
    final calendars = await _calendarService.getAvailableCalendars();
    setState(() {
      _calendars = calendars;
      _isLoadingCalendars = false;
    });
  }

  Future<void> _saveAll() async {
    String? calName;
    if (_selectedCalendarId != null) {
      try {
        calName = _calendars.firstWhere((c) => c.id == _selectedCalendarId).name;
      } catch (_) {}
    }

    final updated = UserSettings(
      defaultCalendarId: _selectedCalendarId,
      defaultCalendarName: calName ?? widget.settings.defaultCalendarName,
      geminiApiKey: _apiKeyController.text.trim(),
      minCallDurationSeconds: _minCallDuration.toInt(),
      autoPromptSaveContact: _autoPromptContact,
      defaultEventDurationMinutes: _defaultDuration,
      isOnboardingCompleted: true,
    );

    await _settingsService.saveSettings(updated);
    widget.onSettingsUpdated(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate con successo!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Calendario',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          if (_isLoadingCalendars)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedCalendarId,
              decoration: const InputDecoration(
                labelText: 'Calendario di Destinazione',
                border: OutlineInputBorder(),
              ),
              items: _calendars.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name} (${c.accountName ?? "Locale"})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCalendarId = val);
              },
            ),
          const SizedBox(height: 24),

          const Text(
            'Motore AI (Google Gemini)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(),
              helperText: 'Ottenibile gratuitamente da Google AI Studio',
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Filtri Chiamate & Notifiche',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            'Ignora chiamate con durata inferiore a: ${_minCallDuration.toInt()} secondi',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _minCallDuration,
            min: 0,
            max: 60,
            divisions: 12,
            label: '${_minCallDuration.toInt()}s',
            onChanged: (val) {
              setState(() => _minCallDuration = val);
            },
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Suggerisci salvataggio nuovo contatto'),
            subtitle: const Text('Se il numero non è in rubrica, pre-seleziona il salvataggio del contatto'),
            value: _autoPromptContact,
            onChanged: (val) {
              setState(() => _autoPromptContact = val);
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'Preferenze Evento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _defaultDuration,
            decoration: const InputDecoration(
              labelText: 'Durata Standard Appuntamento',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 minuti')),
              DropdownMenuItem(value: 60, child: Text('60 minuti (1 ora)')),
              DropdownMenuItem(value: 90, child: Text('90 minuti (1.5 ore)')),
              DropdownMenuItem(value: 120, child: Text('120 minuti (2 ore)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _defaultDuration = val);
            },
          ),
        ],
      ),
    );
  }
}
