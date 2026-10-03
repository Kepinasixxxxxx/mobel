import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/report_summary_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiClient apiClient;
  ReportProvider({required this.apiClient});

  ReportSummary? summary;
  ReportSummary? previous;
  bool isLoading = false;
  String? errorMessage;
  DateTime rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime rangeEnd = DateTime.now();

  DateTime get previousStart => rangeStart.subtract(rangeEnd.difference(rangeStart) + const Duration(days: 1));

  DateTime get previousEnd => rangeStart.subtract(const Duration(seconds: 1));

  Future<ReportSummary> _fetch(DateTime start, DateTime end) async {
    final data = await apiClient.get('/reports/summary', query: {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });
    return ReportSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<void> fetchSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([_fetch(rangeStart, rangeEnd), _fetch(previousStart, previousEnd)]);
      summary = results[0];
      previous = results[1];
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
