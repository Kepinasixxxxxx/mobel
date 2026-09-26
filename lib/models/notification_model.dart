class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? relatedOrderId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedOrderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        relatedOrderId: json['relatedOrderId']?.toString(),
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
