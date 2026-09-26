import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/report_summary_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiClient apiClient;
  ReportProvider({required this.apiClient});

  ReportSummary? summary;
  bool isLoading = false;
  String? errorMessage;
  DateTime rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime rangeEnd = DateTime.now();

  Future<void> fetchSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.get('/reports/summary', query: {
        'startDate': rangeStart.toIso8601String(),
        'endDate': rangeEnd.toIso8601String(),
      });
      summary = ReportSummary.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setRange(DateTime start, DateTime end) {
    rangeStart = start;
    rangeEnd = end;
    fetchSummary();
  }
}
