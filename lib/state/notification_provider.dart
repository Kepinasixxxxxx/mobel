import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient apiClient;
  NotificationProvider({required this.apiClient});

  List<AppNotification> _notifications = [];
  bool isLoading = false;
  String? errorMessage;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.get('/notifications');
      _notifications = (data as List<dynamic>).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    try {
      await apiClient.patch('/notifications/$id/read');
      final old = _notifications[index];
      _notifications[index] = AppNotification(
        id: old.id,
        type: old.type,
        title: old.title,
        message: old.message,
        relatedOrderId: old.relatedOrderId,
        isRead: true,
        createdAt: old.createdAt,
      );
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.id);
    }
  }
}
