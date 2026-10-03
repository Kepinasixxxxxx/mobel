import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/operations_models.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';

class OrderProvider extends ChangeNotifier {
  final ApiClient apiClient;
  OrderProvider({required this.apiClient});

  List<Order> _orders = [];
  bool isLoading = false;
  String? errorMessage;

  List<Order> get orders => List.unmodifiable(_orders);

  Order? orderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  int get perluTindakanCount => _orders.where((o) => o.butuhTindakan).length;

  int countByStatus(OrderStatus status) => _orders.where((o) => o.status == status).length;

  int countByType(OrderType type) => _orders.where((o) => o.orderType == type).length;

  double get omsetTotal => _orders
      .where((o) => o.status != OrderStatus.pending && o.status != OrderStatus.dibatalkan)
      .fold(0, (sum, o) => sum + o.totalPrice);

  double get progresProduksiRata {
    final produksi = _orders.where((o) => o.status == OrderStatus.diproses || o.status == OrderStatus.siapDiambil);
    if (produksi.isEmpty) return 0;
    final total = produksi.fold<double>(0, (sum, o) => sum + (o.latestProgress / 100));
    return total / produksi.length;
  }

  List<Order> get pesananTerbaru {
    final sorted = [..._orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(3).toList();
  }

  List<Order> filtered({OrderStatus? status, OrderType? orderType, String query = ''}) {
    return _orders.where((o) {
      final matchesStatus = status == null || o.status == status;
      final matchesType = orderType == null || o.orderType == orderType;
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          o.orderNumber.toLowerCase().contains(q) ||
          o.customer.name.toLowerCase().contains(q);
      return matchesStatus && matchesType && matchesQuery;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> fetchOrders({OrderStatus? status, OrderType? orderType, String? search}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final query = <String, dynamic>{};
      if (status != null) query['status'] = orderStatusToApi(status);
      if (orderType != null) query['orderType'] = orderTypeToApi(orderType);
      if (search != null && search.isNotEmpty) query['search'] = search;

      final data = await apiClient.get('/orders', query: query);
      _orders = (data as List<dynamic>).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> fetchOrderDetail(String id) async {
    try {
      final data = await apiClient.get('/orders/$id');
      final order = Order.fromJson(data as Map<String, dynamic>);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = order;
      } else {
        _orders.add(order);
      }
      notifyListeners();
      return order;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmOrder(String id, {double? dpAmount}) async {
    try {
      final payload = <String, dynamic>{};
      if (dpAmount != null) payload['dpAmount'] = dpAmount;
      await apiClient.patch('/orders/$id/confirm', data: payload);
      await fetchOrderDetail(id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitQuote(String id, {required double totalPrice, double? dpAmount, DateTime? deadlineDate, String? note}) async {
    try {
      await apiClient.patch('/orders/$id/quote', data: {
        'totalPrice': totalPrice,
        'dpAmount': dpAmount,
        if (deadlineDate != null) 'deadlineDate': deadlineDate.toIso8601String().substring(0, 10),
        'note': ?note,
      });
      await fetchOrderDetail(id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProgress(String id, {required int progressPercentage, required String statusLabel, String? note}) async {
    try {
      await apiClient.patch('/orders/$id/progress', data: {
        'progressPercentage': progressPercentage,
        'statusLabel': statusLabel,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await fetchOrderDetail(id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus(String id, OrderStatus status, {String? note}) async {
    try {
      await apiClient.patch('/orders/$id/status', data: {
        'status': orderStatusToApi(status),
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await fetchOrderDetail(id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(String id, Future<void> Function() action) async {
    try {
      await action();
      await fetchOrderDetail(id);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSizeEntries(String id, List<SizeEntry> entries) =>
      _run(id, () => apiClient.put('/orders/$id/sizes', data: {'entries': entries.map((e) => e.toJson()).toList()}));

  Future<bool> shipOrder(String id, {required String courier, String? trackingNumber, double? shippingCost, DateTime? etaDate}) => _run(
        id,
        () => apiClient.patch('/orders/$id/ship', data: {
          'courier': courier,
          if (trackingNumber != null && trackingNumber.isNotEmpty) 'trackingNumber': trackingNumber,
          'shippingCost': ?shippingCost,
          if (etaDate != null) 'etaDate': etaDate.toIso8601String().substring(0, 10),
        }),
      );

  Future<bool> uploadPhotos(String id, {required String category, String? title, bool isPublic = true, required List<XFile> files}) => _run(id, () async {
        final form = FormData.fromMap({'category': category, if (title != null && title.isNotEmpty) 'title': title, 'isPublic': isPublic.toString()});
        for (final file in files) {
          form.files.add(MapEntry('orderPhotos', ApiClient.imageFile(await file.readAsBytes(), file.name)));
        }
        await apiClient.postForm('/orders/$id/photos', form);
      });

  Future<bool> deletePhoto(String orderId, String photoId) => _run(orderId, () => apiClient.delete('/orders/photos/$photoId'));
}
