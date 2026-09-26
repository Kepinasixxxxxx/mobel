class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType;
  final String senderId;
  final String? messageText;
  final String? imageAttachment;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    this.messageText,
    this.imageAttachment,
    required this.createdAt,
  });

  bool get isFromAdmin => senderType == 'admin';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'].toString(),
        conversationId: json['conversationId'].toString(),
        senderType: json['senderType'] as String,
        senderId: json['senderId'].toString(),
        messageText: json['messageText'] as String?,
        imageAttachment: json['imageAttachment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
