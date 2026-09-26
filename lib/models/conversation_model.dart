class Conversation {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhoto;
  final String? lastMessageText;
  final DateTime? lastMessageAt;

  Conversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhoto,
    this.lastMessageText,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final messages = json['messages'] as List<dynamic>?;
    final lastMessage = (messages != null && messages.isNotEmpty) ? messages.first as Map<String, dynamic> : null;
    return Conversation(
      id: json['id'].toString(),
      customerId: user?['id']?.toString() ?? '0',
      customerName: user?['name'] as String? ?? 'Pelanggan',
      customerPhoto: user?['profilePhoto'] as String?,
      lastMessageText: lastMessage?['messageText'] as String?,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt'].toString()) : null,
    );
  }
}
