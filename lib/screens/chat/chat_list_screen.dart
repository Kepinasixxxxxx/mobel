import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/parsing.dart';
import '../../models/conversation_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/auth_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../akun/akun_screen.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

enum _ChatFilter { semua, belumDibaca, konveksi, sewa, perluRespon }

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchFocus = FocusNode();
  String _query = '';
  _ChatFilter _filter = _ChatFilter.semua;
  bool _unreadFirst = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ChatProvider>().fetchConversations();
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([context.read<ChatProvider>().fetchConversations(), context.read<OrderProvider>().fetchOrders()]);

  Order? _latestOrder(List<Order> orders, String customerId) {
    final matches = orders.where((o) => o.customer.id == customerId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  bool _needsResponse(Order? o) => o != null && o.status == OrderStatus.pending;

  bool _matches(Conversation c, Order? o, _ChatFilter f) => switch (f) {
        _ChatFilter.semua => true,
        _ChatFilter.belumDibaca => c.unreadCount > 0,
        _ChatFilter.konveksi => o != null && o.orderType != OrderType.sewa,
        _ChatFilter.sewa => o?.orderType == OrderType.sewa,
        _ChatFilter.perluRespon => _needsResponse(o),
      };

  String _label(_ChatFilter f) => switch (f) {
        _ChatFilter.semua => 'Semua Obrolan',
        _ChatFilter.belumDibaca => 'Belum Dibaca',
        _ChatFilter.konveksi => 'Konveksi',
        _ChatFilter.sewa => 'Sewa',
        _ChatFilter.perluRespon => 'Perlu Respon',
      };

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final orders = context.watch<OrderProvider>().orders;
    final admin = context.watch<AuthProvider>().currentAdmin;
    final q = _query.trim().toLowerCase();

    final entries = chat.conversations.map((c) => (c, _latestOrder(orders, c.customerId))).toList();
    final visible = entries.where((e) {
      if (!_matches(e.$1, e.$2, _filter)) return false;
      if (q.isEmpty) return true;
      return e.$1.customerName.toLowerCase().contains(q) ||
          (e.$1.lastMessageText ?? '').toLowerCase().contains(q) ||
          (e.$2?.orderNumber.toLowerCase().contains(q) ?? false);
    }).toList()
      ..sort((a, b) {
        if (_unreadFirst && (a.$1.unreadCount > 0) != (b.$1.unreadCount > 0)) return a.$1.unreadCount > 0 ? -1 : 1;
        return (b.$1.lastMessageAt ?? DateTime(2000)).compareTo(a.$1.lastMessageAt ?? DateTime(2000));
      });
    final needResponse = entries.where((e) => _needsResponse(e.$2)).toList();
    final needQuote = needResponse.where((e) => e.$2!.needsQuote).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Row(children: [
                if (Navigator.canPop(context)) const BackButton(color: AppColors.primary),
                const VgLogo(size: 36),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('VIEGUARD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('Chat Pelanggan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_outlined, color: AppColors.primary, size: 24),
                  tooltip: 'Chat Baru',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
                ),
                IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 26), onPressed: _searchFocus.requestFocus),
                TapScale(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunScreen())), child: VgAvatar(name: admin?.name ?? 'Admin')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: 'Cari pesan, nama, atau ID pesanan…',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.primary),
                            filled: false,
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                TapScale(
                  onTap: () => setState(() => _unreadFirst = !_unreadFirst),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _unreadFirst ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _unreadFirst ? AppColors.primary : AppColors.border),
                    ),
                    child: Icon(Icons.tune_rounded, color: _unreadFirst ? Colors.white : AppColors.primary),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _ChatFilter.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _ChatFilter.values[i];
                    final selected = f == _filter;
                    final count = f == _ChatFilter.belumDibaca
                        ? entries.where((e) => e.$1.unreadCount > 0).length
                        : entries.where((e) => _matches(e.$1, e.$2, f)).length;
                    final showBadge = f == _ChatFilter.semua || (f == _ChatFilter.belumDibaca && count > 0);
                    return TapScale(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_label(f), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
                          if (showBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(
                                color: f == _ChatFilter.belumDibaca ? const Color(0xFFF59E0B) : (selected ? Colors.white.withValues(alpha: 0.2) : AppColors.beige),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$count', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: f == _ChatFilter.belumDibaca || selected ? Colors.white : AppColors.textPrimary)),
                            ),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (needResponse.isNotEmpty) ...[
                TapScale(
                  onTap: () => setState(() => _filter = _ChatFilter.perluRespon),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1C7), borderRadius: BorderRadius.circular(14)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const VgIconBadge(icon: Icons.priority_high_rounded, color: Colors.white, background: Color(0xFFF59E0B), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Expanded(child: Text('PERHATIAN DIPERLUKAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.goldDark, letterSpacing: 0.4))),
                            Text('Prioritas', style: TextStyle(fontSize: 12, color: AppColors.goldDark)),
                            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.goldDark),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            '${needResponse.length} pelanggan menunggu respon${needQuote > 0 ? ' ($needQuote butuh penawaran harga)' : ''} & konfirmasi pesanan.',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.35),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (chat.isLoadingList && chat.conversations.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
              else if (chat.errorMessage != null && chat.conversations.isEmpty)
                VgCard(child: Text(chat.errorMessage!, style: const TextStyle(color: AppColors.danger)))
              else if (visible.isEmpty)
                const VgCard(child: Text('Belum ada percakapan pada filter ini.', style: TextStyle(color: AppColors.textSecondary)))
              else
                for (final (c, o) in visible)
                  _ConversationCard(
                    conversation: c,
                    order: o,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: c))),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final Order? order;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.order, required this.onTap});

  String _time(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) return '${DateFormat('HH:mm').format(t)} WIB';
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('d MMM', 'id_ID').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;
    final photo = resolveMediaUrl(c.customerPhoto, ApiConfig.origin);
    final o = order;

    IconData? orderIcon;
    String? orderLabel;
    Color orderBg = AppColors.beige;
    if (o != null) {
      final prefix = switch (o.orderType) {
        OrderType.sewa => 'Rental',
        OrderType.custom => 'Custom',
        OrderType.beli => o.status == OrderStatus.diproses ? 'Produksi' : 'Pesanan',
      };
      orderIcon = switch (o.orderType) {
        OrderType.sewa => Icons.theater_comedy_outlined,
        OrderType.custom => Icons.handyman_outlined,
        OrderType.beli => Icons.receipt_long_outlined,
      };
      orderLabel = '$prefix #${o.orderNumber} • ${o.headline} ${o.totalQuantity} Stel';
      if (o.isCustom && o.status == OrderStatus.pending) orderBg = const Color(0xFFFFF1C7);
    }

    return VgCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.beigeSoft, border: Border.all(color: AppColors.border)),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: photo != null
                ? Image.network(photo, fit: BoxFit.cover, width: 50, height: 50, errorBuilder: (context, error, stackTrace) => _Initial(name: c.customerName))
                : _Initial(name: c.customerName),
          ),
          if (unread)
            Positioned(
              right: -1,
              bottom: 2,
              child: Container(width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF22A447), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
              const SizedBox(width: 8),
              Text(_time(c.lastMessageAt), style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
            ]),
            if (orderLabel != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: orderBg, borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(orderIcon, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Flexible(child: Text(orderLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.primary))),
                ]),
              ),
            ],
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Text(
                  c.lastMessageText == null ? 'Belum ada pesan' : '${c.lastFromAdmin ? 'Anda' : c.customerName.split(' ').first}: "${c.lastMessageText}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary, fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              if (unread)
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(11)),
                  child: Text('${c.unreadCount}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                )
              else if (c.lastFromAdmin)
                const Icon(Icons.done_all_rounded, size: 17, color: AppColors.primary),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  const _Initial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary));
  }
}
