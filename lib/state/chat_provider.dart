import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;

import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/api/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/conversation_model.dart';
import '../models/operations_models.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  ChatProvider({required this.apiClient, required this.tokenStorage});

  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  String? _activeConversationId;
  bool isLoadingList = false;
  bool isLoadingMessages = false;
  bool isSending = false;
  String? errorMessage;

  io_client.Socket? _socket;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> fetchConversations() async {
    isLoadingList = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await apiClient.get('/chat/conversations');
      _conversations = (data as List<dynamic>).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(String conversationId) async {
    _activeConversationId = conversationId;
    isLoadingMessages = true;
    _messages = [];
    notifyListeners();
    try {
      final data = await apiClient.get('/chat/conversations/$conversationId/messages');
      _messages = (data as List<dynamic>).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final old = _conversations[index];
        _conversations[index] = Conversation(
          id: old.id,
          customerId: old.customerId,
          customerName: old.customerName,
          customerPhoto: old.customerPhoto,
          lastMessageText: old.lastMessageText,
          lastMessageAt: old.lastMessageAt,
          lastFromAdmin: old.lastFromAdmin,
        );
      }
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
    await _ensureSocketConnected();
    _socket?.emit('conversation:join', conversationId);
  }

  Future<void> _ensureSocketConnected() async {
    if (_socket != null && _socket!.connected) return;
    final token = await tokenStorage.readAccessToken();
    if (token == null) return;

    _socket?.dispose();
    _socket = io_client.io(
      '${ApiConfig.origin}/ws/mobile',
      io_client.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnectError((_) {
      errorMessage = 'Gagal terhubung ke server chat real-time.';
      notifyListeners();
    });

    _socket!.on('message:new', (data) {
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
      if (message.conversationId == _activeConversationId) {
        _messages.add(message);
      }
      final convIndex = _conversations.indexWhere((c) => c.id == message.conversationId);
      if (convIndex != -1) {
        final old = _conversations[convIndex];
        _conversations[convIndex] = Conversation(
          id: old.id,
          customerId: old.customerId,
          customerName: old.customerName,
          customerPhoto: old.customerPhoto,
          lastMessageText: message.messageText,
          lastMessageAt: message.createdAt,
          unreadCount: message.isFromAdmin || message.conversationId == _activeConversationId ? old.unreadCount : old.unreadCount + 1,
          lastFromAdmin: message.isFromAdmin,
        );
      }
      notifyListeners();
    });

    _socket!.connect();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;
    isSending = true;
    notifyListeners();
    await _ensureSocketConnected();
    _socket?.emit('message:send', {'conversationId': conversationId, 'messageText': text.trim()});
    isSending = false;
    notifyListeners();
  }

  void leaveConversation() {
    _activeConversationId = null;
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  List<CustomerSummary> customers = [];

  Future<void> fetchCustomers() async {
    try {
      final data = await apiClient.get('/customers');
      customers = (data as List<dynamic>).map((e) => CustomerSummary.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<Conversation?> startConversation(String userId, String message) async {
    try {
      await apiClient.post('/chat/conversations', data: {'userId': userId, 'messageText': message});
      await fetchConversations();
      final matches = _conversations.where((c) => c.customerId == userId);
      return matches.isEmpty ? null : matches.first;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }
}
