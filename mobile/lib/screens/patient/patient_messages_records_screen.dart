import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PatientMessagesScreen extends StatelessWidget {
  const PatientMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<AppStore>().conversations;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversations.isEmpty
          ? const EmptyState(icon: Icons.chat_bubble_outline, message: 'No conversations yet')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              itemBuilder: (context, i) {
                final conv = conversations[i];
                return AppCard(
                  onTap: () => context.push('/patient/messages/${conv.id}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          conv.participantName[0],
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
                                  child: Text(conv.participantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  DateFormat('h:mm a').format(conv.lastMessageAt),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppStore>().fetchMessages(widget.conversationId);
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final conv = store.conversationById(widget.conversationId);
    final userId = store.currentUser?.id;

    if (conv == null && _loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (conv == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const EmptyState(icon: Icons.error_outline, message: 'Conversation not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(conv.participantName)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conv.messages.length,
              itemBuilder: (context, i) {
                final msg = conv.messages[i];
                final isMe = msg.senderId == userId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.body,
                          style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(msg.sentAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File attach (mock)')),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;
                    final body = _controller.text.trim();
                    _controller.clear();
                    await store.sendMessage(widget.conversationId, body);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AppStore>().medicalRecords;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, i) {
          final rec = records[i];
          return AppCard(
            onTap: () => context.push('/patient/records/${rec.id}'),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(rec.doctorName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        DateFormat('MMM d, y').format(rec.visitDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    );
  }
}

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final record = context.watch<AppStore>().recordById(recordId);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record')),
        body: const EmptyState(icon: Icons.error_outline, message: 'Record not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Visit Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.diagnosis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${record.doctorName} · ${record.doctorSpecialty}'),
                  Text(
                    DateFormat('MMMM d, y').format(record.visitDate),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(record.notes),
                  const SizedBox(height: 12),
                  const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(record.recommendations),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Prescriptions'),
            for (final rx in record.prescriptions)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.medication, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rx.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${rx.dosage} · ${rx.duration}'),
                          if (rx.instructions != null)
                            Text(rx.instructions!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Download ${rx.medicineName} (mock)')),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final notifications = store.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, i) {
          final n = notifications[i];
          return AppCard(
            onTap: () => store.markNotificationRead(n.id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconForType(n.type),
                  color: n.isRead ? AppColors.textSecondary : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        DateFormat('MMM d · h:mm a').format(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'appointment_reminder':
        return Icons.event;
      case 'new_message':
        return Icons.chat;
      case 'prescription':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }
}

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

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
              child: Text(
                user.name[0],
                style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  _ProfileRow(Icons.phone, 'Phone', user.phone),
                  const Divider(),
                  _ProfileRow(Icons.cake, 'Date of Birth', user.dateOfBirth ?? '-'),
                  const Divider(),
                  _ProfileRow(Icons.bloodtype, 'Blood Group', user.bloodGroup ?? '-'),
                  const Divider(),
                  _ProfileRow(Icons.warning_amber, 'Allergies', user.allergies ?? 'None'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder_open, color: AppColors.primary),
              title: const Text('Medical Records'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/patient/records'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.primary),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/patient/notifications'),
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
