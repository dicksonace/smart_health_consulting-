import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_parsers.dart';
import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/medical_record.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';
import '../services/realtime_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({ApiClient? api}) : _api = api ?? ApiClient() {
    _api.onUnauthorized = _onSessionExpired;
  }

  final ApiClient _api;

  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  List<Doctor> doctors = [];
  List<Appointment> appointments = [];
  List<TimeSlot> _doctorSlots = [];
  List<Conversation> conversations = [];
  List<AppNotification> notifications = [];
  List<MedicalRecord> medicalRecords = [];
  Map<String, dynamic>? adminStats;
  List<Doctor> adminDoctors = [];

  final Map<String, List<ChatMessage>> _messageCache = {};
  final Map<String, Doctor> _doctorCache = {};
  final Map<String, List<TimeSlot>> _slotCache = {};

  RealtimeService? _realtime;
  RealtimeService get realtime => _realtime ??= RealtimeService(_api);

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> init() async {
    if (_isInitialized) return;
    if (await _api.hasToken()) {
      try {
        final data = await _api.get('/user');
        _currentUser = ApiParsers.userFromJson(data);
        await refreshAll();
      } catch (_) {
        await _api.clearToken();
        _currentUser = null;
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _api.post('/login', body: {
        'email': email,
        'password': password,
      });
      await _api.saveToken(data['token'] as String);
      _currentUser = ApiParsers.userFromJson(data['user'] as Map<String, dynamic>);
      await refreshAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> quickLogin(UserRole role) async {
    final key = switch (role) {
      UserRole.patient => 'patient',
      UserRole.doctor => 'doctor',
      UserRole.admin => 'admin',
    };
    await login(ApiConfig.demoEmails[key]!, ApiConfig.demoPassword);
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {}
    await _api.clearToken();
    _clearState();
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_currentUser == null) return;
    await Future.wait([
      fetchAppointments(),
      fetchNotifications(),
      if (_currentUser!.role == UserRole.patient) ...[
        fetchDoctors(),
        fetchConversations(),
        fetchRecords(),
      ],
      if (_currentUser!.role == UserRole.doctor) fetchConversations(),
      if (_currentUser!.role == UserRole.admin) ...[
        fetchAdminStats(),
        fetchAdminDoctors(),
      ],
    ]);
  }

  Future<void> fetchDoctors({String? specialty}) async {
    try {
      final list = await _api.getList('/doctors', query: {
        if (specialty != null) 'specialty': specialty,
      });
      doctors = list.map(ApiParsers.doctorFromJson).toList();
      for (final d in doctors) {
        _doctorCache[d.id] = d;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Doctor?> fetchDoctor(String doctorId) async {
    if (_doctorCache.containsKey(doctorId)) {
      return _doctorCache[doctorId];
    }
    try {
      final data = await _api.get('/doctors/$doctorId');
      final doctor = ApiParsers.doctorFromJson(data);
      _doctorCache[doctorId] = doctor;

      final availability = data['availability'] as List? ?? [];
      _slotCache[doctorId] = availability
          .cast<Map<String, dynamic>>()
          .map(ApiParsers.slotFromJson)
          .toList();

      notifyListeners();
      return doctor;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  List<TimeSlot> slotsForDoctor(String doctorId) {
    return _slotCache[doctorId] ?? [];
  }

  Doctor? doctorById(String id) {
    if (_doctorCache.containsKey(id)) return _doctorCache[id];
    try {
      return doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final list = await _api.getList('/appointments');
      appointments = list.map(ApiParsers.appointmentFromJson).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Appointment> get patientAppointments {
    if (_currentUser?.role != UserRole.patient) return [];
    return appointments.toList()..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  List<Appointment> get doctorAppointments {
    if (_currentUser?.role != UserRole.doctor) return [];
    return appointments.toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
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

  Appointment? appointmentById(String id) {
    try {
      return appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> bookAppointment({
    required String doctorId,
    required TimeSlot slot,
    required AppointmentType type,
    String? reason,
  }) async {
    _setLoading(true);
    try {
      await _api.post('/appointments', body: {
        'doctor_id': int.parse(doctorId),
        'availability_id': int.parse(slot.id),
        'type': ApiParsers.typeToApi(type),
        if (reason != null) 'reason': reason,
      });
      await fetchAppointments();
      await fetchDoctor(doctorId);
      await fetchNotifications();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _api.delete('/appointments/$appointmentId');
    await fetchAppointments();
  }

  Future<void> fetchConversations() async {
    try {
      final list = await _api.getList('/conversations');
      conversations = list.map((json) {
        final conv = ApiParsers.conversationFromJson(json);
        final cached = _messageCache[conv.id];
        if (cached != null && cached.isNotEmpty) {
          conv.messages.addAll(cached);
        }
        return conv;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<ChatMessage>> fetchMessages(String partnerId) async {
    try {
      final list = await _api.getList('/messages/$partnerId');
      final messages = list.map(ApiParsers.messageFromJson).toList();
      _messageCache[partnerId] = messages;

      final convIndex = conversations.indexWhere((c) => c.id == partnerId);
      if (convIndex >= 0) {
        conversations[convIndex].messages.clear();
        conversations[convIndex].messages.addAll(messages);
        conversations[convIndex].unreadCount = 0;
      }
      notifyListeners();
      return messages;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _messageCache[partnerId] ?? [];
    }
  }

  Conversation? conversationById(String id) {
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage(
    String partnerId,
    String body, {
    String? attachmentPath,
  }) async {
    final trimmedBody = body.trim();
    final preview = trimmedBody.isNotEmpty
        ? trimmedBody
        : attachmentPath != null
            ? '📷 Sent an image'
            : '';

    final convIndex = conversations.indexWhere((c) => c.id == partnerId);
    if (convIndex >= 0 && preview.isNotEmpty) {
      conversations[convIndex].lastMessage = preview;
      conversations[convIndex].lastMessageAt = DateTime.now();
      notifyListeners();
    }

    await _api.post('/messages', body: {
      'receiver_id': int.parse(partnerId),
      if (trimmedBody.isNotEmpty) 'body': trimmedBody,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
    });
    await fetchMessages(partnerId);
    await fetchConversations();
  }

  Future<Map<String, dynamic>> uploadMessageAttachment(String filePath) async {
    return _api.uploadFile('/message-attachments', filePath: filePath);
  }

  Future<void> fetchRecords() async {
    try {
      final list = await _api.getList('/patient/records');
      medicalRecords = list.map(ApiParsers.recordFromJson).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  MedicalRecord? recordById(String id) {
    try {
      return medicalRecords.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final list = await _api.getList('/notifications');
      notifications = list.map(ApiParsers.notificationFromJson).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/notifications/$id/read');
    await fetchNotifications();
  }

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  Future<Map<String, dynamic>> symptomCheck(List<String> symptoms) async {
    return _api.post('/symptom-check', body: {'symptoms': symptoms});
  }

  Future<Map<String, dynamic>> fetchVideoRoom(String appointmentId) async {
    return _api.get('/appointments/$appointmentId/video-room');
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await _api.post('/device-token', body: {'fcm_token': fcmToken});
    } catch (_) {}
  }

  void startRealtimePolling({
    required void Function(List<Map<String, dynamic>> events) onEvents,
    int? doctorId,
  }) {
    realtime.startPolling(onEvents: onEvents, doctorId: doctorId);
  }

  void stopRealtimePolling() {
    realtime.stopPolling();
  }

  Future<void> submitConsultation({
    required String appointmentId,
    required String diagnosis,
    required String notes,
    String? recommendations,
    List<Map<String, String>>? prescriptions,
  }) async {
    await _api.post('/consultations', body: {
      'appointment_id': int.parse(appointmentId),
      'diagnosis': diagnosis,
      'notes': notes,
      if (recommendations != null) 'recommendations': recommendations,
      if (prescriptions != null) 'prescriptions': prescriptions,
    });
    await fetchAppointments();
  }

  Future<void> submitFeedback({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    await _api.post('/feedback', body: {
      'appointment_id': int.parse(appointmentId),
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    await fetchAppointments();
    notifyListeners();
  }

  Future<void> fetchAdminStats() async {
    adminStats = await _api.get('/admin/stats');
    notifyListeners();
  }

  Future<void> fetchAdminDoctors() async {
    final list = await _api.getList('/admin/doctors');
    adminDoctors = list.map(ApiParsers.doctorFromJson).toList();
    notifyListeners();
  }

  Future<void> verifyDoctor(String doctorId) async {
    await _api.patch('/admin/doctors/$doctorId/verify');
    await fetchAdminDoctors();
    await fetchAdminStats();
  }

  Future<void> fetchDoctorAvailability() async {
    try {
      final list = await _api.getList('/doctor/availability');
      _doctorSlots = list.map(ApiParsers.slotFromJson).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<TimeSlot> get doctorAvailability => _doctorSlots;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _onSessionExpired() async {
    _clearState();
    _error = 'Your session expired. Please log in again.';
    notifyListeners();
  }

  void _clearState() {
    _currentUser = null;
    doctors = [];
    appointments = [];
    conversations = [];
    notifications = [];
    medicalRecords = [];
    adminStats = null;
    adminDoctors = [];
    _doctorSlots = [];
    _messageCache.clear();
    _doctorCache.clear();
    _slotCache.clear();
    stopRealtimePolling();
    _error = null;
  }
}
