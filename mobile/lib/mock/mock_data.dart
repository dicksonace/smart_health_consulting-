import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/medical_record.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/user_role.dart';

class MockData {
  static final demoPatient = AppUser(
    id: 'patient-1',
    name: 'Ama Mensah',
    email: 'ama.mensah@email.com',
    phone: '+233 24 123 4567',
    role: UserRole.patient,
    dateOfBirth: '1995-03-15',
    bloodGroup: 'O+',
    allergies: 'Penicillin',
  );

  static final demoDoctor = AppUser(
    id: 'doctor-1',
    name: 'Dr. Kwame Osei',
    email: 'kwame.osei@health.com',
    phone: '+233 20 987 6543',
    role: UserRole.doctor,
    specialty: 'General Practice',
    qualifications: 'MBChB, MPH',
    consultationFee: 150,
  );

  static final demoAdmin = AppUser(
    id: 'admin-1',
    name: 'Grace Adom',
    email: 'admin@smarthealth.com',
    phone: '+233 30 111 2222',
    role: UserRole.admin,
  );

  static final doctors = [
    const Doctor(
      id: 'doctor-1',
      name: 'Dr. Kwame Osei',
      specialty: 'General Practice',
      qualifications: 'MBChB, MPH',
      yearsExperience: 12,
      consultationFee: 150,
      rating: 4.8,
      reviewCount: 124,
      bio: 'Experienced general practitioner focused on preventive care and chronic disease management.',
      isVerified: true,
    ),
    const Doctor(
      id: 'doctor-2',
      name: 'Dr. Abena Darko',
      specialty: 'Dermatology',
      qualifications: 'MBChB, MD Dermatology',
      yearsExperience: 8,
      consultationFee: 200,
      rating: 4.9,
      reviewCount: 89,
      bio: 'Specialist in skin conditions, acne treatment, and cosmetic dermatology.',
      isVerified: true,
    ),
    const Doctor(
      id: 'doctor-3',
      name: 'Dr. Emmanuel Boateng',
      specialty: 'Cardiology',
      qualifications: 'MBChB, FACC',
      yearsExperience: 15,
      consultationFee: 300,
      rating: 4.7,
      reviewCount: 156,
      bio: 'Heart specialist with expertise in hypertension and cardiovascular disease.',
      isVerified: true,
    ),
    const Doctor(
      id: 'doctor-4',
      name: 'Dr. Efua Ansah',
      specialty: 'Pediatrics',
      qualifications: 'MBChB, DCH',
      yearsExperience: 10,
      consultationFee: 180,
      rating: 4.9,
      reviewCount: 203,
      bio: 'Dedicated to children\'s health from infancy through adolescence.',
      isVerified: true,
    ),
    const Doctor(
      id: 'doctor-5',
      name: 'Dr. Kofi Asante',
      specialty: 'Orthopedics',
      qualifications: 'MBChB, MS Ortho',
      yearsExperience: 14,
      consultationFee: 250,
      rating: 4.6,
      reviewCount: 67,
      bio: 'Bone and joint specialist treating sports injuries and arthritis.',
      isVerified: false,
    ),
  ];

  static List<Appointment> initialAppointments() {
    final now = DateTime.now();
    return [
      Appointment(
        id: 'appt-1',
        patientId: 'patient-1',
        patientName: 'Ama Mensah',
        doctorId: 'doctor-1',
        doctorName: 'Dr. Kwame Osei',
        doctorSpecialty: 'General Practice',
        scheduledAt: now.add(const Duration(days: 1, hours: 10)),
        type: AppointmentType.video,
        status: AppointmentStatus.confirmed,
        reason: 'Follow-up on blood pressure',
        urgency: UrgencyLevel.low,
      ),
      Appointment(
        id: 'appt-2',
        patientId: 'patient-1',
        patientName: 'Ama Mensah',
        doctorId: 'doctor-2',
        doctorName: 'Dr. Abena Darko',
        doctorSpecialty: 'Dermatology',
        scheduledAt: now.subtract(const Duration(days: 14)),
        type: AppointmentType.inPerson,
        status: AppointmentStatus.completed,
        reason: 'Skin rash evaluation',
        urgency: UrgencyLevel.medium,
      ),
      Appointment(
        id: 'appt-3',
        patientId: 'patient-2',
        patientName: 'John Doe',
        doctorId: 'doctor-1',
        doctorName: 'Dr. Kwame Osei',
        doctorSpecialty: 'General Practice',
        scheduledAt: now.add(const Duration(hours: 3)),
        type: AppointmentType.chat,
        status: AppointmentStatus.confirmed,
        reason: 'General consultation',
        urgency: UrgencyLevel.low,
      ),
    ];
  }

