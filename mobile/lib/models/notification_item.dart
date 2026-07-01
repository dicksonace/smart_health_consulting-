class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  bool isRead;
}

class TimeSlot {
  TimeSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String id;
  final String doctorId;
  final DateTime date;
  final String startTime;
  final String endTime;
  bool isAvailable;
}

class SymptomResult {
  const SymptomResult({
    required this.suggestedSpecialty,
    required this.urgency,
    required this.summary,
    required this.advice,
  });

  final String suggestedSpecialty;
  final String urgency;
  final String summary;
  final String advice;
}
