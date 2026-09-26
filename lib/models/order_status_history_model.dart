class OrderStatusHistoryEntry {
  final String id;
  final int progressPercentage;
  final String statusLabel;
  final String? note;
  final String? adminName;
  final DateTime createdAt;

  OrderStatusHistoryEntry({
    required this.id,
    required this.progressPercentage,
    required this.statusLabel,
    this.note,
    this.adminName,
    required this.createdAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    return OrderStatusHistoryEntry(
      id: json['id'].toString(),
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      statusLabel: json['statusLabel'] as String? ?? '-',
      note: json['note'] as String?,
      adminName: admin?['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
