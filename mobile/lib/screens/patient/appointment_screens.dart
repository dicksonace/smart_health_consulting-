import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../models/appointment.dart';
import '../../models/notification_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  TimeSlot? _selectedSlot;
  AppointmentType _type = AppointmentType.video;

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
    final slots = store.slotsForDoctor(widget.doctorId);

    if (doctor == null || slots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: EmptyState(
          icon: Icons.event_busy,
          message: doctor == null ? 'Doctor not found' : 'No available slots',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(doctor.specialty, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Consultation Type'),
            SegmentedButton<AppointmentType>(
              segments: const [
                ButtonSegment(value: AppointmentType.video, label: Text('Video'), icon: Icon(Icons.videocam)),
                ButtonSegment(value: AppointmentType.inPerson, label: Text('In Person'), icon: Icon(Icons.person)),
                ButtonSegment(value: AppointmentType.chat, label: Text('Chat'), icon: Icon(Icons.chat)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Available Slots — ${DateFormat('EEE, MMM d').format(slots.first.date)}',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final available = slot.isAvailable;
                final selected = _selectedSlot?.id == slot.id;
                return ChoiceChip(
                  label: Text('${slot.startTime} - ${slot.endTime}'),
                  selected: selected,
                  onSelected: available
                      ? (v) => setState(() => _selectedSlot = v ? slot : null)
                      : null,
                  selectedColor: AppColors.success.withValues(alpha: 0.2),
                  backgroundColor: available ? null : AppColors.unavailable.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: available ? (selected ? AppColors.success : AppColors.textPrimary) : AppColors.unavailable,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Available', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.unavailable, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Unavailable', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          label: 'Continue',
          onPressed: _selectedSlot == null
              ? null
              : () => context.push(
                    '/patient/book/confirm',
                    extra: {'doctorId': widget.doctorId, 'slot': _selectedSlot!, 'type': _type},
                  ),
        ),
      ),
    );
  }
}

class BookingConfirmScreen extends StatelessWidget {
  const BookingConfirmScreen({
    super.key,
    required this.doctorId,
    required this.slot,
    required this.type,
  });

  final String doctorId;
  final TimeSlot slot;
  final AppointmentType type;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final doctor = store.doctorById(doctorId)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Appointment Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              _Row('Doctor', doctor.name),
              _Row('Specialty', doctor.specialty),
              _Row('Date', DateFormat('EEEE, MMMM d, y').format(slot.date)),
              _Row('Time', '${slot.startTime} - ${slot.endTime}'),
              _Row('Type', type == AppointmentType.video ? 'Video Call' : type == AppointmentType.inPerson ? 'In Person' : 'Chat'),
              _Row('Fee', 'GHS ${doctor.consultationFee.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          label: 'Confirm Booking',
          onPressed: () async {
            await store.bookAppointment(doctorId: doctorId, slot: slot, type: type);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment booked successfully!')),
              );
              context.go('/patient/appointments');
            }
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppStore>().patientAppointments;

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: appointments.isEmpty
          ? const EmptyState(icon: Icons.event_busy, message: 'No appointments yet')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, i) {
                final appt = appointments[i];
                return AppCard(
                  onTap: () => context.push('/patient/appointments/${appt.id}'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusColor(appt.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event, color: _statusColor(appt.status)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appt.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(appt.doctorSpecialty, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y · h:mm a').format(appt.scheduledAt),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(appt.statusLabel, style: TextStyle(color: _statusColor(appt.status), fontWeight: FontWeight.w600, fontSize: 12)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/doctors'),
        icon: const Icon(Icons.add),
        label: const Text('Book New'),
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.unavailable;
    }
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final appt = store.appointmentById(appointmentId);

    if (appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const EmptyState(icon: Icons.error_outline, message: 'Appointment not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.doctorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(appt.doctorSpecialty, style: const TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 24),
                  _DetailRow(Icons.calendar_today, DateFormat('EEEE, MMM d, y').format(appt.scheduledAt)),
                  _DetailRow(Icons.access_time, DateFormat('h:mm a').format(appt.scheduledAt)),
                  _DetailRow(Icons.videocam, appt.typeLabel),
                  _DetailRow(Icons.info_outline, appt.statusLabel),
                  if (appt.reason != null) _DetailRow(Icons.notes, appt.reason!),
                ],
              ),
            ),
            if (appt.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: 16),
              if (appt.type == AppointmentType.video)
                PrimaryButton(
                  label: 'Join Video Call',
                  icon: Icons.videocam,
                  onPressed: () => context.push('/patient/call/$appointmentId'),
                ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Cancel Appointment',
                onPressed: () async {
                  await store.cancelAppointment(appointmentId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment cancelled')),
                    );
                    context.pop();
                  }
                },
              ),
            ],
            if (appt.status == AppointmentStatus.completed) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Leave Feedback',
                onPressed: () => context.push('/patient/feedback/$appointmentId'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final appt = context.watch<AppStore>().appointmentById(appointmentId);

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(appt?.doctorName ?? 'Video Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              appt?.doctorName ?? 'Doctor',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Video call placeholder', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallButton(icon: Icons.mic, label: 'Mute', onTap: () {}),
                const SizedBox(width: 24),
                _CallButton(
                  icon: Icons.call_end,
                  label: 'End',
                  color: AppColors.urgent,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 24),
                _CallButton(icon: Icons.videocam, label: 'Camera', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor: color ?? Colors.white24,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Visit')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How was your consultation?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 40,
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Share your experience (optional)'),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Submit Feedback',
              onPressed: () async {
                await context.read<AppStore>().submitFeedback(
                      appointmentId: widget.appointmentId,
                      rating: _rating,
                      comment: _commentController.text.trim().isEmpty
                          ? null
                          : _commentController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your feedback!')),
                  );
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
