import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_status.dart';
import '../../state/auth_provider.dart';
import '../../state/notification_provider.dart';
import '../../state/order_provider.dart';
import '../../state/payment_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../laporan/laporan_screen.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../pembayaran/payment_verification_list_screen.dart';
import '../stok/stok_list_screen.dart';
import 'security_screen.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
      final rentals = context.read<RentalProvider>();
      if (rentals.rentalOrders.isEmpty) rentals.fetchRentals();
    });
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<bool?> _formDialog({required String title, required List<Widget> fields, required String action}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title),
        content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: fields)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(children: [
            Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 10),
            Expanded(child: VgButton(label: action, onPressed: () => Navigator.pop(ctx, true))),
          ]),
        ],
      ),
    );
  }

  Future<void> _editProfile(AuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.currentAdmin?.name);
    final phoneCtrl = TextEditingController(text: auth.currentAdmin?.phone);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _formDialog(title: 'Edit Profil', action: 'Simpan', fields: [
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', isDense: true)),
      const SizedBox(height: 14),
      TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', isDense: true)),
    ]);
    if (ok != true) return;
    final success = await auth.updateProfile(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim());
    messenger.showSnackBar(SnackBar(content: Text(success ? 'Profil diperbarui.' : auth.errorMessage ?? 'Gagal memperbarui profil.')));
  }

  Future<void> _logout(AuthProvider auth) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda perlu login kembali untuk mengelola pesanan dan penyewaan.'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(children: [
            Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 10),
            Expanded(child: VgButton(label: 'Keluar', onPressed: () => Navigator.pop(ctx, true))),
          ]),
        ],
      ),
    );
    if (ok != true) return;
    navigator.popUntil((route) => route.isFirst);
    await auth.logout();
  }

  String _roleLabel(String role) => switch (role.toLowerCase()) {
        'owner' => 'Owner & Super Administrator',
        'admin' => 'Operations Administrator',
        _ => role.toUpperCase(),
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = auth.currentAdmin;
    final orders = context.watch<OrderProvider>().orders;
    final rentals = context.watch<RentalProvider>().rentalOrders;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final pendingPayments = context.watch<PaymentProvider>().payments.where((p) => p.status == PaymentStatus.menunggu).length;
    final completed = orders.where((o) => o.status == OrderStatus.selesai).length;
    final activeRentals = rentals.where((o) => o.rental!.status == RentalStatus.diambil || o.rental!.status == RentalStatus.terlambat).length;
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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
                  Text('Akun Admin', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              TapScale(
                onTap: () => _push(const NotifikasiScreen()),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(alignment: Alignment.center, children: [
                    const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
                    if (unread > 0)
                      Positioned(top: 9, right: 10, child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle))),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: 84,
                    decoration: const BoxDecoration(gradient: AppColors.maroonGradient),
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
                    alignment: Alignment.topLeft,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      VgPill(label: 'Sesi Terverifikasi', color: Colors.white, background: Colors.white.withValues(alpha: 0.15), dot: true, fontSize: 11),
                      const Spacer(),
                      TapScale(
                        onTap: () => _editProfile(auth),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.edit_outlined, size: 17, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                  Positioned(
                    left: 16,
                    top: 44,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: VgAvatar(name: admin?.name ?? 'Admin', size: 72),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF22A447)),
                        ),
                      ),
                    ]),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: VgPill(label: _roleLabel(admin?.role ?? 'admin'), color: AppColors.textPrimary, background: AppColors.beige, fontSize: 11.5),
                    ),
                    const SizedBox(height: 14),
                    Text(admin?.name ?? '-', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      ['Admin ID: ${admin?.id ?? '-'}', ?admin?.email, ?admin?.phone].join(' • '),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    VgInset(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(children: [
                        _Stat(value: '$completed', label: 'Pesanan\nSelesai'),
                        _Stat(value: '$activeRentals', label: 'Sewa\nAktif'),
                        _Stat(value: '$pending', label: 'Perlu\nTindakan', highlight: pending > 0),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(title: 'OPERASIONAL & BISNIS', trailing: '4 Modul'),
            _MenuCard(icon: Icons.bar_chart_rounded, title: 'Laporan & Analitik Bisnis', onTap: () => _push(const LaporanScreen())),
            _MenuCard(
              icon: Icons.warehouse_outlined,
              title: 'Manajemen Stok & Gudang',
              onTap: () => _push(Scaffold(backgroundColor: AppColors.background, appBar: const VgBackBar(title: 'Manajemen Stok'), body: const StokListScreen())),
            ),
            _MenuCard(
              icon: Icons.fact_check_outlined,
              title: 'Verifikasi Pembayaran',
              badge: pendingPayments > 0 ? '$pendingPayments Menunggu' : null,
              onTap: () => _push(const PaymentVerificationListScreen()),
            ),
            _MenuCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notifikasi & Log Aktivitas',
              badge: unread > 0 ? '$unread Baru' : null,
              onTap: () => _push(const NotifikasiScreen()),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(title: 'PENGATURAN & KEAMANAN', trailing: 'Akun Admin'),
            _MenuCard(icon: Icons.manage_accounts_outlined, title: 'Edit Profil Admin', onTap: () => _editProfile(auth)),
            _MenuCard(icon: Icons.shield_outlined, title: 'Keamanan Akun & PIN', onTap: () => _push(const SecurityScreen())),
            const SizedBox(height: 16),
            TapScale(
              onTap: () => _logout(auth),
              child: Container(
                height: 52,
                decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Keluar dari Akun Admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('VIEGUARD Admin', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            const SizedBox(height: 2),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.primary),
              SizedBox(width: 4),
              Flexible(child: Text('Sesi login dilindungi token terenkripsi', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.primary))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _Stat({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: highlight ? AppColors.goldDark : AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.25)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String trailing;
  const _SectionLabel({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.6))),
        Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      ]),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  const _MenuCard({required this.icon, required this.title, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return VgCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        VgIconBadge(icon: icon, size: 44),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        if (badge != null) ...[
          VgPill(label: badge!, color: AppColors.goldDark, background: const Color(0xFFFFF1C7), dot: true, fontSize: 11),
          const SizedBox(width: 6),
        ],
        const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
      ]),
    );
  }
}
