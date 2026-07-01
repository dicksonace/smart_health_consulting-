class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualifications,
    required this.yearsExperience,
    required this.consultationFee,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.isVerified,
  });

  final String id;
  final String name;
  final String specialty;
  final String qualifications;
  final int yearsExperience;
  final double consultationFee;
  final double rating;
  final int reviewCount;
  final String bio;
  final bool isVerified;
}
