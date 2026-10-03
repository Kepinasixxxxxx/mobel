import '../core/api/api_config.dart';
import '../core/utils/parsing.dart';

class ProductVariant {
  final String id;
  final String size;
  final int stockBuy;
  final int stockRent;
  final int stockInService;
  final String? serviceNote;
  final double? priceBuyOverride;
  final double? priceRentOverride;

  ProductVariant({
    required this.id,
    required this.size,
    required this.stockBuy,
    required this.stockRent,
    this.stockInService = 0,
    this.serviceNote,
    this.priceBuyOverride,
    this.priceRentOverride,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'].toString(),
        size: json['size'] as String,
        stockBuy: json['stockBuy'] as int? ?? 0,
        stockRent: json['stockRent'] as int? ?? 0,
        stockInService: json['stockInService'] as int? ?? 0,
        serviceNote: json['serviceNote'] as String?,
        priceBuyOverride: parseDecimalOrNull(json['priceBuyOverride']),
        priceRentOverride: parseDecimalOrNull(json['priceRentOverride']),
      );
}

class ProductAccessoryInfo {
  final String name;
  final int quantityPerSet;

  ProductAccessoryInfo({required this.name, required this.quantityPerSet});

  factory ProductAccessoryInfo.fromJson(Map<String, dynamic> json) => ProductAccessoryInfo(
        name: (json['accessory'] as Map<String, dynamic>?)?['name'] as String? ?? '-',
        quantityPerSet: json['quantityPerSet'] as int? ?? 1,
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
  final String? sku;
  final String? conditionGrade;
  final List<String> imageUrls;
  final List<ProductVariant> variants;
  final List<ProductAccessoryInfo> accessories;

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
    this.sku,
    this.conditionGrade,
    required this.imageUrls,
    required this.variants,
    this.accessories = const [],
  });

  int get totalStockRent => variants.fold(0, (sum, v) => sum + v.stockRent);

  int get totalInService => variants.fold(0, (sum, v) => sum + v.stockInService);

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>? ?? []).map((e) => resolveMediaUrl((e as Map<String, dynamic>)['imageUrl'] as String?, ApiConfig.origin)).whereType<String>().toList();
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
      sku: json['sku'] as String?,
      conditionGrade: json['conditionGrade'] as String?,
      imageUrls: images,
      variants: (json['variants'] as List<dynamic>? ?? []).map((e) => ProductVariant.fromJson(e as Map<String, dynamic>)).toList(),
      accessories: (json['productAccessories'] as List<dynamic>? ?? []).map((e) => ProductAccessoryInfo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
