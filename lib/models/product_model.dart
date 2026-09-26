import '../core/utils/parsing.dart';

class ProductVariant {
  final String id;
  final String size;
  final int stockBuy;
  final int stockRent;
  final double? priceBuyOverride;
  final double? priceRentOverride;

  ProductVariant({
    required this.id,
    required this.size,
    required this.stockBuy,
    required this.stockRent,
    this.priceBuyOverride,
    this.priceRentOverride,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'].toString(),
        size: json['size'] as String,
        stockBuy: json['stockBuy'] as int? ?? 0,
        stockRent: json['stockRent'] as int? ?? 0,
        priceBuyOverride: parseDecimalOrNull(json['priceBuyOverride']),
        priceRentOverride: parseDecimalOrNull(json['priceRentOverride']),
      );
}

class Product {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final String? description;
  final double? basePriceBuy;
  final double? basePriceRent;
  final bool isCustomAvailable;
  final bool isVisible;
  final List<String> imageUrls;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    this.basePriceBuy,
    this.basePriceRent,
    required this.isCustomAvailable,
    required this.isVisible,
    required this.imageUrls,
    required this.variants,
  });

  int get totalStockRent => variants.fold(0, (sum, v) => sum + v.stockRent);

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>? ?? []).map((e) => (e as Map<String, dynamic>)['imageUrl'] as String).toList();
    return Product(
      id: json['id'].toString(),
      categoryId: json['categoryId'].toString(),
      categoryName: category?['name'] as String? ?? '-',
      name: json['name'] as String,
      description: json['description'] as String?,
      basePriceBuy: parseDecimalOrNull(json['basePriceBuy']),
      basePriceRent: parseDecimalOrNull(json['basePriceRent']),
      isCustomAvailable: json['isCustomAvailable'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      imageUrls: images,
      variants: (json['variants'] as List<dynamic>? ?? []).map((e) => ProductVariant.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
