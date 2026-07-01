import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<AppStore>().adminStats;

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final apptTotal = stats['appointments']?['total'] ?? 0;
    final completed = stats['appointments']?['by_status']?['completed'] ?? 0;
    final verified = stats['doctors']?['verified'] ?? 0;
    final pending = stats['doctors']?['pending_verification'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatCard('Total Appointments', '$apptTotal', Icons.event, AppColors.primary),
              _StatCard('Completed', '$completed', Icons.check_circle, AppColors.success),
              _StatCard('Active Doctors', '$verified', Icons.medical_services, AppColors.primary),
              _StatCard('Pending Approval', '$pending', Icons.pending, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchAdminDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final doctors = store.adminDoctors;

    if (doctors.isEmpty && store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (context, i) {
        final doc = doctors[i];
        return AppCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(doc.name[0], style: const TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${doc.specialty} · ${doc.yearsExperience} yrs'),
                  ],
                ),
              ),
              if (doc.isVerified)
                const Chip(
                  label: Text('Verified', style: TextStyle(fontSize: 11)),
                  backgroundColor: Color(0xFFE8F5E9),
                  side: BorderSide.none,
                )
              else
                TextButton(
                  onPressed: () async {
                    await store.verifyDoctor(doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${doc.name} approved')),
                      );
                    }
                  },
                  child: const Text('Approve'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports & Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appointments This Week', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _Bar(label: 'Mon', value: 0.6),
                _Bar(label: 'Tue', value: 0.8),
                _Bar(label: 'Wed', value: 0.5),
                _Bar(label: 'Thu', value: 0.9),
                _Bar(label: 'Fri', value: 0.7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
