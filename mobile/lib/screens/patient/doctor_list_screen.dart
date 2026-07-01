import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  String? _specialtyFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final doctors = store.doctors;
    final specialties = doctors.map((d) => d.specialty).toSet().toList()..sort();
    final filtered = _specialtyFilter == null
        ? doctors
        : doctors.where((d) => d.specialty == _specialtyFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: store.isLoading && doctors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _specialtyFilter == null,
                          onSelected: (_) => setState(() => _specialtyFilter = null),
                        ),
                      ),
                      for (final s in specialties)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s),
                            selected: _specialtyFilter == s,
                            onSelected: (_) => setState(() => _specialtyFilter = s),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => store.fetchDoctors(),
                    child: filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(icon: Icons.search_off, message: 'No doctors found'),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final doc = filtered[i];
                              return AppCard(
                                onTap: () => context.push('/patient/doctors/${doc.id}'),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        doc.name.split(' ').last[0],
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              if (doc.isVerified)
                                                const Icon(Icons.verified, color: AppColors.primary, size: 18),
                                            ],
                                          ),
                                          Text(doc.specialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              Text(' ${doc.rating}'),
                                              const Spacer(),
                                              Text('GHS ${doc.consultationFee.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchDoctor(widget.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final doctor = store.doctorById(widget.doctorId);

    if (doctor == null && store.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor')),
        body: const EmptyState(icon: Icons.error_outline, message: 'Doctor not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      doctor.name.split(' ').last[0],
                      style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(doctor.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(doctor.specialty, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(' ${doctor.rating} · ${doctor.reviewCount} reviews'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${doctor.yearsExperience} years experience · ${doctor.qualifications}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(doctor.bio.isEmpty ? 'No bio available.' : doctor.bio),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Consultation Fee', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'GHS ${doctor.consultationFee.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          label: 'Book Appointment',
          icon: Icons.calendar_month,
          onPressed: () => context.push('/patient/book/${widget.doctorId}'),
        ),
      ),
    );
  }
}
