import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../models/payment_model.dart';
import '../../state/auth_provider.dart';
import '../../state/order_provider.dart';
import '../../state/payment_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

class PaymentVerificationDetailScreen extends StatefulWidget {
  final String paymentId;
  const PaymentVerificationDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentVerificationDetailScreen> createState() => _PaymentVerificationDetailScreenState();
}

class _PaymentVerificationDetailScreenState extends State<PaymentVerificationDetailScreen> {
  final _checks = [false, false, false];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final payment = _payment(context.read<PaymentProvider>());
      if (payment != null) context.read<OrderProvider>().fetchOrderDetail(payment.orderId);
    });
  }

  Payment? _payment(PaymentProvider provider) {
    final matches = provider.payments.where((p) => p.id == widget.paymentId);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _verify(bool approve, {String? reason}) async {
    final provider = context.read<PaymentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? pin;
    if (approve) {
      final (proceed, entered) = await requirePin(context);
      if (!proceed || !mounted) return;
      pin = entered;
    }
    setState(() => _submitting = true);
    final ok = await provider.verifyPayment(widget.paymentId, approve: approve, refundReason: reason, pin: pin);
    if (!mounted) return;
    setState(() => _submitting = false);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? (approve ? 'Pembayaran diverifikasi.' : 'Bukti pembayaran ditolak.') : provider.errorMessage ?? 'Gagal memproses pembayaran.'),
    ));
    if (ok) navigator.pop();
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Tolak Bukti Transfer'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Alasan penolakan / hal yang perlu dikonfirmasi ulang')),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(children: [
            Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 10),
            Expanded(child: VgButton(label: 'Tolak', style: VgButtonStyle.maroon, onPressed: () => Navigator.pop(ctx, true))),
          ]),
        ],
      ),
    );
    if (ok == true && mounted) await _verify(false, reason: controller.text.trim());
  }

  void _zoom(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(children: [
          InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
          Positioned(right: 4, top: 4, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment(context.watch<PaymentProvider>());
    if (payment == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Verifikasi Pembayaran'), body: Center(child: Text('Pembayaran tidak ditemukan.')));
    }
    final order = context.watch<OrderProvider>().orderById(payment.orderId);
    final admin = context.watch<AuthProvider>().currentAdmin;
    final pending = payment.status == PaymentStatus.menunggu;
    final isDp = payment.paymentType == 'dp';

    final total = order?.totalPrice ?? payment.orderTotalPrice ?? 0;
    final otherVerified = order?.payments.where((p) => p.id != payment.id && p.status == PaymentStatus.terverifikasi).toList() ?? [];
    final paidBefore = otherVerified.fold<double>(0, (s, p) => s + p.amount);
    final expected = isDp ? (order?.dpAmount ?? total / 2) : (total - paidBefore).clamp(0, double.infinity).toDouble();
    final difference = payment.amount - expected;
    final matched = difference.abs() < 1;
    final checkedCount = _checks.where((c) => c).length;

    final checkItems = [
      ('Nominal transfer sesuai tagihan', '${Formatters.rupiah(payment.amount)} dibanding tagihan ${Formatters.rupiah(expected)}.'),
      ('Mutasi rekening admin telah dicek', 'Dana efektif masuk tanpa status tertahan / pending kliring.'),
      ('Data pesanan & kontak pelanggan terkonfirmasi', '${payment.customerName ?? 'Pelanggan'} siap menerima kelanjutan pesanan.'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Verifikasi Pembayaran'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            const VgIconBadge(icon: Icons.shield_outlined, size: 26, circle: true),
            const SizedBox(width: 8),
            const Expanded(child: Text('AUDIT PEMBAYARAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.8))),
            VgPill(label: 'Order #${payment.orderNumber ?? '-'}', color: AppColors.primary, background: AppColors.beige, fontSize: 10.5),
          ]),
          const SizedBox(height: 6),
          const Text('Harap teliti pencocokan mutasi bank sebelum menyetujui pembayaran pelanggan.', style: TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.4)),
          const SizedBox(height: 14),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: VgPill(
                    label: pending ? 'MENUNGGU VERIFIKASI ADMIN' : payment.status.label.toUpperCase(),
                    color: payment.status.color,
                    background: payment.status.background,
                    dot: true,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(isDp ? 'Termin DP' : 'Pelunasan', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 10),
              Text(payment.customerName ?? '-', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (order != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.checkroom_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Expanded(child: Text('${order.headline} (${order.totalQuantity} Stel)', style: const TextStyle(fontSize: 13, color: AppColors.primary))),
                ]),
                const SizedBox(height: 12),
                _ProductionStatus(order: order),
              ],
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Rincian Tagihan & Pelunasan',
                trailing: VgPill(label: isDp ? 'Termin 1 / 2' : 'Termin 2 / 2', color: AppColors.primary, background: AppColors.beige),
              ),
              _Line(label: 'Total Nilai Pesanan', value: Formatters.rupiah(total)),
              for (final p in otherVerified)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VgInset(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${p.paymentType == 'dp' ? 'Pembayaran DP' : 'Pembayaran'} (${Formatters.date(p.createdAt)})', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                          Row(children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Flexible(child: Text('Terverifikasi${p.paymentMethod != null ? ' ${p.paymentMethod}' : ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.success))),
                          ]),
                        ]),
                      ),
                      Text('- ${Formatters.rupiah(p.amount)}', style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              _Line(label: isDp ? 'Tagihan DP' : 'Sisa Tagihan', value: Formatters.rupiah(expected)),
              const SizedBox(height: 4),
              VgInset(
                child: Row(children: [
                  Expanded(
                    child: Text(isDp ? 'Nominal DP Ditagihkan' : 'Total Pelunasan Ditagihkan', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                  Text(Formatters.rupiah(expected), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Bukti Transfer Pelanggan',
                trailing: VgPill(
                  label: matched ? 'Match 100%' : 'Selisih ${Formatters.rupiah(difference.abs())}',
                  color: matched ? AppColors.success : AppColors.warning,
                  background: matched ? AppColors.successBg : AppColors.warningBg,
                  icon: matched ? Icons.check_circle_outline_rounded : Icons.error_outline,
                  fontSize: 10.5,
                ),
              ),
              VgInset(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _Line(label: 'Metode Pembayaran', value: payment.paymentMethod ?? '-', small: true),
                  _Line(label: 'Waktu Transaksi', value: '${Formatters.dateTime(payment.createdAt)} WIB', small: true),
                  _Line(label: 'Jenis', value: isDp ? 'Uang Muka (DP)' : 'Pelunasan', small: true),
                  Row(children: [
                    const Expanded(child: Text('Nominal Tertera', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
                    Text(Formatters.rupiah(payment.amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: matched ? AppColors.success : AppColors.warning)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              VgInset(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: payment.proofImage == null
                          ? Container(
                              color: AppColors.surface,
                              alignment: Alignment.center,
                              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primary),
                                SizedBox(height: 6),
                                Text('Bukti transfer tidak dilampirkan', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                              ]),
                            )
                          : Image.network(payment.proofImage!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surface, child: const Icon(Icons.broken_image_outlined, color: AppColors.primary))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Expanded(child: Text('Jumlah Ditransfer', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
                    Text(Formatters.rupiah(payment.amount), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ]),
                  if (payment.proofImage != null) ...[
                    const SizedBox(height: 12),
                    VgButton(
                      label: 'Perbesar Bukti Transfer Asli',
                      icon: Icons.zoom_in_rounded,
                      style: VgButtonStyle.outline,
                      expanded: true,
                      height: 42,
                      onPressed: () => _zoom(payment.proofImage!),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
          if (pending)
            VgCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VgCardTitle(
                  title: 'Audit Kepatuhan & Validasi',
                  trailing: VgPill(
                    label: '$checkedCount/3 Lengkap',
                    color: checkedCount == 3 ? AppColors.success : AppColors.goldDark,
                    background: checkedCount == 3 ? AppColors.successBg : AppColors.warningBg,
                    fontSize: 10.5,
                  ),
                ),
                const Text('Pastikan ketiga butir di bawah telah dicek secara cermat sebelum menyetujui pembayaran.', style: TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.4)),
                const SizedBox(height: 10),
                for (var i = 0; i < checkItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TapScale(
                      onTap: () => setState(() => _checks[i] = !_checks[i]),
                      child: VgInset(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: _checks[i] ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: _checks[i] ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(checkItems[i].$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(checkItems[i].$2, style: const TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.35)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ]),
            )
          else
            VgCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const VgCardTitle(title: 'Riwayat Audit'),
                _Line(label: 'Diaudit oleh', value: payment.verifierName ?? '-'),
                if (payment.verifiedAt != null) _Line(label: 'Waktu audit', value: Formatters.dateTime(payment.verifiedAt!)),
                if (payment.refundReason != null) _Line(label: 'Alasan penolakan', value: payment.refundReason!),
              ]),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Aksi ini akan dicatat dalam Audit Trail Admin VIEGUARD (${admin?.name ?? 'Admin'}).', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: pending
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _GreenButton(
                    label: 'Verifikasi & Setujui Pembayaran',
                    loading: _submitting,
                    onPressed: checkedCount == 3 ? () => _verify(true) : null,
                  ),
                  const SizedBox(height: 10),
                  VgButton(label: 'Tolak Bukti / Minta Konfirmasi Ulang', icon: Icons.flag_outlined, style: VgButtonStyle.soft, expanded: true, height: 42, onPressed: _submitting ? null : _reject),
                ]),
              ),
            )
          : null,
    );
  }
}

class _ProductionStatus extends StatelessWidget {
  final Order order;
  const _ProductionStatus({required this.order});

  @override
  Widget build(BuildContext context) {
    final ready = order.status == OrderStatus.siapDiambil || order.status == OrderStatus.selesai;
    return VgInset(
      child: Row(children: [
        Icon(ready ? Icons.local_shipping_outlined : Icons.precision_manufacturing_outlined, size: 22, color: ready ? AppColors.success : AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Status Produksi', style: TextStyle(fontSize: 11.5, color: AppColors.primary)),
            Text(
              order.requiresProduction ? 'Progres ${order.latestProgress}% • ${order.status.label}' : order.status.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ]),
        ),
        if (ready) const VgPill(label: 'QC Passed', color: AppColors.success, background: AppColors.surface, fontSize: 10.5),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool small;
  const _Line({required this.label, required this.value, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: small ? 8 : 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: small ? 12.5 : 13.5, color: AppColors.primary))),
        const SizedBox(width: 10),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: small ? 12.5 : 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]),
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const _GreenButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: TapScale(
        onTap: disabled || loading ? null : onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF2E7D4F), borderRadius: BorderRadius.circular(14)),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                ]),
        ),
      ),
    );
  }
}
