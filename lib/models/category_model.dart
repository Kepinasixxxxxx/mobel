class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final int productCount;

  ProductCategory({required this.id, required this.name, this.description, this.productCount = 0});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return ProductCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      productCount: count?['products'] as int? ?? 0,
    );
  }
}
