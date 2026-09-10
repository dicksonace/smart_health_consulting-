class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentMimeType,
    this.messageType = 'text',
    this.metadata,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  bool isRead;
  final String? attachmentUrl;
  final String? attachmentMimeType;
  final String messageType;
  final Map<String, dynamic>? metadata;

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get isCallEvent =>
      messageType == 'call_started' ||
      messageType == 'call_ended' ||
      messageType == 'call_missed';
}

class Conversation {
  Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.messages,
  });

  final String id;
  final String participantId;
  final String participantName;
  final String participantRole;
  String lastMessage;
  DateTime lastMessageAt;
  int unreadCount;
  final List<ChatMessage> messages;
}
