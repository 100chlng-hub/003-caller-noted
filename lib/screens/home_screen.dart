import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import '../models/call_session.dart';
import '../services/notification_service.dart';
import 'quick_event_modal.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserSettings settings;

  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserSettings _currentSettings;

  // Mock list of recent calls processed
  final List<CallSession> _recentSessions = [
    CallSession(
      id: '1',
      phoneNumber: '+39 347 1234567',
      contactName: 'Mario Rossi (Idraulica)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      durationSeconds: 142,
      hasEventCreated: true,
    ),
    CallSession(
      id: '2',
      phoneNumber: '+39 338 9876543',
      contactName: null,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      durationSeconds: 85,
      hasEventCreated: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
    _initNotifications();
  }

  void _initNotifications() {
    NotificationService().initialize(
      onSelectNotification: (payload) {
        if (payload != null && payload.isNotEmpty) {
          final parts = payload.split('|');
          final phone = parts[0];
          final contact = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
          _openQuickEventModal(phoneNumber: phone, contactName: contact);
        }
      },
    );
  }

  void _openQuickEventModal({String? phoneNumber, String? contactName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickEventModal(
        phoneNumber: phoneNumber,
        contactName: contactName,
        settings: _currentSettings,
      ),
    );
  }

  void _simulateIncomingCallEnd() async {
    // Simulates an incoming call finishing, triggering notification
    const testPhone = '+39 349 5550192';
    const testContact = 'Giuseppe Verdi (Elettricista)';

    await NotificationService().showCallEndedNotification(
      phoneNumber: testPhone,
      contactName: testContact,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulazione: Chiamata terminata! Notifica heads-up inviata.'),
        backgroundColor: Colors.blue,
      ),
    );

    // Also auto-open modal for quick test
    _openQuickEventModal(phoneNumber: testPhone, contactName: testContact);
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'it_IT');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caller-Noted'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    settings: _currentSettings,
                    onSettingsUpdated: (updated) {
                      setState(() => _currentSettings = updated);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Service Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Rilevamento Telefonate Attivo',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Calendario attivo: ${_currentSettings.defaultCalendarName ?? "Non selezionato"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'Filtro: ignora chiamate < ${_currentSettings.minCallDurationSeconds}s',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Simulation Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _simulateIncomingCallEnd,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Simula Fine Telefonata (Test Flow)'),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Ultime Chiamate Elaborate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List of recent calls
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentSessions.length,
              itemBuilder: (context, index) {
                final session = _recentSessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: session.hasEventCreated ? Colors.green.shade50 : Colors.orange.shade50,
                      child: Icon(
                        session.hasEventCreated ? Icons.event_available : Icons.phone_callback,
                        color: session.hasEventCreated ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(
                      session.contactName ?? session.phoneNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Durata: ${session.durationSeconds}s • ${timeFormat.format(session.timestamp)}',
                    ),
                    trailing: session.hasEventCreated
                        ? const Chip(
                            label: Text('A Calendario', style: TextStyle(fontSize: 11, color: Colors.green)),
                            backgroundColor: Color(0xFFE8F5E9),
                          )
                        : TextButton(
                            onPressed: () => _openQuickEventModal(
                              phoneNumber: session.phoneNumber,
                              contactName: session.contactName,
                            ),
                            child: const Text('Crea Ora'),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickEventModal(),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic),
        label: const Text('Nuovo Appuntamento'),
      ),
    );
  }
}
