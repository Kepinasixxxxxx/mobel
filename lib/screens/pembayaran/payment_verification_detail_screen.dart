import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/payment_model.dart';
import '../../state/payment_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/remote_image_tile.dart';
import '../../widgets/common/status_badge.dart';

class PaymentVerificationDetailScreen extends StatefulWidget {
  final String paymentId;
  const PaymentVerificationDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentVerificationDetailScreen> createState() => _PaymentVerificationDetailScreenState();
}

class _PaymentVerificationDetailScreenState extends State<PaymentVerificationDetailScreen> {
  bool _nominalChecked = false;
  bool _mutasiChecked = false;
  bool _dataChecked = false;
  bool _submitting = false;

  bool get _allChecked => _nominalChecked && _mutasiChecked && _dataChecked;

  Future<void> _approve() async {
    setState(() => _submitting = true);
    final ok = await context.read<PaymentProvider>().verifyPayment(widget.paymentId, approve: true);
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pembayaran diverifikasi.' : context.read<PaymentProvider>().errorMessage ?? 'Gagal verifikasi.')));
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Bukti Pembayaran'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Alasan penolakan')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Tolak')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final ok = await context.read<PaymentProvider>().verifyPayment(widget.paymentId, approve: false, refundReason: controller.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Bukti pembayaran ditolak.' : context.read<PaymentProvider>().errorMessage ?? 'Gagal menolak.')));
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final matches = provider.payments.where((p) => p.id == widget.paymentId);
    if (matches.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final Payment payment = matches.first;
    final isPending = payment.status.name == 'menunggu';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Audit Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            const TagChip(label: 'AUDIT PEMBAYARAN', color: AppColors.primary, background: AppColors.infoBg),
            const Spacer(),
            PaymentStatusBadge(status: payment.status),
          ]),
          const SizedBox(height: 10),
          Text(payment.customerName ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Order #${payment.orderNumber ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Rincian Tagihan',
            trailingIcon: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            children: [
              InfoTile(label: 'Jenis Pembayaran', value: payment.paymentType == 'dp' ? 'Uang Muka (DP)' : payment.paymentType == 'pelunasan' ? 'Pelunasan' : 'Refund'),
              InfoTile(label: 'Nominal Ditransfer', value: Formatters.rupiah(payment.amount)),
              if (payment.orderTotalPrice != null) InfoTile(label: 'Total Tagihan Pesanan', value: Formatters.rupiah(payment.orderTotalPrice!)),
              InfoTile(label: 'Metode', value: payment.paymentMethod ?? '-'),
              InfoTile(label: 'Waktu Transaksi', value: Formatters.dateTime(payment.createdAt)),
            ],
          ),
          SectionCard(
            title: 'Bukti Transfer Pelanggan',
            trailingIcon: const Icon(Icons.image_outlined, color: AppColors.primary),
            children: [
              RemoteImageTile(url: payment.proofImage, label: 'Bukti Transfer', height: 200),
            ],
          ),
          if (isPending)
            SectionCard(
              title: 'Audit Kepatuhan & Validasi',
              subtitle: 'Pastikan ketiga butir berikut dicek sebelum menyetujui',
              children: [
                _AuditCheckbox(label: 'Nominal transfer sesuai invoice', value: _nominalChecked, onChanged: (v) => setState(() => _nominalChecked = v)),
                _AuditCheckbox(label: 'Mutasi rekening admin telah dicek', value: _mutasiChecked, onChanged: (v) => setState(() => _mutasiChecked = v)),
                _AuditCheckbox(label: 'Data pesanan & pelanggan terkonfirmasi', value: _dataChecked, onChanged: (v) => setState(() => _dataChecked = v)),
              ],
            ),
          if (!isPending && payment.verifierName != null)
            SectionCard(title: 'Riwayat Audit', children: [
              InfoTile(label: 'Diaudit Oleh', value: payment.verifierName!),
              if (payment.verifiedAt != null) InfoTile(label: 'Waktu Audit', value: Formatters.dateTime(payment.verifiedAt!)),
              if (payment.refundReason != null) InfoTile(label: 'Alasan Penolakan', value: payment.refundReason!),
            ]),
        ],
      ),
      bottomNavigationBar: isPending
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: (_allChecked && !_submitting) ? _approve : null,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Verifikasi & Setujui'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(onPressed: _submitting ? null : _reject, child: const Text('Tolak Bukti / Minta Konfirmasi Ulang', style: TextStyle(color: AppColors.danger))),
                ],
              ),
            )
          : null,
    );
  }
}

class _AuditCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AuditCheckbox({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
        ]),
      ),
    );
  }
}
