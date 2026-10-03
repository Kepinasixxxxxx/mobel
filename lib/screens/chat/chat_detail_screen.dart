import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsing.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/chat_provider.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
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
  late final ChatProvider _chat;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    Future.microtask(() {
      if (!mounted) return;
      _chat.openConversation(widget.conversation.id);
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
    });
  }

  @override
  void dispose() {
    _chat.leaveConversation();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _chat.sendMessage(widget.conversation.id, text);
    if (preset == null) _inputCtrl.clear();
  }

  void _scrollToEnd(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  Order? _linkedOrder(OrderProvider provider) {
    final matches = provider.orders.where((o) => o.customer.id == widget.conversation.customerId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  List<(String, IconData, String)> _quickReplies(Order? order) => [
        ('Minta Bukti Transfer', Icons.receipt_long_outlined, 'Mohon kirimkan bukti transfer pembayaran${order != null ? ' untuk pesanan #${order.orderNumber}' : ''} agar dapat segera kami verifikasi.'),
        ('Minta Data Ukuran', Icons.straighten_rounded, 'Mohon kirimkan rekap data ukuran (S/M/L/XL) beserta jumlah per ukuran agar produksi dapat dijadwalkan.'),
        ('Konfirmasi Jadwal', Icons.event_available_outlined, 'Kami ingin mengonfirmasi jadwal pengambilan/pengiriman pesanan. Mohon informasikan waktu yang sesuai.'),
        ('Terima Kasih', Icons.favorite_border_rounded, 'Terima kasih atas kepercayaan Anda kepada VIEGUARD. Kami akan segera memproses permintaan Anda.'),
      ];

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final order = _linkedOrder(context.watch<OrderProvider>());
    final messages = chat.messages;
    _scrollToEnd(messages.length);
    final firstName = widget.conversation.customerName.split(' ').first;

    final items = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (day != lastDay) {
        items.add(_DateSeparator(date: day));
        lastDay = day;
      }
      final prev = i > 0 ? messages[i - 1] : null;
      final grouped = prev != null && prev.senderType == m.senderType && m.createdAt.difference(prev.createdAt).inMinutes < 5;
      items.add(_MessageBubble(message: m, customerName: widget.conversation.customerName, showHeader: !grouped));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VgBackBar(title: widget.conversation.customerName),
      body: Column(children: [
        if (order != null) _OrderContextCard(order: order),
        Expanded(
          child: chat.isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const Center(child: Text('Belum ada pesan. Mulai percakapan dengan pelanggan.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)))
                  : ListView(controller: _scrollCtrl, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: items),
        ),
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.only(top: 8),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final q in _quickReplies(order))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TapScale(
                          onTap: () => setState(() => _inputCtrl.text = q.$3),
                          child: VgPill(label: q.$1, color: AppColors.primary, background: AppColors.beige, icon: q.$2, fontSize: 12, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(16)),
                      child: TextField(
                        controller: _inputCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan balasan untuk $firstName',
                          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.primary),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TapScale(
                    onTap: chat.isSending ? null : _send,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: chat.isSending
                          ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _OrderContextCard extends StatelessWidget {
  final Order order;
  const _OrderContextCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dpVerified = order.amountPaid > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const VgIconBadge(icon: Icons.inventory_2_outlined, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Pesanan #${order.orderNumber}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                TapScale(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesananScreen(orderId: order.id))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Lihat', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ]),
                ),
              ]),
              const SizedBox(height: 4),
              OrderStatusPill(order: order),
              const SizedBox(height: 4),
              Text('${order.headline} (${order.totalQuantity} Stel)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.primary)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            VgPill(label: 'Total: ${order.needsQuote ? 'Belum ditentukan' : Formatters.rupiah(order.totalPrice)}', color: AppColors.textPrimary, background: AppColors.beige, icon: Icons.payments_outlined, fontSize: 11.5),
            const SizedBox(width: 8),
            VgPill(
              label: dpVerified ? 'DP: Terverifikasi' : 'DP: Belum dibayar',
              color: dpVerified ? AppColors.success : AppColors.warning,
              background: AppColors.beige,
              icon: dpVerified ? Icons.verified_outlined : Icons.schedule_rounded,
              fontSize: 11.5,
            ),
            if (order.deadlineDate != null) ...[
              const SizedBox(width: 8),
              VgPill(label: 'Target: ${Formatters.date(order.deadlineDate!)}', color: AppColors.textPrimary, background: AppColors.beige, icon: Icons.event_outlined, fontSize: 11.5),
            ],
            if (order.status == OrderStatus.diproses) ...[
              const SizedBox(width: 8),
              VgPill(label: 'Progres ${order.latestProgress}%', color: AppColors.primary, background: AppColors.beige, icon: Icons.precision_manufacturing_outlined, fontSize: 11.5),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: VgPill(
          label: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
          color: AppColors.primary,
          background: AppColors.beige,
          icon: Icons.calendar_today_rounded,
          fontSize: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String customerName;
  final bool showHeader;

  const _MessageBubble({required this.message, required this.customerName, required this.showHeader});

  @override
  Widget build(BuildContext context) {
    final admin = message.isFromAdmin;
    final time = '${DateFormat('HH:mm').format(message.createdAt)} WIB';
    final image = resolveMediaUrl(message.imageAttachment, ApiConfig.origin);
    final maxWidth = MediaQuery.of(context).size.width * 0.74;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: admin ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(admin ? 14 : 4),
          topRight: Radius.circular(admin ? 4 : 14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
        boxShadow: admin ? null : AppColors.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (image != null)
          Padding(
            padding: EdgeInsets.only(bottom: message.messageText?.isNotEmpty == true ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(image, width: 200, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
            ),
          ),
        if (message.messageText != null && message.messageText!.isNotEmpty)
          Text(message.messageText!, style: TextStyle(fontSize: 14.5, height: 1.45, color: admin ? Colors.white : AppColors.textPrimary)),
      ]),
    );

    if (admin) {
      return Padding(
        padding: EdgeInsets.only(top: showHeader ? 10 : 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          bubble,
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(time, style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.done_all_rounded, size: 14, color: AppColors.primary),
          ]),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 10 : 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 36,
          child: showHeader ? const VgIconBadge(icon: Icons.school_outlined, size: 30, circle: true) : null,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 4),
                child: Row(children: [
                  Flexible(child: Text(customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                ]),
              ),
            bubble,
          ]),
        ),
      ]),
    );
  }
}
