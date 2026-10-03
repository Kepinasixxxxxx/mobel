import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/order_status.dart';
import '../models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiClient apiClient;
  PaymentProvider({required this.apiClient});

  List<Payment> _payments = [];
  bool isLoading = false;
  String? errorMessage;

  List<Payment> get payments => List.unmodifiable(_payments);

  int countByStatus(PaymentStatus status) => _payments.where((p) => p.status == status).length;

  Future<void> fetchPayments({PaymentStatus? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final query = <String, dynamic>{};
      if (status != null) query['status'] = paymentStatusToApi(status);
      final data = await apiClient.get('/payments', query: query);
      _payments = (data as List<dynamic>).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPayment(String id, {required bool approve, String? refundReason, String? pin}) async {
    try {
      await apiClient.patch('/payments/$id/verify', data: {
        'status': approve ? 'terverifikasi' : 'ditolak',
        if (!approve && refundReason != null) 'refundReason': refundReason,
        'pin': ?pin,
      });
      await fetchPayments();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
