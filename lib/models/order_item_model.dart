import '../core/api/api_config.dart';
import '../core/utils/parsing.dart';

class OrderItem {
  final String id;
  final String? productId;
  final String itemType;
  final String name;
  final int quantity;
  final String? size;
  final double unitPrice;
  final double subtotal;
  final String? imageUrl;

  OrderItem({
    required this.id,
    this.productId,
    required this.itemType,
    required this.name,
    required this.quantity,
    this.size,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final accessory = json['accessory'] as Map<String, dynamic>?;
    final name = product?['name'] ?? accessory?['name'] ?? 'Item';
    final images = product?['images'] as List<dynamic>? ?? [];
    final rawImage = images.isNotEmpty ? (images.first as Map<String, dynamic>)['imageUrl'] as String? : null;
    return OrderItem(
      id: json['id'].toString(),
      productId: json['productId']?.toString(),
      itemType: json['itemType'] as String? ?? 'product',
      name: name as String,
      quantity: json['quantity'] as int? ?? 0,
      size: json['size'] as String?,
      unitPrice: parseDecimal(json['unitPrice']),
      subtotal: parseDecimal(json['subtotal']),
      imageUrl: resolveMediaUrl(rawImage, ApiConfig.origin),
    );
  }
}
