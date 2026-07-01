class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  bool isRead;
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
