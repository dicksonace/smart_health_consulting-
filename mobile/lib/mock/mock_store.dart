import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';
import 'mock_data.dart';

class MockStore extends ChangeNotifier {
  AppUser? _currentUser;
  late List<Appointment> appointments;
  late List<TimeSlot> slots;
  late List<Conversation> conversations;
  late List<AppNotification> notifications;
  final List<Doctor> doctors = MockData.doctors;

  MockStore() {
    reset();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void reset() {
    appointments = MockData.initialAppointments();
    slots = MockData.initialSlots();
    conversations = MockData.initialConversations();
    notifications = MockData.initialNotifications();
    _currentUser = null;
  }

  void loginAs(UserRole role) {
    switch (role) {
      case UserRole.patient:
        _currentUser = MockData.demoPatient;
      case UserRole.doctor:
        _currentUser = MockData.demoDoctor;
      case UserRole.admin:
        _currentUser = MockData.demoAdmin;
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  List<Appointment> get patientAppointments {
    if (_currentUser?.role != UserRole.patient) return [];
    return appointments
        .where((a) => a.patientId == _currentUser!.id)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  List<Appointment> get doctorAppointments {
    if (_currentUser?.role != UserRole.doctor) return [];
    return appointments
        .where((a) => a.doctorId == _currentUser!.id)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<Appointment> get doctorTodayAppointments {
    final today = DateTime.now();
    return doctorAppointments.where((a) {
      return a.scheduledAt.year == today.year &&
          a.scheduledAt.month == today.month &&
          a.scheduledAt.day == today.day &&
          a.status == AppointmentStatus.confirmed;
    }).toList();
  }

  Appointment? get nextPatientAppointment {
    final upcoming = patientAppointments
        .where((a) =>
            a.status == AppointmentStatus.confirmed &&
            a.scheduledAt.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<TimeSlot> slotsForDoctor(String doctorId) {
    return slots.where((s) => s.doctorId == doctorId).toList();
  }

  Doctor? doctorById(String id) {
    try {
      return doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Appointment? appointmentById(String id) {
    try {
      return appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Conversation? conversationById(String id) {
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void bookAppointment({
    required String doctorId,
    required TimeSlot slot,
    required AppointmentType type,
    String? reason,
  }) {
    final doctor = doctorById(doctorId);
    if (doctor == null || _currentUser?.role != UserRole.patient) return;

    final parts = slot.startTime.split(':');
    final scheduledAt = DateTime(
      slot.date.year,
      slot.date.month,
      slot.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final appt = Appointment(
      id: 'appt-${DateTime.now().millisecondsSinceEpoch}',
      patientId: _currentUser!.id,
      patientName: _currentUser!.name,
      doctorId: doctorId,
      doctorName: doctor.name,
      doctorSpecialty: doctor.specialty,
      scheduledAt: scheduledAt,
      type: type,
      status: AppointmentStatus.confirmed,
      reason: reason,
    );

    appointments.add(appt);
    slot.isAvailable = false;

    notifications.insert(
      0,
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Confirmed',
        body: 'Your appointment with ${doctor.name} is confirmed.',
        type: 'booking_confirmed',
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void cancelAppointment(String appointmentId) {
    final appt = appointmentById(appointmentId);
    if (appt == null) return;
    appt.status = AppointmentStatus.cancelled;

    for (final slot in slots) {
      if (slot.doctorId == appt.doctorId) {
        final parts = slot.startTime.split(':');
        final slotTime = DateTime(
          slot.date.year,
          slot.date.month,
          slot.date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        if (slotTime == appt.scheduledAt) {
          slot.isAvailable = true;
          break;
        }
      }
    }
    notifyListeners();
  }

  void sendMessage(String conversationId, String body) {
    if (_currentUser == null) return;
    final conv = conversationById(conversationId);
    if (conv == null) return;

    final msg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser!.id,
      body: body,
      sentAt: DateTime.now(),
      isRead: true,
    );

    conv.messages.add(msg);
    conv.lastMessage = body;
    conv.lastMessageAt = DateTime.now();
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final notif = notifications.cast<AppNotification?>().firstWhere(
          (n) => n!.id == id,
          orElse: () => null,
        );
    if (notif != null) {
      notif.isRead = true;
      notifyListeners();
    }
  }

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  Map<String, dynamic> get adminStats => {
        'totalAppointments': appointments.length,
        'completedAppointments':
            appointments.where((a) => a.status == AppointmentStatus.completed).length,
        'activeDoctors': doctors.where((d) => d.isVerified).length,
        'pendingDoctors': doctors.where((d) => !d.isVerified).length,
        'totalPatients': 2,
        'avgRating': 4.8,
      };
}
