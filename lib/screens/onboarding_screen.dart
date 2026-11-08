import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_settings.dart';
import '../services/calendar_service.dart';
import '../services/settings_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final UserSettings settings;

  const OnboardingScreen({super.key, required this.settings});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final CalendarService _calendarService = CalendarService();
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _apiKeyController = TextEditingController();

  bool _calendarPermission = false;
  bool _phonePermission = false;
  bool _contactsPermission = false;
  bool _micPermission = false;

  List<Calendar> _availableCalendars = [];
  String? _selectedCalendarId;
  String? _selectedCalendarName;
  bool _isLoadingCalendars = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.settings.geminiApiKey;
    _checkPermissions();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final cal = await Permission.calendarFullAccess.isGranted;
    final phone = await Permission.phone.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final mic = await Permission.microphone.isGranted;

    setState(() {
      _calendarPermission = cal;
      _phonePermission = phone;
      _contactsPermission = contacts;
      _micPermission = mic;
    });

    if (cal) {
      _loadCalendars();
    }
  }

  Future<void> _requestCalendarPermission() async {
    final granted = await _calendarService.checkOrRequestPermission();
    setState(() => _calendarPermission = granted);
    if (granted) {
      _loadCalendars();
    }
  }

  Future<void> _requestPhonePermission() async {
    final status = await Permission.phone.request();
    setState(() => _phonePermission = status.isGranted);
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    setState(() => _contactsPermission = status.isGranted);
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _micPermission = status.isGranted);
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoadingCalendars = true);
    final calendars = await _calendarService.getAvailableCalendars();
    setState(() {
      _availableCalendars = calendars;
      _isLoadingCalendars = false;
      if (calendars.isNotEmpty) {
        // Pick primary or first
        final defaultCal = calendars.firstWhere(
          (c) => c.isDefault == true,
          orElse: () => calendars.first,
        );
        _selectedCalendarId = defaultCal.id;
        _selectedCalendarName = defaultCal.name;
      }
    });
  }

  Future<void> _finishOnboarding() async {
    if (_selectedCalendarId == null && _availableCalendars.isNotEmpty) {
      _selectedCalendarId = _availableCalendars.first.id;
      _selectedCalendarName = _availableCalendars.first.name;
    }

    final updated = UserSettings(
      defaultCalendarId: _selectedCalendarId,
      defaultCalendarName: _selectedCalendarName,
      geminiApiKey: _apiKeyController.text.trim(),
      minCallDurationSeconds: widget.settings.minCallDurationSeconds,
      autoPromptSaveContact: widget.settings.autoPromptSaveContact,
      defaultEventDurationMinutes: widget.settings.defaultEventDurationMinutes,
      isOnboardingCompleted: true,
    );

    await _settingsService.saveSettings(updated);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(settings: updated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benvenuto in Caller-Noted'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Configurazione Iniziale',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Caller-Noted trasforma le tue telefonate di lavoro in appuntamenti a calendario in pochi secondi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Step 1: Permissions
            const Text(
              '1. Permessi Richiesti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPermissionTile(
              title: 'Calendario Dispositivo',
              subtitle: 'Per inserire e salvare gli appuntamenti',
              icon: Icons.calendar_today,
              isGranted: _calendarPermission,
              onRequest: _requestCalendarPermission,
            ),
            _buildPermissionTile(
              title: 'Stato Telefono & Chiamate',
              subtitle: 'Per rilevare il termine delle telefonate',
              icon: Icons.phone,
              isGranted: _phonePermission,
              onRequest: _requestPhonePermission,
            ),
            _buildPermissionTile(
              title: 'Contatti & Rubrica',
              subtitle: 'Per associare il nome e salvare nuovi numeri',
              icon: Icons.contacts,
              isGranted: _contactsPermission,
              onRequest: _requestContactsPermission,
            ),
            _buildPermissionTile(
              title: 'Microfono',
              subtitle: 'Per la dettatura vocale rapida post-chiamata',
              icon: Icons.mic,
              isGranted: _micPermission,
              onRequest: _requestMicPermission,
            ),
            const SizedBox(height: 24),

            // Step 2: Calendar Selection
            const Text(
              '2. Scegli il Calendario di Destinazione',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingCalendars)
              const Center(child: CircularProgressIndicator())
            else if (_availableCalendars.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Nessun calendario rilevato. Assicurati di aver concesso il permesso Calendario.'),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCalendarId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                items: _availableCalendars.map((cal) {
                  return DropdownMenuItem<String>(
                    value: cal.id,
                    child: Text('${cal.name} (${cal.accountName ?? 'Locale'})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCalendarId = val;
                    _selectedCalendarName = _availableCalendars.firstWhere((c) => c.id == val).name;
                  });
                },
              ),
            const SizedBox(height: 24),

            // Step 3: Gemini API Key
            const Text(
              '3. Chiave Google Gemini API (Opzionale)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilizzata per il parsing intelligente della nota vocale in JSON. Se lasciata vuota, verrà usato il parser di base.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 32),

            // Start Button
            ElevatedButton(
              onPressed: _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Inizia a Usare Caller-Noted',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isGranted ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: isGranted ? Colors.green : Colors.grey.shade600),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : OutlinedButton(
                onPressed: onRequest,
                child: const Text('Consenti'),
              ),
      ),
    );
  }
}
