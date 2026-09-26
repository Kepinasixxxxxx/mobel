import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/remote_image_tile.dart';
import '../../widgets/common/status_badge.dart';
import 'workshop_progress_screen.dart';

class DetailPesananScreen extends StatefulWidget {
  final String orderId;
  const DetailPesananScreen({super.key, required this.orderId});

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _confirmOrder(Order order) async {
    final controller = TextEditingController(text: order.dpAmount?.toStringAsFixed(0) ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal DP (opsional)', prefixText: 'Rp ', isDense: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Konfirmasi')),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final dp = double.tryParse(controller.text);
    final ok = await context.read<OrderProvider>().confirmOrder(order.id, dpAmount: dp);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pesanan dikonfirmasi.' : context.read<OrderProvider>().errorMessage ?? 'Gagal konfirmasi.')));
  }

  Future<void> _changeStatus(Order order, OrderStatus status, String confirmLabel) async {
    final ok = await context.read<OrderProvider>().changeStatus(order.id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? confirmLabel : context.read<OrderProvider>().errorMessage ?? 'Gagal memperbarui status.')));
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);

    if (_loading && order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Pesanan tidak ditemukan.')));
    }

    final sisaHari = order.deadlineDate != null ? Formatters.daysLeft(order.deadlineDate!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Row(children: [
            StatusBadge(status: order.status),
            const Spacer(),
            TagChip(label: order.orderType.label, color: AppColors.primary, background: AppColors.infoBg),
          ]),
          const SizedBox(height: 8),
          Text('#${order.orderNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('Dipesan: ${Formatters.dateTime(order.createdAt)} WIB', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (sisaHari != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.event, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Text('Deadline: ${Formatters.date(order.deadlineDate!)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                TagChip(label: sisaHari >= 0 ? 'Sisa $sisaHari Hari' : 'Lewat ${-sisaHari} Hari', color: sisaHari >= 0 ? AppColors.info : AppColors.danger, background: AppColors.surface),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          SectionCard(
            title: 'Informasi Pelanggan',
            trailingIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
            children: [
              InfoTile(label: 'Nama Pelanggan', value: order.customer.name),
              if (order.customer.phone != null) InfoTile(label: 'Telepon', value: order.customer.phone!),
              if (order.customer.email != null) InfoTile(label: 'Email', value: order.customer.email!),
              if (order.customer.address != null) InfoTile(label: 'Alamat', value: order.customer.address!),
            ],
          ),
          if (order.customOrderDetail != null)
            SectionCard(
              title: 'Detail Pesanan Custom',
              trailingIcon: const Icon(Icons.brush_outlined, color: AppColors.primary),
              children: [
                if (order.customOrderDetail!.jenisJenjang != null) InfoTile(label: 'Jenjang', value: order.customOrderDetail!.jenisJenjang!),
                if (order.customOrderDetail!.designDescription != null) InfoTile(label: 'Deskripsi Desain', value: order.customOrderDetail!.designDescription!),
                if (order.customOrderDetail!.consultationNote != null) InfoTile(label: 'Catatan Konsultasi', value: order.customOrderDetail!.consultationNote!),
                if (order.customOrderDetail!.designReference != null) ...[
                  const SizedBox(height: 4),
                  RemoteImageTile(url: order.customOrderDetail!.designReference, label: 'Referensi Desain'),
                ],
              ],
            ),
          SectionCard(
            title: 'Item Pesanan',
            trailingIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
            children: [
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(
                        child: Text('${item.name}${item.size != null ? ' (${item.size})' : ''} x${item.quantity}', style: const TextStyle(fontSize: 12.5)),
                      ),
                      Text(Formatters.rupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ]),
                  )),
              const Divider(height: 20),
              _PriceRow(label: 'Total Tagihan', value: Formatters.rupiah(order.totalPrice), bold: true),
              if (order.dpAmount != null) _PriceRow(label: 'DP Ditetapkan', value: Formatters.rupiah(order.dpAmount!)),
              _PriceRow(label: 'Sudah Dibayar', value: Formatters.rupiah(order.amountPaid)),
              _PriceRow(label: 'Sisa Tagihan', value: Formatters.rupiah(order.sisaTagihan)),
              const SizedBox(height: 8),
              if (order.isLunas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    SizedBox(width: 8),
                    Text('Lunas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ]),
                ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty)
            SectionCard(title: 'Catatan', children: [Text(order.notes!, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))]),
          if (order.statusHistory.isNotEmpty)
            SectionCard(
              title: 'Riwayat Status',
              trailingIcon: const Icon(Icons.history, color: AppColors.primary),
              children: order.statusHistory.reversed
                  .map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${h.statusLabel} · ${h.progressPercentage}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                  if (h.note != null) Text(h.note!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                  Text('${Formatters.dateTime(h.createdAt)} · ${h.adminName ?? '-'}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
      bottomNavigationBar: _BottomAction(
        order: order,
        onConfirm: () => _confirmOrder(order),
        onChangeStatus: _changeStatus,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: bold ? 13 : 12, color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final Order order;
  final VoidCallback onConfirm;
  final void Function(Order order, OrderStatus status, String confirmLabel) onChangeStatus;

  const _BottomAction({required this.order, required this.onConfirm, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    Widget button;
    switch (order.status) {
      case OrderStatus.pending:
        button = ElevatedButton.icon(onPressed: onConfirm, icon: const Icon(Icons.verified_outlined, size: 18), label: const Text('Konfirmasi Pesanan'));
        break;
      case OrderStatus.dikonfirmasi:
      case OrderStatus.diproses:
        button = order.requiresProduction
            ? ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkshopProgressScreen(orderId: order.id))),
                icon: const Icon(Icons.precision_manufacturing_outlined, size: 18),
                label: const Text('Update Progres Produksi'),
              )
            : ElevatedButton.icon(
                onPressed: () => onChangeStatus(order, OrderStatus.siapDiambil, 'Ditandai siap diambil.'),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('Tandai Siap Diambil'),
              );
        break;
      case OrderStatus.siapDiambil:
        button = ElevatedButton.icon(
          onPressed: () => onChangeStatus(order, OrderStatus.selesai, 'Pesanan diselesaikan.'),
          icon: const Icon(Icons.task_alt, size: 18),
          label: const Text('Tandai Selesai'),
        );
        break;
      case OrderStatus.selesai:
      case OrderStatus.dibatalkan:
        button = const SizedBox.shrink();
        break;
    }

    return SafeArea(minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: SizedBox(width: double.infinity, child: button));
  }
}
