import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/operations_models.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/chat_provider.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _search = TextEditingController();
  final _message = TextEditingController();
  CustomerSummary? _selected;
  String _template = 'sapa';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      chat.fetchCustomers();
      if (chat.conversations.isEmpty) chat.fetchConversations();
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _message.dispose();
    super.dispose();
  }

  Order? _latestOrder(List<Order> orders, String customerId) {
    final list = orders.where((o) => o.customer.id == customerId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.isEmpty ? null : list.first;
  }

  String _text(String key, CustomerSummary c, Order? o) {
    final ref = o != null ? ' untuk pesanan #${o.orderNumber}' : '';
    return switch (key) {
      'kembali' => 'Selamat siang, kami dari VIEGUARD mengingatkan jadwal pengembalian kostum$ref. Mohon dikembalikan tepat waktu, terima kasih.',
      'ukuran' => 'Selamat siang, mohon kirimkan data ukuran siswa$ref (nama, tinggi badan, ukuran) agar produksi bisa segera dijadwalkan.',
      'bayar' => 'Selamat siang, berikut kami informasikan tagihan$ref. Mohon unggah bukti transfer setelah pembayaran, terima kasih.',
      _ => 'Selamat siang ${c.name}, kami dari admin VIEGUARD. Ada yang bisa kami bantu?',
    };
  }

  void _select(CustomerSummary c, Order? o) {
    setState(() {
      _selected = c;
      _message.text = _text(_template, c, o);
    });
  }

  Future<void> _send() async {
    final chat = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_selected == null || _message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final conversation = await chat.startConversation(_selected!.id, _message.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    if (conversation == null) {
      messenger.showSnackBar(SnackBar(content: Text(chat.errorMessage ?? 'Gagal memulai percakapan.')));
      return;
    }
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conversation)));
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final orders = context.watch<OrderProvider>().orders;
    final existing = chat.conversations.map((c) => c.customerId).toSet();
    final q = _search.text.trim().toLowerCase();
    final customers = chat.customers.where((c) {
      if (q.isEmpty) return true;
      final order = _latestOrder(orders, c.id);
      return c.name.toLowerCase().contains(q) || (order?.orderNumber.toLowerCase().contains(q) ?? false);
    }).toList()
      ..sort((a, b) => (existing.contains(a.id) ? 1 : 0).compareTo(existing.contains(b.id) ? 1 : 0));
    final selectedOrder = _selected == null ? null : _latestOrder(orders, _selected!.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Chat Baru'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgTextField(controller: _search, icon: Icons.search_rounded, hint: 'Cari pelanggan atau no. pesanan', color: AppColors.surface, onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          const Text('PILIH PELANGGAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          if (chat.customers.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
          else
            for (final c in customers.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Builder(builder: (context) {
                  final order = _latestOrder(orders, c.id);
                  final selected = _selected?.id == c.id;
                  return TapScale(
                    scaleDown: 0.98,
                    onTap: () => _select(c, order),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.beigeSoft, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                          child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text(
                              order != null ? '${order.orderType.label} #${order.orderNumber} · ${order.headline}' : 'Belum ada pesanan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 6),
                        if (existing.contains(c.id))
                          const VgPill(label: 'Sudah ada chat', color: AppColors.textSecondary, background: AppColors.beige, fontSize: 10)
                        else
                          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: selected ? AppColors.primary : AppColors.textSecondary),
                      ]),
                    ),
                  );
                }),
              ),
          if (_selected != null)
            VgCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const VgCardTitle(title: 'Pesan Pembuka', subtitle: 'Pilih template atau tulis sendiri'),
                VgChoiceChips<String>(
                  options: const [('sapa', 'Sapaan'), ('kembali', 'Pengingat Kembali'), ('ukuran', 'Minta Data Ukuran'), ('bayar', 'Info Pembayaran')],
                  selected: _template,
                  onSelected: (v) => setState(() {
                    _template = v;
                    _message.text = _text(v, _selected!, selectedOrder);
                  }),
                ),
                const SizedBox(height: 12),
                VgTextField(controller: _message, maxLines: 5),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(
          label: _selected == null ? 'Pilih Pelanggan' : 'Kirim & Buka Percakapan',
          icon: Icons.send_rounded,
          expanded: true,
          height: 52,
          loading: _sending,
          onPressed: _selected == null ? null : _send,
        ),
        const SizedBox(height: 6),
      ]),
    );
  }
}
