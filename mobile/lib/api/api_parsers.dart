import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/medical_record.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';

class ApiParsers {
  static UserRole parseRole(String? role) {
    switch (role) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  static AppUser userFromJson(Map<String, dynamic> json) {
    final role = parseRole(json['role'] as String?);
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final patient = json['patient'] as Map<String, dynamic>?;

    return AppUser(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: role,
      specialty: doctor?['specialty'] as String?,
      qualifications: doctor?['qualifications'] as String?,
      consultationFee: doctor?['consultation_fee'] != null
          ? double.tryParse(doctor!['consultation_fee'].toString())
          : null,
      dateOfBirth: patient?['date_of_birth'] as String?,
      bloodGroup: patient?['blood_group'] as String?,
      allergies: patient?['allergies'] as String?,
    );
  }

  static Doctor doctorFromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return Doctor(
      id: json['id'].toString(),
      name: user['name'] as String? ?? 'Doctor',
      specialty: json['specialty'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      yearsExperience: json['years_experience'] as int? ?? 0,
      consultationFee: double.tryParse(json['consultation_fee']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0,
      reviewCount: 0,
      bio: json['bio'] as String? ?? '',
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  static Appointment appointmentFromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? {};
    final patientUser = patient['user'] as Map<String, dynamic>? ?? {};
    final doctor = json['doctor'] as Map<String, dynamic>? ?? {};
    final doctorUser = doctor['user'] as Map<String, dynamic>? ?? {};

    return Appointment(
      id: json['id'].toString(),
      patientId: json['patient_id']?.toString() ?? patient['id']?.toString() ?? '',
      patientName: patientUser['name'] as String? ?? 'Patient',
      doctorId: json['doctor_id']?.toString() ?? doctor['id']?.toString() ?? '',
      doctorName: doctorUser['name'] as String? ?? 'Doctor',
      doctorSpecialty: doctor['specialty'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      type: _parseType(json['type'] as String?),
      status: _parseStatus(json['status'] as String?),
      reason: json['reason'] as String?,
      urgency: _parseUrgency(json['urgency'] as String?),
    );
  }

  static AppointmentType _parseType(String? type) {
    switch (type) {
      case 'in_person':
        return AppointmentType.inPerson;
      case 'chat':
        return AppointmentType.chat;
      default:
        return AppointmentType.video;
    }
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.confirmed;
    }
  }

  static UrgencyLevel _parseUrgency(String? urgency) {
    switch (urgency) {
      case 'emergency':
        return UrgencyLevel.emergency;
      case 'high':
        return UrgencyLevel.high;
      case 'medium':
        return UrgencyLevel.medium;
      default:
        return UrgencyLevel.low;
    }
  }

  static String typeToApi(AppointmentType type) {
    switch (type) {
      case AppointmentType.inPerson:
        return 'in_person';
      case AppointmentType.chat:
        return 'chat';
      case AppointmentType.video:
        return 'video';
    }
  }

  static TimeSlot slotFromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String;
    final date = DateTime.parse(dateStr.contains('T') ? dateStr : '${dateStr}T00:00:00');
    return TimeSlot(
      id: json['id'].toString(),
      doctorId: json['doctor_id'].toString(),
      date: date,
      startTime: _formatTime(json['start_time']),
      endTime: _formatTime(json['end_time']),
      isAvailable: json['status'] == 'available',
    );
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '00:00';
    final str = value.toString();
    if (str.length >= 5) return str.substring(0, 5);
    return str;
  }

  static Conversation conversationFromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>? ?? {};
    final lastMsg = json['last_message'] as Map<String, dynamic>?;
    return Conversation(
      id: partner['id'].toString(),
      participantId: partner['id'].toString(),
      participantName: partner['name'] as String? ?? 'User',
      participantRole: partner['role'] as String? ?? 'user',
      lastMessage: lastMsg?['body'] as String? ?? '',
      lastMessageAt: lastMsg?['created_at'] != null
          ? DateTime.parse(lastMsg!['created_at'] as String)
          : DateTime.now(),
      unreadCount: json['unread_count'] as int? ?? 0,
      messages: [],
    );
  }

  static ChatMessage messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      body: json['body'] as String? ?? '',
      sentAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read_at'] != null,
    );
  }

  static AppNotification notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read_at'] != null,
    );
  }

  static MedicalRecord recordFromJson(Map<String, dynamic> json) {
    final appointment = json['appointment'] as Map<String, dynamic>? ?? {};
    final doctor = appointment['doctor'] as Map<String, dynamic>? ?? {};
    final doctorUser = doctor['user'] as Map<String, dynamic>? ?? {};
    final prescriptions = (json['prescriptions'] as List? ?? [])
        .map((p) => Prescription(
              medicineName: p['medicine_name'] as String? ?? '',
              dosage: p['dosage'] as String? ?? '',
              duration: p['duration'] as String? ?? '',
              instructions: p['instructions'] as String?,
            ))
        .toList();

    return MedicalRecord(
      id: json['id'].toString(),
      appointmentId: json['appointment_id']?.toString() ?? appointment['id']?.toString() ?? '',
      doctorName: doctorUser['name'] as String? ?? 'Doctor',
      doctorSpecialty: doctor['specialty'] as String? ?? '',
      visitDate: appointment['scheduled_at'] != null
          ? DateTime.parse(appointment['scheduled_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      diagnosis: json['diagnosis'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      recommendations: json['recommendations'] as String? ?? '',
      prescriptions: prescriptions,
    );
  }
}
