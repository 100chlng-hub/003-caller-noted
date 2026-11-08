import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/calendar_event_draft.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  bool _isTimezoneInitialized = false;

  void _initTimezone() {
    if (!_isTimezoneInitialized) {
      tz.initializeTimeZones();
      _isTimezoneInitialized = true;
    }
  }

  Future<bool> checkOrRequestPermission() async {
    final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
      return true;
    }
    final requestResult = await _deviceCalendarPlugin.requestPermissions();
    return requestResult.isSuccess && (requestResult.data ?? false);
  }

  Future<List<Calendar>> getAvailableCalendars() async {
    final hasPerm = await checkOrRequestPermission();
    if (!hasPerm) return [];

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      // Filter out read-only calendars
      return calendarsResult.data!.where((c) => !(c.isReadOnly ?? false)).toList();
    }
    return [];
  }

  Future<bool> saveEvent({
    required CalendarEventDraft draft,
    required String calendarId,
  }) async {
    _initTimezone();
    final hasPerm = await checkOrRequestPermission();
    if (!hasPerm) return false;

    final location = tz.local;
    final startTZ = tz.TZDateTime.from(draft.startTime, location);
    final endTZ = tz.TZDateTime.from(draft.endTime, location);

    // Build rich description including caller contact & phone
    final StringBuffer fullDescription = StringBuffer();
    if (draft.description != null && draft.description!.isNotEmpty) {
      fullDescription.writeln(draft.description);
      fullDescription.writeln();
    }
    if (draft.contactName != null && draft.contactName!.isNotEmpty) {
      fullDescription.writeln('👤 Contatto: ${draft.contactName}');
    }
    if (draft.phoneNumber != null && draft.phoneNumber!.isNotEmpty) {
      fullDescription.writeln('📞 Telefono: ${draft.phoneNumber}');
    }
    fullDescription.writeln('⚡ Creato con Caller-Noted');

    final event = Event(
      calendarId,
      title: draft.title,
      start: startTZ,
      end: endTZ,
      description: fullDescription.toString(),
      location: draft.location,
      reminders: [Reminder(minutes: 60)], // Default 1h reminder
    );

    final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    return createResult?.isSuccess == true;
  }
}
