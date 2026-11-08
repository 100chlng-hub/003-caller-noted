class CalendarEventDraft {
  String title;
  DateTime startTime;
  DateTime endTime;
  String? location;
  String? description;
  String? phoneNumber;
  String? contactName;
  bool isNewContact;
  String? calendarId;
  String? rawTranscript;

  CalendarEventDraft({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.description,
    this.phoneNumber,
    this.contactName,
    this.isNewContact = false,
    this.calendarId,
    this.rawTranscript,
  });

  factory CalendarEventDraft.fromJson(Map<String, dynamic> json, {String? phoneNumber, String? contactName}) {
    final now = DateTime.now();
    DateTime start = now.add(const Duration(days: 1));
    DateTime end = start.add(const Duration(hours: 1));

    if (json['startDate'] != null) {
      try {
        start = DateTime.parse(json['startDate']);
      } catch (_) {}
    }

    if (json['endDate'] != null) {
      try {
        end = DateTime.parse(json['endDate']);
      } catch (_) {
        end = start.add(const Duration(hours: 1));
      }
    } else {
      end = start.add(const Duration(hours: 1));
    }

    return CalendarEventDraft(
      title: json['title'] ?? 'Nuovo Appuntamento',
      startTime: start,
      endTime: end,
      location: json['location'],
      description: json['description'],
      phoneNumber: phoneNumber ?? json['phoneNumber'],
      contactName: contactName ?? json['contactName'],
      isNewContact: json['isNewContact'] == true,
      rawTranscript: json['rawTranscript'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startTime.toIso8601String(),
      'endDate': endTime.toIso8601String(),
      'location': location,
      'description': description,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'isNewContact': isNewContact,
      'calendarId': calendarId,
      'rawTranscript': rawTranscript,
    };
  }
}
