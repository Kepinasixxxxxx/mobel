import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  List<Order> rentalsForProduct(String productId) =>
      rentalOrders.where((o) => o.items.any((i) => i.productId == productId)).toList()..sort((a, b) => b.rental!.pickupDate.compareTo(a.rental!.pickupDate));

  int _qty(String productId, Set<RentalStatus> statuses, String? size) => rentalOrders
      .where((o) => statuses.contains(o.rental!.status))
      .expand((o) => o.items)
      .where((i) => i.productId == productId && (size == null || i.size == size))
      .fold(0, (sum, i) => sum + i.quantity);

  int rentedQty(String productId, {String? size}) => _qty(productId, {RentalStatus.diambil, RentalStatus.terlambat}, size);

  int bookedQty(String productId, {String? size}) => _qty(productId, {RentalStatus.dipesan}, size);

  DateTime? earliestReturn(String productId) {
    final dates = rentalsForProduct(productId)
        .where((o) => o.rental!.status == RentalStatus.diambil || o.rental!.status == RentalStatus.terlambat)
        .map((o) => o.rental!.returnDate)
        .toList()
      ..sort();
    return dates.isEmpty ? null : dates.first;
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
        'itemConditionBefore': ?itemConditionBefore,
        'itemConditionAfter': ?itemConditionAfter,
        'damageNote': ?damageNote,
        'penaltyAmount': ?penaltyAmount,
      });
      await fetchRentals();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handover(String rentalId, {String? pickupTime, String? returnTime, double? depositAmount, String? conditionNote, XFile? agreementPhoto}) async {
    try {
      final form = FormData.fromMap({
        'pickupTime': ?pickupTime,
        'returnTime': ?returnTime,
        if (depositAmount != null) 'depositAmount': depositAmount.toString(),
        'conditionNote': ?conditionNote,
      });
      if (agreementPhoto != null) {
        form.files.add(MapEntry('agreementPhoto', ApiClient.imageFile(await agreementPhoto.readAsBytes(), agreementPhoto.name)));
      }
      await apiClient.patchForm('/rentals/$rentalId/handover', form);
      await fetchRentals();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refund(String rentalId, {required double amount, String? bank, String? account, String? holder, XFile? proof, String? pin}) async {
    try {
      final form = FormData.fromMap({
        'refundAmount': amount.toString(),
        'refundBank': ?bank,
        'refundAccount': ?account,
        'refundHolder': ?holder,
        'pin': ?pin,
      });
      if (proof != null) form.files.add(MapEntry('refundProof', ApiClient.imageFile(await proof.readAsBytes(), proof.name)));
      await apiClient.patchForm('/rentals/$rentalId/refund', form);
      await fetchRentals();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
