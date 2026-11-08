class CallSession {
  final String id;
  final String phoneNumber;
  final String? contactName;
  final DateTime timestamp;
  final int durationSeconds;
  bool hasEventCreated;

  CallSession({
    required this.id,
    required this.phoneNumber,
    this.contactName,
    required this.timestamp,
    required this.durationSeconds,
    this.hasEventCreated = false,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      contactName: json['contactName'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      durationSeconds: json['durationSeconds'] ?? 0,
      hasEventCreated: json['hasEventCreated'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'hasEventCreated': hasEventCreated,
    };
  }
}
