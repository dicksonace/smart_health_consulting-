import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.specialty,
    this.qualifications,
    this.consultationFee,
    this.dateOfBirth,
    this.bloodGroup,
    this.allergies,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? specialty;
  final String? qualifications;
  final double? consultationFee;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? allergies;
}
