import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiClient apiClient;
  ProductProvider({required this.apiClient});

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  bool isLoading = false;
  String? errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  Product? productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> filtered({String? categoryId, String query = ''}) {
    return _products.where((p) {
      final matchesCategory = categoryId == null || p.categoryId == categoryId;
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.categoryName.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<bool> toggleVisibility(String id, bool isVisible) async {
    try {
      await apiClient.patch('/products/$id/visibility', data: {'isVisible': isVisible});
      await fetchAll();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([apiClient.get('/products'), apiClient.get('/categories')]);
      _products = (results[0] as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      _categories = (results[1] as List<dynamic>).map((e) => ProductCategory.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> createProduct(Map<String, dynamic> data, List<XFile> photos) async {
    try {
      final created = await apiClient.post('/products', data: data);
      final id = (created as Map<String, dynamic>)['id'].toString();
      if (photos.isNotEmpty) {
        final form = FormData();
        for (final photo in photos) {
          form.files.add(MapEntry('productImages', ApiClient.imageFile(await photo.readAsBytes(), photo.name)));
        }
        await apiClient.postForm('/products/$id/images', form);
      }
      await fetchAll();
      return productById(id);
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVariants(String id, List<Map<String, dynamic>> variants) async {
    try {
      await apiClient.put('/products/$id/variants', data: {'variants': variants});
      await fetchAll();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
