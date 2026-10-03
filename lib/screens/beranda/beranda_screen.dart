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
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../penyewaan/penyewaan_list_screen.dart';
import '../pesanan/detail_pesanan_screen.dart';
import '../pesanan/pesanan_list_screen.dart';
import '../stok/product_form_screen.dart';
import '../stok/stok_list_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final products = context.read<ProductProvider>();
    await Future.wait([
      context.read<OrderProvider>().fetchOrders(),
      context.read<RentalProvider>().fetchRentals(),
      context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu),
      context.read<NotificationProvider>().fetchNotifications(),
      if (products.products.isEmpty) products.fetchAll(),
    ]);
    if (mounted) setState(() => _lastUpdated = DateTime.now());
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final rentals = context.watch<RentalProvider>();
    final products = context.watch<ProductProvider>();
    final admin = context.watch<AuthProvider>().currentAdmin;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final schedule = rentals.rentalOrders.where((o) => day(o.rental!.pickupDate) == today || day(o.rental!.returnDate) == today).toList();
    final activeRentals = rentals.rentalOrders.where((o) => o.rental!.status == RentalStatus.diambil || o.rental!.status == RentalStatus.terlambat).toList();
    final activeModels = activeRentals.expand((o) => o.items.map((i) => i.name)).toSet().length;
    final rentedUnits = activeRentals.fold<int>(0, (sum, o) => sum + o.totalQuantity);
    final bookedRentals = rentals.rentalOrders.where((o) => o.rental!.status != RentalStatus.dikembalikan).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 68,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: const VgTopBar(subtitle: 'Beranda'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeBanner(adminName: admin?.name ?? 'Admin'),
                  const SizedBox(height: 26),
                  VgSectionHeader(
                    title: 'Ringkasan Hari Ini',
                    trailing: _lastUpdated == null
                        ? null
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('Update ${DateFormat('HH:mm').format(_lastUpdated!)}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ]),
                  ),
                  _Ringkasan(
                    pesananBaru: orders.perluTindakanCount,
                    kostumDisewa: rentedUnits,
                    modelDisewa: activeModels,
                    progres: orders.progresProduksiRata,
                    omset: orders.omsetTotal,
                    onPesanan: () => _push(const PesananListScreen()),
                    onSewa: () => _push(const PenyewaanListScreen()),
                  ),
                  const SizedBox(height: 26),
                  const VgSectionHeader(title: 'Kelola Barang'),
                  Row(children: [
                    Expanded(
                      child: _KelolaTile(
                        icon: Icons.checkroom_rounded,
                        title: 'Kelola Barang',
                        subtitle: '${products.products.length} Item',
                        onTap: () => _push(const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Manajemen Stok'), body: StokListScreen())),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KelolaTile(
                        icon: Icons.event_available_rounded,
                        title: 'Kelola Sewaan',
                        subtitle: '$bookedRentals Aktif',
                        onTap: () => _push(const PenyewaanListScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KelolaTile(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Tambah Barang',
                        subtitle: 'Baru / Custom',
                        highlighted: true,
                        onTap: () => _push(const ProductFormScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  VgSectionHeader(
                    title: 'Jadwal Rental Hari Ini',
                    icon: Icons.calendar_month_rounded,
                    actionLabel: 'Lihat Semua',
                    onAction: () => _push(const PenyewaanListScreen()),
                  ),
                  if (schedule.isEmpty)
                    const VgCard(
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Text('Tidak ada jadwal pengambilan atau pengembalian hari ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    )
                  else
                    ...schedule.map((o) => _JadwalTile(order: o, today: today)),
                  const SizedBox(height: 16),
                  VgSectionHeader(
                    title: 'Pesanan Terbaru',
                    badge: orders.perluTindakanCount > 0
                        ? VgPill(label: '${orders.perluTindakanCount} Perlu Tindakan', color: AppColors.warning, background: AppColors.warningBg, fontSize: 10.5)
                        : null,
                    actionLabel: 'Semua',
                    onAction: () => _push(const PesananListScreen()),
                  ),
                  if (orders.isLoading && orders.orders.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                  else if (orders.errorMessage != null && orders.orders.isEmpty)
                    VgCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(orders.errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                        const SizedBox(height: 10),
                        VgButton(label: 'Coba Lagi', icon: Icons.refresh, style: VgButtonStyle.soft, onPressed: _refresh, height: 42),
                      ]),
                    )
                  else if (orders.orders.isEmpty)
                    const VgCard(child: Text('Belum ada pesanan.', style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ...orders.pesananTerbaru.map((o) => _RecentOrderCard(order: o, onTap: () => _push(DetailPesananScreen(orderId: o.id)))),
                ]),
              ),
            ),
          ],
        ),
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
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(
          right: -50,
          top: -60,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0)]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.8))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now()), style: const TextStyle(fontSize: 11.5, color: AppColors.goldLight, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            Text('Selamat Datang, $adminName', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.goldLight, height: 1.25)),
            const SizedBox(height: 6),
            const Text('Pantau konveksi seragam & rental kostum hari ini.', style: TextStyle(fontSize: 13, color: AppColors.onPrimaryMuted, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class _Ringkasan extends StatelessWidget {
  final int pesananBaru;
  final int kostumDisewa;
  final int modelDisewa;
  final double progres;
  final double omset;
  final VoidCallback onPesanan;
  final VoidCallback onSewa;

  const _Ringkasan({
    required this.pesananBaru,
    required this.kostumDisewa,
    required this.modelDisewa,
    required this.progres,
    required this.omset,
    required this.onPesanan,
    required this.onSewa,
  });

  static BoxDecoration get _box => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      );

  @override
  Widget build(BuildContext context) {
    final percent = (progres * 100).round();
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 9,
          child: TapScale(
            onTap: onPesanan,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _box,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Expanded(child: Text('Pesanan Baru', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  VgIconBadge(icon: Icons.receipt_long_rounded, size: 28, color: AppColors.info, background: AppColors.infoBg, circle: true),
                ]),
                const Spacer(),
                Text('$pesananBaru', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1)),
                const SizedBox(height: 8),
                const Text('Pesanan saat ini', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 13,
          child: Column(children: [
            TapScale(
              onTap: onSewa,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: _box,
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Kostum Disewa', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text('$kostumDisewa', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const SizedBox(width: 6),
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Flexible(child: Text('$modelDisewa Model saat ini', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary))),
                      ]),
                    ]),
                  ),
                  const VgIconBadge(icon: Icons.checkroom_rounded, size: 30, color: AppColors.info, background: AppColors.infoBg, circle: true),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: _box,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('Progres Produksi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progres.clamp(0, 1), minHeight: 7, backgroundColor: AppColors.beige, color: AppColors.gold),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: _box,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Omset Berjalan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(Formatters.rupiahCompact(omset), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _KelolaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _KelolaTile({required this.icon, required this.title, required this.subtitle, this.highlighted = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: highlighted ? null : AppColors.surface,
          gradient: highlighted ? AppColors.maroonGradient : null,
          borderRadius: BorderRadius.circular(18),
          border: highlighted ? null : Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          highlighted
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                )
              : VgIconBadge(icon: icon, size: 40, background: AppColors.beigeSoft, circle: true),
          const SizedBox(height: 10),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlighted ? AppColors.goldLight : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: highlighted ? AppColors.onPrimaryMuted : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _JadwalTile extends StatelessWidget {
  final Order order;
  final DateTime today;
  const _JadwalTile({required this.order, required this.today});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final pickup = DateTime(rental.pickupDate.year, rental.pickupDate.month, rental.pickupDate.day);
    final isPickup = pickup == today;
    final label = isPickup ? 'Pengambilan' : 'Pengembalian';
    final date = isPickup ? rental.pickupDate : rental.returnDate;

    String chip;
    Color fg;
    Color bg;
    if (rental.status == RentalStatus.dikembalikan) {
      chip = 'Pengecekan';
      fg = AppColors.warning;
      bg = AppColors.warningBg;
    } else if (isPickup) {
      chip = 'Siap Ambil';
      fg = AppColors.success;
      bg = AppColors.successBg;
    } else {
      chip = 'Pengembalian';
      fg = AppColors.primary;
      bg = AppColors.dangerBg;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        SizedBox(
          width: 62,
          child: Column(children: [
            Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
            Text(DateFormat('MMM', 'id_ID').format(date).toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ),
        Container(width: 1, height: 32, color: AppColors.border),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('$label • ${order.totalQuantity} ${order.headline}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 8),
        VgPill(label: chip, color: fg, background: bg, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      ]),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _RecentOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pending = order.status == OrderStatus.pending;
    return VgCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          OrderStatusPill(order: order),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          VgThumb(url: order.coverImage, size: 64, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
                Text(order.customer.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                VgPill(label: order.orderType.label, color: AppColors.info, background: AppColors.infoBg, fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
              ]),
              const SizedBox(height: 4),
              Text('${order.headline} (${order.totalQuantity} Stel)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                order.needsQuote ? 'Belum Ditentukan' : Formatters.rupiah(order.totalPrice),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        VgButton(
          label: pending ? 'Lihat Detail & Konfirmasi' : 'Lihat Detail',
          icon: pending ? Icons.arrow_forward_rounded : null,
          trailingIcon: true,
          style: pending ? VgButtonStyle.gold : VgButtonStyle.outline,
          expanded: true,
          height: 44,
          onPressed: onTap,
        ),
      ]),
    );
  }
}
