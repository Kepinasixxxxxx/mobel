import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/pesanan/pesanan_order_card.dart';
import '../akun/akun_screen.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../pembayaran/payment_verification_list_screen.dart';
import '../penyewaan/penyewaan_list_screen.dart';
import '../pesanan/detail_pesanan_screen.dart';
import '../pesanan/pesanan_list_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrderProvider>().fetchOrders();
      context.read<RentalProvider>().fetchRentals();
      context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu);
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<OrderProvider>().fetchOrders(),
      context.read<RentalProvider>().fetchRentals(),
      context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu),
      context.read<NotificationProvider>().fetchNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final rentalProvider = context.watch<RentalProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final admin = context.watch<AuthProvider>().currentAdmin;
    final notificationProvider = context.watch<NotificationProvider>();

    final todaySchedule = rentalProvider.rentalOrders.where((o) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickup = DateTime(o.rental!.pickupDate.year, o.rental!.pickupDate.month, o.rental!.pickupDate.day);
      final ret = DateTime(o.rental!.returnDate.year, o.rental!.returnDate.month, o.rental!.returnDate.day);
      return pickup == today || ret == today;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: const Text('V', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VIEGUARD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                      Text('Beranda', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                    ),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${notificationProvider.unreadCount}', style: const TextStyle(color: AppColors.onPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 4),
                  child: TapScale(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunScreen())),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (admin?.name.isNotEmpty == true ? admin!.name[0] : 'A').toUpperCase(),
                        style: const TextStyle(color: AppColors.onPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeBanner(adminName: admin?.name ?? 'Admin'),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Ringkasan Hari Ini'),
                  const SizedBox(height: 10),
                  _RingkasanGrid(orderProvider: orderProvider),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Kelola Barang'),
                  const SizedBox(height: 10),
                  _KelolaBarangGrid(pendingPayments: paymentProvider.payments.length),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Jadwal Sewa Hari Ini',
                    actionLabel: 'Lihat Semua',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenyewaanListScreen())),
                  ),
                  const SizedBox(height: 10),
                  if (todaySchedule.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Tidak ada jadwal ambil/kembali hari ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    )
                  else
                    ...todaySchedule.map((o) => _JadwalTile(order: o)),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Pesanan Terbaru',
                    trailingBadge: TagChip(label: '${orderProvider.perluTindakanCount} Perlu Tindakan', color: AppColors.warning, background: AppColors.warningBg),
                    actionLabel: 'Semua',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PesananListScreen())),
                  ),
                  const SizedBox(height: 10),
                  if (orderProvider.isLoading && orderProvider.orders.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                  else if (orderProvider.errorMessage != null && orderProvider.orders.isEmpty)
                    _ErrorNotice(message: orderProvider.errorMessage!, onRetry: _refresh)
                  else if (orderProvider.orders.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Belum ada pesanan.', style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ...orderProvider.pesananTerbaru.map(
                      (o) => PesananOrderCard(
                        order: o,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesananScreen(orderId: o.id))),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Gagal memuat data dari server', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String adminName;
  const _WelcomeBanner({required this.adminName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.maroon.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.08)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(Formatters.dayDate(DateTime.now()), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 14),
              Text('Selamat Datang,', style: GoogleFonts.greatVibes(fontSize: 26, color: AppColors.primary)),
              Text(adminName, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Pantau konveksi seragam & rental kostum hari ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingkasanGrid extends StatelessWidget {
  final OrderProvider orderProvider;
  const _RingkasanGrid({required this.orderProvider});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatCard(icon: Icons.assignment_outlined, label: 'Pesanan Baru', value: '${orderProvider.countByStatus(OrderStatus.pending)}', caption: 'Menunggu konfirmasi'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Sedang Disewa', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Icon(Icons.checkroom, size: 18, color: AppColors.primary),
                ]),
                const SizedBox(height: 4),
                Text('${orderProvider.countByType(OrderType.sewa)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Text('Total pesanan sewa', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Progres Produksi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('${(orderProvider.progresProduksiRata * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: orderProvider.progresProduksiRata, minHeight: 6, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.info)),
                ),
                const SizedBox(height: 10),
                const Text('Omset Aktif', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(Formatters.rupiahCompact(orderProvider.omsetTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _StatCard({required this.icon, required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final needsAction = int.tryParse(value) != null && int.parse(value) > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Icon(icon, size: 18, color: AppColors.primary),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(caption, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: needsAction ? AppColors.warningBg : AppColors.successBg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              needsAction ? 'Perlu ditindaklanjuti' : 'Semua sudah ditangani',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: needsAction ? AppColors.warning : AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _KelolaBarangGrid extends StatelessWidget {
  final int pendingPayments;
  const _KelolaBarangGrid({required this.pendingPayments});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KelolaTile(
            icon: Icons.fact_check_outlined,
            title: 'Verifikasi\nPembayaran',
            badge: pendingPayments > 0 ? '$pendingPayments' : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentVerificationListScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KelolaTile(
            icon: Icons.key_outlined,
            title: 'Penyewaan\nAktif',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenyewaanListScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KelolaTile(
            icon: Icons.receipt_long_outlined,
            title: 'Semua\nPesanan',
            highlighted: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PesananListScreen())),
          ),
        ),
      ],
    );
  }
}

class _KelolaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final bool highlighted;
  final VoidCallback onTap;

  const _KelolaTile({required this.icon, required this.title, this.badge, this.highlighted = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: highlighted ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: highlighted ? AppColors.onPrimary : AppColors.primary, size: 24),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Text(badge!, style: const TextStyle(color: AppColors.onPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: highlighted ? AppColors.onPrimary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _JadwalTile extends StatelessWidget {
  final Order order;
  const _JadwalTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPickupToday = DateTime(rental.pickupDate.year, rental.pickupDate.month, rental.pickupDate.day) == today;
    final label = isPickupToday ? 'Pengambilan' : 'Pengembalian';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(isPickupToday ? Icons.outbound : Icons.assignment_return_outlined, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('$label · #${order.orderNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          RentalStatusBadge(status: rental.status),
        ],
      ),
    );
  }
}
