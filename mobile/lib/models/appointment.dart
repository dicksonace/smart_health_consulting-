enum AppointmentStatus { confirmed, completed, cancelled }

enum AppointmentType { inPerson, video, chat }

enum UrgencyLevel { low, medium, high, emergency }

class Appointment {
  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.scheduledAt,
    required this.type,
    required this.status,
    this.reason,
    this.urgency = UrgencyLevel.low,
    this.hasFeedback = false,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime scheduledAt;
  final AppointmentType type;
  AppointmentStatus status;
  final String? reason;
  final UrgencyLevel urgency;
  final bool hasFeedback;

  String get typeLabel {
    switch (type) {
      case AppointmentType.inPerson:
        return 'In Person';
      case AppointmentType.video:
        return 'Video Call';
      case AppointmentType.chat:
        return 'Chat';
    }
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
