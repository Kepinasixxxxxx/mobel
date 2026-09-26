import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';

class RentalProvider extends ChangeNotifier {
  final ApiClient apiClient;
  RentalProvider({required this.apiClient});

  List<Order> _rentalOrders = [];
  bool isLoading = false;
  String? errorMessage;

  List<Order> get rentalOrders => List.unmodifiable(_rentalOrders.where((o) => o.rental != null));

  Order? orderByRentalId(String rentalId) {
    try {
      return _rentalOrders.firstWhere((o) => o.rental?.id == rentalId);
    } catch (_) {
      return null;
    }
  }

  int countByRentalStatus(RentalStatus status) => rentalOrders.where((o) => o.rental!.status == status).length;

  List<Order> filtered({RentalStatus? status, String query = ''}) {
    return rentalOrders.where((o) {
      final matchesStatus = status == null || o.rental!.status == status;
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          o.orderNumber.toLowerCase().contains(q) ||
          o.customer.name.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList()
      ..sort((a, b) => a.rental!.returnDate.compareTo(b.rental!.returnDate));
  }

  Future<void> fetchRentals() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.get('/orders', query: {'orderType': 'sewa'});
      _rentalOrders = (data as List<dynamic>).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRentalStatus(
    String rentalId, {
    required RentalStatus status,
    String? itemConditionBefore,
    String? itemConditionAfter,
    String? damageNote,
    double? penaltyAmount,
  }) async {
    try {
      await apiClient.patch('/rentals/$rentalId/status', data: {
        'status': rentalStatusToApi(status),
        if (itemConditionBefore != null) 'itemConditionBefore': itemConditionBefore,
        if (itemConditionAfter != null) 'itemConditionAfter': itemConditionAfter,
        if (damageNote != null) 'damageNote': damageNote,
        if (penaltyAmount != null) 'penaltyAmount': penaltyAmount,
      });
      await fetchRentals();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
