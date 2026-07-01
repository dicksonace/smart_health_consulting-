import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final user = store.currentUser!;
    final nextAppt = store.nextPatientAppointment;
    final unread = store.unreadNotificationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Health'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/patient/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.name.split(' ').first}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('How can we help you today?', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            if (nextAppt != null)
              AppCard(
                onTap: () => context.push('/patient/appointments/${nextAppt.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.event, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Upcoming Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(nextAppt.doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(nextAppt.doctorSpecialty, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('EEE, MMM d · h:mm a').format(nextAppt.scheduledAt),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(nextAppt.typeLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              AppCard(
                child: const Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Expanded(child: Text('No upcoming appointments')),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick Actions'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                QuickActionTile(
                  icon: Icons.healing,
                  label: 'Symptom Checker',
                  color: AppColors.urgent,
                  onTap: () => context.push('/patient/symptom-check'),
                ),
                QuickActionTile(
                  icon: Icons.calendar_month,
                  label: 'Book Appointment',
                  color: AppColors.primary,
                  onTap: () => context.push('/patient/doctors'),
                ),
                QuickActionTile(
                  icon: Icons.chat,
                  label: 'Message Doctor',
                  color: AppColors.success,
                  onTap: () => context.go('/patient/messages'),
                ),
                QuickActionTile(
                  icon: Icons.folder_open,
                  label: 'Medical Records',
                  color: AppColors.warning,
                  onTap: () => context.push('/patient/records'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
