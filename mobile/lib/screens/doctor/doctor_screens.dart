import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

import '../patient/patient_messages_records_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final todayAppts = store.doctorTodayAppointments;
    final allAppts = store.doctorAppointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/doctor/availability'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${store.currentUser!.name.split(' ').first}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '${todayAppts.length} appointment(s) today',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Today'),
            if (todayAppts.isEmpty)
              const AppCard(
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('No appointments scheduled for today'),
                  ],
                ),
              )
            else
              ...todayAppts.map((appt) => _AppointmentTile(appt: appt)),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming'),
            ...allAppts
                .where((a) => !todayAppts.contains(a))
                .take(5)
                .map((appt) => _AppointmentTile(appt: appt)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appt});

  final Appointment appt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/doctor/appointments/${appt.id}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('h:mm').format(appt.scheduledAt),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  DateFormat('a').format(appt.scheduledAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(appt.reason ?? 'General consultation', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(appt.typeLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class DoctorAppointmentDetailScreen extends StatelessWidget {
  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final appt = context.watch<AppStore>().appointmentById(appointmentId);

    if (appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const EmptyState(icon: Icons.error_outline, message: 'Not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(DateFormat('EEEE, MMM d · h:mm a').format(appt.scheduledAt)),
                  Text('Type: ${appt.typeLabel}'),
                  if (appt.reason != null) ...[
                    const SizedBox(height: 8),
                    Text('Reason: ${appt.reason}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'View Patient History',
              onPressed: () => context.push('/doctor/patients/${appt.patientId}'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Start Consultation',
              icon: Icons.medical_services,
              onPressed: () => context.push('/doctor/consult/$appointmentId'),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchDoctorAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final slots = store.doctorAvailability;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Availability')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your availability slots:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (slots.isEmpty && store.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (slots.isEmpty)
            const EmptyState(icon: Icons.event_busy, message: 'No slots configured')
          else
          ...slots.map((slot) => AppCard(
                child: Row(
                  children: [
                    Icon(
                      slot.isAvailable ? Icons.check_circle : Icons.cancel,
                      color: slot.isAvailable ? AppColors.success : AppColors.unavailable,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${slot.startTime} - ${slot.endTime}'),
                    ),
                    Text(
                      slot.isAvailable ? 'Available' : 'Booked',
                      style: TextStyle(
                        color: slot.isAvailable ? AppColors.success : AppColors.unavailable,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Add Time Slot (mock)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Slot added (mock)')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ConsultationRoomScreen extends StatefulWidget {
  const ConsultationRoomScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<ConsultationRoomScreen> {
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicineController = TextEditingController(text: 'Amlodipine 5mg');
  final _dosageController = TextEditingController(text: '1 tablet daily');

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appt = context.watch<AppStore>().appointmentById(widget.appointmentId);

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (appt != null)
              AppCard(
                child: Text('Patient: ${appt.patientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _diagnosisController,
              decoration: const InputDecoration(labelText: 'Diagnosis'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Clinical Notes'),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Prescription'),
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(labelText: 'Medicine'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage Instructions'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save & Complete Consultation',
              onPressed: appt == null
                  ? null
                  : () async {
                      await context.read<AppStore>().submitConsultation(
                            appointmentId: widget.appointmentId,
                            diagnosis: _diagnosisController.text,
                            notes: _notesController.text,
                            prescriptions: [
                              {
                                'medicine_name': _medicineController.text,
                                'dosage': _dosageController.text,
                                'duration': '30 days',
                              },
                            ],
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Consultation saved')),
                        );
                        context.go('/doctor/home');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorMessagesScreen extends StatelessWidget {
  const DoctorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatientMessagesScreen();
  }
}

class DoctorChatThreadScreen extends StatelessWidget {
  const DoctorChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return ChatThreadScreen(conversationId: conversationId);
  }
}

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final patientIds = store.doctorAppointments.map((a) => a.patientId).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: patientIds.map((id) {
          final appt = store.doctorAppointments.firstWhere((a) => a.patientId == id);
          return AppCard(
            onTap: () => context.push('/doctor/patients/$id'),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(appt.patientName[0], style: const TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Last visit: ${DateFormat('MMM d').format(appt.scheduledAt)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final appts = context.watch<AppStore>().doctorAppointments
        .where((a) => a.patientId == patientId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Patient History')),
      body: appts.isEmpty
          ? const EmptyState(icon: Icons.folder_open, message: 'No visit history for this patient')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appts.length,
              itemBuilder: (context, i) {
                final appt = appts[i];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.reason ?? 'Consultation', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('MMM d, y').format(appt.scheduledAt)),
                      const SizedBox(height: 8),
                      Text('Status: ${appt.statusLabel}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class DoctorAccountScreen extends StatelessWidget {
  const DoctorAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final user = store.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(user.name[0], style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user.specialty ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  _Row(Icons.email, user.email),
                  const Divider(),
                  _Row(Icons.phone, user.phone),
                  const Divider(),
                  _Row(Icons.school, user.qualifications ?? '-'),
                  const Divider(),
                  _Row(Icons.payments, 'GHS ${user.consultationFee?.toStringAsFixed(0) ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: const Text('Manage Availability'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/doctor/availability'),
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Log Out',
              onPressed: () async {
                await store.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
