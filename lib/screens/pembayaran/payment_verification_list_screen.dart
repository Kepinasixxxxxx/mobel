import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../models/payment_model.dart';
import '../../state/payment_provider.dart';
import '../../widgets/common/status_badge.dart';
import 'payment_verification_detail_screen.dart';

class PaymentVerificationListScreen extends StatefulWidget {
  const PaymentVerificationListScreen({super.key});

  @override
  State<PaymentVerificationListScreen> createState() => _PaymentVerificationListScreenState();
}

class _PaymentVerificationListScreenState extends State<PaymentVerificationListScreen> {
  PaymentStatus _statusFilter = PaymentStatus.menunggu;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentProvider>().fetchPayments(status: _statusFilter));
  }

  void _selectFilter(PaymentStatus status) {
    setState(() => _statusFilter = status);
    context.read<PaymentProvider>().fetchPayments(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verifikasi Pembayaran')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(label: 'Menunggu', selected: _statusFilter == PaymentStatus.menunggu, onTap: () => _selectFilter(PaymentStatus.menunggu)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Terverifikasi', selected: _statusFilter == PaymentStatus.terverifikasi, onTap: () => _selectFilter(PaymentStatus.terverifikasi)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Ditolak', selected: _statusFilter == PaymentStatus.ditolak, onTap: () => _selectFilter(PaymentStatus.ditolak)),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.payments.isEmpty
                    ? const Center(child: Text('Tidak ada pembayaran pada status ini', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: provider.payments.length,
                        itemBuilder: (context, index) => _PaymentCard(
                          payment: provider.payments[index],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentVerificationDetailScreen(paymentId: provider.payments[index].id))),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PaymentCard({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${payment.orderNumber ?? '-'} · ${payment.customerName ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${payment.paymentType.toUpperCase()} · ${Formatters.date(payment.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(Formatters.rupiah(payment.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
            PaymentStatusBadge(status: payment.status),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
        child: Text(label, style: TextStyle(color: selected ? AppColors.onPrimary : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
