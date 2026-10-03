import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/auth_provider.dart';
import '../../state/notification_provider.dart';
import '../../state/order_provider.dart';
import '../../state/payment_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../akun/akun_screen.dart';
import '../pembayaran/payment_verification_detail_screen.dart';
import '../pembayaran/payment_verification_list_screen.dart';
import '../penyewaan/penyewaan_detail_screen.dart';
import '../penyewaan/penyewaan_list_screen.dart';
import '../pesanan/detail_pesanan_screen.dart';
import '../pesanan/input_harga_screen.dart';

enum _Cat { semua, pesanan, sewa, produksi }

class _Activity {
  final String key;
  final DateTime time;
  final _Cat cat;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final bool unread;
  final String? notificationId;
  final Widget? extra;
  final VoidCallback? onTap;

  _Activity({
    required this.key,
    required this.time,
    required this.cat,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBg = AppColors.beige,
    required this.title,
    required this.body,
    this.unread = false,
    this.notificationId,
    this.extra,
    this.onTap,
  });
}

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  _Cat _cat = _Cat.semua;
  bool _unreadOnly = false;
  bool _showArchive = false;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications();
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
      final rentals = context.read<RentalProvider>();
      if (rentals.rentalOrders.isEmpty) rentals.fetchRentals();
      context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu);
    });
  }

  Future<void> _refresh() => Future.wait([
        context.read<NotificationProvider>().fetchNotifications(),
        context.read<OrderProvider>().fetchOrders(),
        context.read<RentalProvider>().fetchRentals(),
        context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu),
      ]);

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  List<_Activity> _build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>().notifications;
    final orders = context.watch<OrderProvider>();
    final rentals = context.watch<RentalProvider>().rentalOrders;
    final payments = context.watch<PaymentProvider>().payments;
    final result = <_Activity>[];

    for (final n in notifications) {
      final order = n.relatedOrderId != null ? orders.orderById(n.relatedOrderId!) : null;
      final type = n.type.toUpperCase();
      if (type.contains('PAYMENT')) {
        final pending = payments.where((p) => p.orderId == n.relatedOrderId && p.status == PaymentStatus.menunggu).firstOrNull;
        result.add(_Activity(
          key: 'n${n.id}',
          time: n.createdAt,
          cat: _Cat.pesanan,
          icon: Icons.account_balance_outlined,
          title: n.title,
          body: n.message,
          unread: !n.isRead,
          notificationId: n.id,
          extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (pending != null) ...[
              VgPill(label: 'Menunggu Konfirmasi Admin', color: AppColors.warning, background: const Color(0xFFFFF4D6), dot: true, fontSize: 11),
              const SizedBox(height: 10),
            ],
            VgButton(
              label: pending != null ? 'Tinjau Bukti Transfer' : 'Lihat Pembayaran',
              icon: Icons.receipt_long_outlined,
              style: pending != null ? VgButtonStyle.maroon : VgButtonStyle.soft,
              height: 38,
              onPressed: () => _push(pending != null ? PaymentVerificationDetailScreen(paymentId: pending.id) : const PaymentVerificationListScreen()),
            ),
          ]),
        ));
      } else {
        result.add(_Activity(
          key: 'n${n.id}',
          time: n.createdAt,
          cat: _Cat.pesanan,
          icon: order?.isCustom == true ? Icons.checkroom_rounded : Icons.receipt_long_outlined,
          title: n.title,
          body: n.message,
          unread: !n.isRead,
          notificationId: n.id,
          extra: order == null
              ? null
              : Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
                  order.needsQuote
                      ? VgButton(label: 'Buat Draft Penawaran', icon: Icons.request_quote_outlined, style: VgButtonStyle.soft, height: 36, onPressed: () => _push(InputHargaScreen(orderId: order.id)))
                      : VgButton(label: 'Buka Pesanan', icon: Icons.open_in_new_rounded, style: VgButtonStyle.soft, height: 36, onPressed: () => _push(DetailPesananScreen(orderId: order.id))),
                ]),
          onTap: n.relatedOrderId == null ? null : () => _push(DetailPesananScreen(orderId: n.relatedOrderId!)),
        ));
      }
    }

    for (final o in orders.orders) {
      if (o.statusHistory.isEmpty || o.latestProgress == 0) continue;
      final h = o.statusHistory.last;
      result.add(_Activity(
        key: 'h${h.id}',
        time: h.createdAt,
        cat: _Cat.produksi,
        icon: Icons.precision_manufacturing_outlined,
        title: 'Progres Produksi Diperbarui (${h.statusLabel} ${h.progressPercentage}%)',
        body: h.note?.isNotEmpty == true ? h.note! : '${o.customer.name} • ${o.headline}',
        extra: Column(children: [
          Row(children: [
            Expanded(child: Text('${o.customer.name} • ${o.totalQuantity} Stel', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
            Text('${h.progressPercentage}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: h.progressPercentage / 100, minHeight: 7, backgroundColor: AppColors.beige, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('Diperbarui oleh ${h.adminName ?? 'Admin'}', style: const TextStyle(fontSize: 12, color: AppColors.primary))),
            const Text('Lihat Detail', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ]),
        onTap: () => _push(DetailPesananScreen(orderId: o.id)),
      ));
    }

    for (final o in rentals) {
      final r = o.rental!;
      if (r.status != RentalStatus.dikembalikan || r.actualReturnDate == null) continue;
      final penalty = r.penaltyAmount ?? 0;
      result.add(_Activity(
        key: 'r${r.id}',
        time: r.actualReturnDate!,
        cat: _Cat.sewa,
        icon: Icons.fact_check_outlined,
        iconColor: AppColors.goldDark,
        iconBg: const Color(0xFFFFF4D6),
        title: penalty > 0 ? 'Inspeksi Pengembalian Dicatat: Ada Potongan' : 'Inspeksi Pengembalian Dicatat',
        body: r.damageNote ?? '${o.totalQuantity} stel ${o.headline} dari ${o.customer.name} kembali dalam kondisi baik.',
        extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            VgPill(label: 'Rental #${o.orderNumber}', color: AppColors.textPrimary, background: AppColors.beige, fontSize: 11),
            penalty > 0
                ? VgPill(label: 'Potongan ${Formatters.rupiah(penalty)}', color: AppColors.danger, background: AppColors.dangerBg, fontSize: 11)
                : const VgPill(label: 'Bebas Cacat', color: AppColors.success, background: AppColors.successBg, fontSize: 11),
          ]),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Buka Berita Acara ›', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
        onTap: () => _push(PenyewaanDetailScreen(orderId: o.id)),
      ));
    }

    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  String _catLabel(_Cat c) => switch (c) {
        _Cat.semua => 'Semua',
        _Cat.pesanan => 'Pesanan & Pembayaran',
        _Cat.sewa => 'Sewa & Pengembalian',
        _Cat.produksi => 'Produksi',
      };

  String _timeLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (day == today) {
      final diff = now.difference(t);
      if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(0, 59)}m lalu';
      return '${diff.inHours} jam lalu';
    }
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin, ${DateFormat('HH:mm').format(t)}';
    return DateFormat('d MMM, HH:mm', 'id_ID').format(t);
  }

  String _groupLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'HARI INI';
    if (day == today.subtract(const Duration(days: 1))) return 'KEMARIN';
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(day).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final admin = context.watch<AuthProvider>().currentAdmin;
    final rentals = context.watch<RentalProvider>().rentalOrders;
    final all = _build(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(const Duration(days: 6));
    final q = _query.trim().toLowerCase();
    final list = all.where((a) {
      if (_cat != _Cat.semua && a.cat != _cat) return false;
      if (_unreadOnly && !a.unread) return false;
      if (!_showArchive && a.time.isBefore(cutoff)) return false;
      return q.isEmpty || a.title.toLowerCase().contains(q) || a.body.toLowerCase().contains(q);
    }).toList();
    final hasArchive = all.any((a) => a.time.isBefore(cutoff));
    final newToday = all.where((a) => a.unread && !a.time.isBefore(today)).length;

    final dueToday = rentals.where((o) {
      final r = o.rental!;
      return r.status == RentalStatus.diambil && DateTime(r.returnDate.year, r.returnDate.month, r.returnDate.day) == today;
    }).toList();
    final late = rentals.where((o) => o.rental!.status == RentalStatus.terlambat).length;

    final groups = <DateTime, List<_Activity>>{};
    for (final a in list) {
      groups.putIfAbsent(DateTime(a.time.year, a.time.month, a.time.day), () => []).add(a);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                child: Row(children: [
                  if (Navigator.canPop(context)) const BackButton(color: AppColors.primary) else const SizedBox(width: 12),
                  const VgLogo(size: 36),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('VIEGUARD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text('Notifikasi & Log Aktivitas', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded, color: AppColors.primary, size: 26),
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) _query = '';
                    }),
                  ),
                  TapScale(onTap: () => _push(const AkunScreen()), child: VgAvatar(name: admin?.name ?? 'Admin')),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_searching) ...[
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(hintText: 'Cari aktivitas, pesanan, pelanggan…', prefixIcon: Icon(Icons.search_rounded)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _Cat.values.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final c = _Cat.values[i];
                        final selected = c == _cat;
                        final count = c == _Cat.semua ? all.length : all.where((a) => a.cat == c).length;
                        final unread = all.where((a) => a.unread && (c == _Cat.semua || a.cat == c)).length;
                        return TapScale(
                          onTap: () => setState(() => _cat = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.beige, borderRadius: BorderRadius.circular(10)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(c == _Cat.semua ? 'Semua ($count)' : _catLabel(c), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
                              if (c != _Cat.semua && unread > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(10)),
                                  child: Text('$unread', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.onGold)),
                                ),
                              ],
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('$newToday aktivitas baru hari ini', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
                    if (notifications.unreadCount > 0)
                      TapScale(
                        onTap: notifications.markAllAsRead,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                      ),
                    const SizedBox(width: 8),
                    TapScale(
                      onTap: () => setState(() => _unreadOnly = !_unreadOnly),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: _unreadOnly ? AppColors.primary : AppColors.beige, shape: BoxShape.circle),
                        child: Icon(Icons.tune_rounded, size: 18, color: _unreadOnly ? Colors.white : AppColors.primary),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (dueToday.isNotEmpty || late > 0) ...[
                    _DueBanner(orders: dueToday, late: late, onOpen: () => _push(const PenyewaanListScreen())),
                    const SizedBox(height: 20),
                  ],
                  if (notifications.isLoading && all.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                  else if (list.isEmpty)
                    VgCard(child: Text(_unreadOnly ? 'Tidak ada aktivitas yang belum dibaca.' : 'Belum ada aktivitas pada kategori ini.', style: const TextStyle(color: AppColors.textSecondary)))
                  else
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Container(width: 4, height: 16, decoration: BoxDecoration(color: entry.key == today ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_groupLabel(entry.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.6))),
                          Text('${entry.value.length} Aktivitas', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                        ]),
                      ),
                      for (final a in entry.value)
                        _ActivityCard(
                          activity: a,
                          timeLabel: _timeLabel(a.time),
                          onTap: () {
                            if (a.notificationId != null) notifications.markAsRead(a.notificationId!);
                            a.onTap?.call();
                          },
                        ),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 10),
                  Center(
                    child: Column(children: [
                      const VgIconBadge(icon: Icons.history_rounded, size: 32, circle: true),
                      const SizedBox(height: 10),
                      Text(_showArchive ? 'Menampilkan seluruh riwayat aktivitas' : 'Menampilkan riwayat aktivitas 7 hari terakhir', style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
                      if (hasArchive)
                        TextButton(
                          onPressed: () => setState(() => _showArchive = !_showArchive),
                          child: Text(_showArchive ? 'Sembunyikan Arsip' : 'Muat Arsip Log Lebih Lama', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  final List<Order> orders;
  final int late;
  final VoidCallback onOpen;
  const _DueBanner({required this.orders, required this.late, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final names = orders.map((o) => o.customer.name).take(3).join(', ');
    final title = orders.isNotEmpty ? 'Pengembalian Kostum Jatuh Tempo Hari Ini!' : 'Ada Sewa yang Terlambat Dikembalikan';
    final body = [
      if (orders.isNotEmpty) '${orders.length} rental dijadwalkan kembali hari ini ($names${orders.length > 3 ? ', …' : ''}).',
      if (late > 0) '$late rental melewati batas pengembalian.',
    ].join(' ');
    return TapScale(
      scaleDown: 0.98,
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1C7),
          borderRadius: BorderRadius.circular(12),
          border: const Border(left: BorderSide(color: Color(0xFFF59E0B), width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const VgIconBadge(icon: Icons.alarm_rounded, color: Color(0xFFF59E0B), background: AppColors.surface, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('JATUH TEMPO HARI INI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldDark, letterSpacing: 0.6))),
                if (late > 0) VgPill(label: '$late Terlambat', color: AppColors.danger, background: AppColors.surface, fontSize: 10.5),
              ]),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45)),
              const SizedBox(height: 10),
              const Wrap(spacing: 12, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Buka Jadwal Rental', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.textPrimary),
                ]),
                Text('• Prioritas Tinggi', style: TextStyle(fontSize: 12, color: AppColors.goldDark)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _Activity activity;
  final String timeLabel;
  final VoidCallback onTap;

  const _ActivityCard({required this.activity, required this.timeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return VgCard(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [
          VgIconBadge(icon: activity.icon, color: activity.iconColor, background: activity.iconBg, size: 42),
          if (activity.unread)
            Positioned(
              right: -3,
              top: -3,
              child: Container(width: 11, height: 11, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2))),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(activity.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3))),
              const SizedBox(width: 8),
              Text(timeLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 4),
            Text(activity.body, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
            if (activity.extra != null) ...[const SizedBox(height: 10), activity.extra!],
          ]),
        ),
      ]),
    );
  }
}
