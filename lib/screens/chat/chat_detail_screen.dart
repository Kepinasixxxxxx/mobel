import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/order_model.dart';
import '../../state/chat_provider.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../pesanan/detail_pesanan_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().openConversation(widget.conversation.id));
  }

  @override
  void dispose() {
    context.read<ChatProvider>().leaveConversation();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(widget.conversation.id, text);
    _inputCtrl.clear();
  }

  Order? _linkedOrder(OrderProvider orderProvider) {
    final matches = orderProvider.orders.where((o) => o.customer.id == widget.conversation.customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final linkedOrder = _linkedOrder(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.conversation.customerName)),
      body: Column(
        children: [
          if (linkedOrder != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(children: [
                const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pesanan #${linkedOrder.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      Row(children: [StatusBadge(status: linkedOrder.status), const SizedBox(width: 6), Text(Formatters.rupiah(linkedOrder.totalPrice), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesananScreen(orderId: linkedOrder.id))),
                  child: const Text('Lihat Pesanan', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          Expanded(
            child: chatProvider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: chatProvider.messages[index]),
                  ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  decoration: const InputDecoration(hintText: 'Ketik pesan balasan...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(icon: const Icon(Icons.send, color: AppColors.onPrimary, size: 18), onPressed: _send),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isFromAdmin;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isAdmin ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageAttachment != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network('${ApiConfig.origin}${message.imageAttachment}', width: 180, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
              ),
            if (message.messageText != null && message.messageText!.isNotEmpty)
              Text(message.messageText!, style: TextStyle(color: isAdmin ? AppColors.onPrimary : AppColors.textPrimary, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')} WIB',
              style: TextStyle(color: isAdmin ? AppColors.onPrimaryMuted : AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
