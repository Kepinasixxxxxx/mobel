import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/operations_models.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiClient apiClient;
  AppointmentProvider({required this.apiClient});

  List<Appointment> _appointments = [];
  bool isLoading = false;
  String? errorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  List<Appointment> onDay(DateTime day) =>
      _appointments.where((a) => a.startAt.year == day.year && a.startAt.month == day.month && a.startAt.day == day.day).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

  Future<void> fetchRange(DateTime start, DateTime end) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.get('/appointments', query: {'startDate': start.toIso8601String(), 'endDate': end.toIso8601String()});
      _appointments = (data as List<dynamic>).map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Appointment>> fetchDay(DateTime day) async {
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    try {
      final data = await apiClient.get('/appointments', query: {'date': key});
      final list = (data as List<dynamic>).map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
      _appointments = [..._appointments.where((a) => !(a.startAt.year == day.year && a.startAt.month == day.month && a.startAt.day == day.day)), ...list];
      notifyListeners();
      return list;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return onDay(day);
    }
  }

  Future<Appointment?> create({
    required String type,
    String? orderId,
    required String customerName,
    required DateTime startAt,
    required int durationMinutes,
    String? room,
    String? staffName,
    String? note,
  }) async {
    try {
      final local = startAt.toIso8601String().substring(0, 19);
      final data = await apiClient.post('/appointments', data: {
        'type': type,
        'orderId': ?orderId,
        'customerName': customerName,
        'startAt': local,
        'durationMinutes': durationMinutes,
        'room': ?room,
        'staffName': ?staffName,
        'note': ?note,
      });
      final created = Appointment.fromJson(data as Map<String, dynamic>);
      _appointments = [..._appointments, created];
      errorMessage = null;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await apiClient.delete('/appointments/$id');
      _appointments = _appointments.where((a) => a.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
