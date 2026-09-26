import '../core/utils/parsing.dart';

class OrderItem {
  final String id;
  final String itemType;
  final String name;
  final int quantity;
  final String? size;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.itemType,
    required this.name,
    required this.quantity,
    this.size,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final accessory = json['accessory'] as Map<String, dynamic>?;
    final name = product?['name'] ?? accessory?['name'] ?? 'Item';
    return OrderItem(
      id: json['id'].toString(),
      itemType: json['itemType'] as String? ?? 'product',
      name: name as String,
      quantity: json['quantity'] as int? ?? 0,
      size: json['size'] as String?,
      unitPrice: parseDecimal(json['unitPrice']),
      subtotal: parseDecimal(json['subtotal']),
    );
  }
}
