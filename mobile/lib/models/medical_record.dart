class Prescription {
  const Prescription({
    required this.medicineName,
    required this.dosage,
    required this.duration,
    this.instructions,
  });

  final String medicineName;
  final String dosage;
  final String duration;
  final String? instructions;
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.visitDate,
    required this.diagnosis,
    required this.notes,
    required this.recommendations,
    required this.prescriptions,
  });

  final String id;
  final String appointmentId;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime visitDate;
  final String diagnosis;
  final String notes;
  final String recommendations;
  final List<Prescription> prescriptions;
}
