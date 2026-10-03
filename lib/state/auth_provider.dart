import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/admin_model.dart';
import '../models/operations_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthProvider({required this.apiClient, required this.tokenStorage}) {
    apiClient.onSessionExpired = _handleSessionExpired;
  }

  AuthStatus status = AuthStatus.unknown;
  Admin? currentAdmin;
  bool isLoading = false;
  String? errorMessage;

  Future<void> tryAutoLogin() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await apiClient.get('/account/me');
      currentAdmin = Admin.fromJson(data as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } on ApiException {
      await tokenStorage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.post('/auth/login', data: {'email': email, 'password': password});
      currentAdmin = Admin.fromJson(data['admin'] as Map<String, dynamic>);
      await tokenStorage.save(accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    errorMessage = null;
    try {
      await apiClient.post('/auth/forgot-password', data: {'email': email});
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

  Future<bool> resetPassword({required String email, required String otpCode, required String newPassword}) async {
    errorMessage = null;
    try {
      await apiClient.post('/auth/reset-password', data: {'email': email, 'otpCode': otpCode, 'newPassword': newPassword});
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    try {
      final data = await apiClient.put('/account/me', data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      currentAdmin = Admin.fromJson(data as Map<String, dynamic>);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      await apiClient.patch('/account/change-password', data: {'oldPassword': oldPassword, 'newPassword': newPassword});
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    try {
      await apiClient.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // ignore network errors on logout
    }
    await _handleSessionExpired();
  }

  Future<void> _handleSessionExpired() async {
    await tokenStorage.clear();
    currentAdmin = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  SecurityInfo? security;

  Future<SecurityInfo?> fetchSecurity() async {
    try {
      final data = await apiClient.get('/account/security');
      security = SecurityInfo.fromJson(data as Map<String, dynamic>);
      notifyListeners();
      return security;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> _securityAction(Future<void> Function() action) async {
    try {
      await action();
      await fetchSecurity();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPin({required String pin, required String password}) => _securityAction(() => apiClient.patch('/account/pin', data: {'pin': pin, 'password': password}));

  Future<bool> setAutoAccept(bool value) => _securityAction(() => apiClient.patch('/account/settings', data: {'autoAcceptOrders': value}));

  Future<bool> revokeSession(String id) => _securityAction(() => apiClient.delete('/account/sessions/$id'));
}