  static List<TimeSlot> initialSlots() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return [
      for (final doctorId in ['doctor-1', 'doctor-2', 'doctor-3'])
        ...[
          TimeSlot(
            id: 'slot-$doctorId-1',
            doctorId: doctorId,
            date: tomorrow,
            startTime: '09:00',
            endTime: '09:30',
            isAvailable: true,
          ),
          TimeSlot(
            id: 'slot-$doctorId-2',
            doctorId: doctorId,
            date: tomorrow,
            startTime: '10:00',
            endTime: '10:30',
            isAvailable: doctorId != 'doctor-2',
          ),
          TimeSlot(
            id: 'slot-$doctorId-3',
            doctorId: doctorId,
            date: tomorrow,
            startTime: '11:00',
            endTime: '11:30',
            isAvailable: true,
          ),
          TimeSlot(
            id: 'slot-$doctorId-4',
            doctorId: doctorId,
            date: tomorrow,
            startTime: '14:00',
            endTime: '14:30',
            isAvailable: false,
          ),
        ],
    ];
  }

  static List<Conversation> initialConversations() {
    final now = DateTime.now();
    return [
      Conversation(
        id: 'conv-1',
        participantId: 'doctor-1',
        participantName: 'Dr. Kwame Osei',
        participantRole: 'Doctor',
        lastMessage: 'Please take the medication after meals.',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        unreadCount: 1,
        messages: [
          ChatMessage(
            id: 'msg-1',
            senderId: 'patient-1',
            body: 'Good morning Doctor, I wanted to ask about my prescription.',
            sentAt: now.subtract(const Duration(hours: 3)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg-2',
            senderId: 'doctor-1',
            body: 'Good morning Ama. What would you like to know?',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 45)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg-3',
            senderId: 'patient-1',
            body: 'Should I take it before or after food?',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 30)),
            isRead: true,
          ),
          ChatMessage(
            id: 'msg-4',
            senderId: 'doctor-1',
            body: 'Please take the medication after meals.',
            sentAt: now.subtract(const Duration(hours: 2)),
            isRead: false,
          ),
        ],
      ),
      Conversation(
        id: 'conv-2',
        participantId: 'doctor-2',
        participantName: 'Dr. Abena Darko',
        participantRole: 'Doctor',
        lastMessage: 'Your test results look good.',
        lastMessageAt: now.subtract(const Duration(days: 2)),
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'msg-5',
            senderId: 'doctor-2',
            body: 'Your test results look good.',
            sentAt: now.subtract(const Duration(days: 2)),
            isRead: true,
          ),
        ],
      ),
    ];
  }

  static final medicalRecords = [
    MedicalRecord(
      id: 'rec-1',
      appointmentId: 'appt-2',
      doctorName: 'Dr. Abena Darko',
      doctorSpecialty: 'Dermatology',
      visitDate: DateTime.now().subtract(const Duration(days: 14)),
      diagnosis: 'Contact dermatitis',
      notes: 'Mild allergic reaction on forearms. Likely caused by new soap.',
      recommendations: 'Avoid irritants. Use prescribed cream twice daily.',
      prescriptions: const [
        Prescription(
          medicineName: 'Hydrocortisone Cream 1%',
          dosage: 'Apply thin layer',
          duration: '7 days',
          instructions: 'Apply twice daily to affected area',
        ),
      ],
    ),
    MedicalRecord(
      id: 'rec-2',
      appointmentId: 'appt-old-1',
      doctorName: 'Dr. Kwame Osei',
      doctorSpecialty: 'General Practice',
      visitDate: DateTime.now().subtract(const Duration(days: 60)),
      diagnosis: 'Hypertension (Stage 1)',
      notes: 'BP reading 145/92. Patient reports occasional headaches.',
      recommendations: 'Reduce salt intake. Monitor BP weekly. Follow up in 4 weeks.',
      prescriptions: const [
        Prescription(
          medicineName: 'Amlodipine 5mg',
          dosage: '1 tablet',
          duration: '30 days',
          instructions: 'Take once daily in the morning',
        ),
      ],
    ),
    MedicalRecord(
      id: 'rec-3',
      appointmentId: 'appt-old-2',
      doctorName: 'Dr. Kwame Osei',
      doctorSpecialty: 'General Practice',
      visitDate: DateTime.now().subtract(const Duration(days: 90)),
      diagnosis: 'Upper respiratory infection',
      notes: 'Mild cough and sore throat for 3 days. No fever.',
      recommendations: 'Rest and hydration. Return if symptoms worsen.',
      prescriptions: const [
        Prescription(
          medicineName: 'Paracetamol 500mg',
          dosage: '2 tablets',
          duration: '5 days',
          instructions: 'Take every 6 hours as needed',
        ),
      ],
    ),
  ];

  static List<AppNotification> initialNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif-1',
        title: 'Appointment Reminder',
        body: 'Your video call with Dr. Kwame Osei is tomorrow at 10:00 AM.',
        type: 'appointment_reminder',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'notif-2',
        title: 'New Message',
        body: 'Dr. Kwame Osei sent you a message.',
        type: 'new_message',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'notif-3',
        title: 'Booking Confirmed',
        body: 'Your appointment with Dr. Abena Darko was confirmed.',
        type: 'booking_confirmed',
        createdAt: now.subtract(const Duration(days: 14)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-4',
        title: 'Prescription Ready',
        body: 'Your prescription from Dr. Abena Darko is available.',
        type: 'prescription',
        createdAt: now.subtract(const Duration(days: 14)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-5',
        title: 'Feedback Request',
        body: 'How was your visit with Dr. Abena Darko? Rate your experience.',
        type: 'feedback',
        createdAt: now.subtract(const Duration(days: 13)),
        isRead: true,
      ),
    ];
  }

  static SymptomResult analyzeSymptoms(List<String> symptoms) {
    final combined = symptoms.join(' ').toLowerCase();
    if (combined.contains('chest') || combined.contains('breath')) {
      return const SymptomResult(
        suggestedSpecialty: 'Cardiology',
        urgency: 'Emergency',
        summary: 'Your symptoms may indicate a cardiovascular concern.',
        advice: 'Seek emergency care immediately. Do not wait for a regular appointment.',
      );
    }
    if (combined.contains('skin') || combined.contains('rash') || combined.contains('itch')) {
      return const SymptomResult(
        suggestedSpecialty: 'Dermatology',
        urgency: 'Medium',
        summary: 'Your symptoms suggest a skin-related condition.',
        advice: 'Consider booking with a dermatologist within the next few days.',
      );
    }
    if (combined.contains('child') || combined.contains('baby') || combined.contains('fever')) {
      return const SymptomResult(
        suggestedSpecialty: 'Pediatrics',
        urgency: 'High',
        summary: 'Pediatric evaluation may be needed.',
        advice: 'Book a pediatric consultation as soon as possible.',
      );
    }
    return const SymptomResult(
      suggestedSpecialty: 'General Practice',
      urgency: 'Low',
      summary: 'Your symptoms can be evaluated by a general practitioner.',
      advice: 'Book a general consultation for a full assessment.',
    );
  }
}
