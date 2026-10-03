import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/vg/vg_ui.dart';

Future<void> confirmOrderFlow(BuildContext context, Order order) async {
  final provider = context.read<OrderProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final controller = TextEditingController(text: (order.dpAmount ?? order.totalPrice * 0.5).toStringAsFixed(0));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Konfirmasi Pesanan'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('#${order.orderNumber} • ${order.customer.name}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Total ${Formatters.rupiah(order.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 14),
        const Text('Nominal DP yang harus dibayar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        VgMoneyField(controller: controller),
      ]),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        Row(children: [
          Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
          const SizedBox(width: 10),
          Expanded(child: VgButton(label: 'Konfirmasi', style: VgButtonStyle.gold, onPressed: () => Navigator.pop(ctx, true))),
        ]),
      ],
    ),
  );
  if (ok != true) return;
  final success = await provider.confirmOrder(order.id, dpAmount: double.tryParse(controller.text.replaceAll('.', '')));
  messenger.showSnackBar(SnackBar(content: Text(success ? 'Pesanan dikonfirmasi.' : provider.errorMessage ?? 'Gagal konfirmasi.')));
}

Future<void> changeStatusFlow(BuildContext context, Order order, OrderStatus status, String successLabel, {String? note}) async {
  final provider = context.read<OrderProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await provider.changeStatus(order.id, status, note: note);
  messenger.showSnackBar(SnackBar(content: Text(ok ? successLabel : provider.errorMessage ?? 'Gagal memperbarui status.')));
}

Future<void> rejectOrderFlow(BuildContext context, Order order) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Tolak / Minta Revisi'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Alasan penolakan atau revisi yang diminta'),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        Row(children: [
          Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
          const SizedBox(width: 10),
          Expanded(child: VgButton(label: 'Tolak Pesanan', style: VgButtonStyle.maroon, onPressed: () => Navigator.pop(ctx, true))),
        ]),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await changeStatusFlow(context, order, OrderStatus.dibatalkan, 'Pesanan ditolak.', note: controller.text.trim());
}
