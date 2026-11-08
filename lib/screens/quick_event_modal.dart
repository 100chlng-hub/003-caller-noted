import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event_draft.dart';
import '../models/user_settings.dart';
import '../services/calendar_service.dart';
import '../services/contacts_service.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';

class QuickEventModal extends StatefulWidget {
  final String? phoneNumber;
  final String? contactName;
  final UserSettings settings;

  const QuickEventModal({
    super.key,
    this.phoneNumber,
    this.contactName,
    required this.settings,
  });

  @override
  State<QuickEventModal> createState() => _QuickEventModalState();
}

class _QuickEventModalState extends State<QuickEventModal> {
  final SpeechService _speechService = SpeechService();
  final CalendarService _calendarService = CalendarService();
  final ContactsService _contactsService = ContactsService();

  bool _isListening = false;
  bool _isProcessingAI = false;
  bool _isSaving = false;
  String _liveTranscript = '';

  CalendarEventDraft? _draft;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  bool _saveToContacts = false;
  String? _selectedCalendarId;

  @override
  void initState() {
    super.initState();
    _selectedCalendarId = widget.settings.defaultCalendarId;
    _contactNameController.text = widget.contactName ?? '';
    _saveToContacts = widget.settings.autoPromptSaveContact && widget.contactName == null && widget.phoneNumber != null;
    
    // Auto start voice listening if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceCapture();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  void _startVoiceCapture() async {
    setState(() {
      _isListening = true;
      _liveTranscript = 'In ascolto... parla pure (es. "Sopralluogo domani alle 15 con Mario")';
    });

    await _speechService.startListening(
      onResult: (text) {
        setState(() {
          _liveTranscript = text;
        });
      },
    );
  }

  void _stopAndProcessAI() async {
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
      _isProcessingAI = true;
    });

    final gemini = GeminiService(apiKey: widget.settings.geminiApiKey);
    final draft = await gemini.parseAppointmentFromVoice(
      voiceTranscript: _liveTranscript,
      phoneNumber: widget.phoneNumber,
      knownContactName: widget.contactName,
    );

    setState(() {
      _draft = draft;
      _isProcessingAI = false;
      _titleController.text = draft.title;
      _locationController.text = draft.location ?? '';
      _descriptionController.text = draft.description ?? '';
      if (draft.contactName != null && draft.contactName!.isNotEmpty) {
        _contactNameController.text = draft.contactName!;
      }
      _startDate = draft.startTime;
      _startTime = TimeOfDay.fromDateTime(draft.startTime);
      _endDate = draft.endTime;
      _endTime = TimeOfDay.fromDateTime(draft.endTime);
      _saveToContacts = draft.isNewContact;
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final initialTime = isStart ? _startTime : _endTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    setState(() {
      if (isStart) {
        _startDate = pickedDate;
        _startTime = pickedTime;
        _endDate = pickedDate;
        _endTime = TimeOfDay(hour: (pickedTime.hour + 1) % 24, minute: pickedTime.minute);
      } else {
        _endDate = pickedDate;
        _endTime = pickedTime;
      }
    });
  }

  void _saveEvent() async {
    if (_selectedCalendarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un calendario prima di salvare')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final draftToSave = CalendarEventDraft(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Nuovo Appuntamento',
      startTime: startDateTime,
      endTime: endDateTime,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      phoneNumber: widget.phoneNumber,
      contactName: _contactNameController.text.trim().isNotEmpty ? _contactNameController.text.trim() : null,
      calendarId: _selectedCalendarId,
      rawTranscript: _liveTranscript,
    );

    // Save to native calendar
    final success = await _calendarService.saveEvent(
      draft: draftToSave,
      calendarId: _selectedCalendarId!,
    );

    // Optionally save contact to address book
    if (_saveToContacts && widget.phoneNumber != null && _contactNameController.text.trim().isNotEmpty) {
      await _contactsService.createContact(
        displayName: _contactNameController.text.trim(),
        phoneNumber: widget.phoneNumber!,
      );
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Evento salvato con successo nel calendario!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio nel calendario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM yyyy', 'it_IT');

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with caller pill
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.phone_in_talk, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contactName ?? widget.phoneNumber ?? 'Chiamata Recente',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (widget.contactName != null && widget.phoneNumber != null)
                        Text(
                          widget.phoneNumber!,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Voice Capture Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening ? Colors.red.shade300 : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening ? 'Registrazione vocale in corso...' : 'Trascrizione Vocale',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isListening ? Colors.red : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveTranscript.isNotEmpty ? _liveTranscript : 'Tocca il microfono per dettare i dettagli...',
                    style: TextStyle(
                      fontStyle: _liveTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isListening)
                        ElevatedButton.icon(
                          onPressed: _stopAndProcessAI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.stop),
                          label: const Text('Fine Dettatura & AI'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _startVoiceCapture,
                          icon: const Icon(Icons.mic),
                          label: const Text('Riprova Vocale'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isProcessingAI)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Gemini sta estraendo i dettagli dell\'appuntamento...'),
                    ],
                  ),
                ),
              )
            else ...[
              // Event Form Fields
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo Appuntamento',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Date/Time Start & End Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        'Inizio:\n${dateFormat.format(_startDate)} ${_startTime.format(context)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: false),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        'Fine:\n${dateFormat.format(_endDate)} ${_endTime.format(context)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Luogo / Indirizzo Sopralluogo',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note & Dettagli Intervento',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Save to Contacts Checkbox
              if (widget.phoneNumber != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Salva anche in Rubrica'),
                  subtitle: Text('Aggiunge ${_contactNameController.text.isNotEmpty ? _contactNameController.text : widget.phoneNumber} ai contatti del telefono'),
                  value: _saveToContacts,
                  onChanged: (val) {
                    setState(() => _saveToContacts = val ?? false);
                  },
                ),

              const SizedBox(height: 20),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? 'Salvataggio in corso...' : 'Salva Evento in Calendario',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
