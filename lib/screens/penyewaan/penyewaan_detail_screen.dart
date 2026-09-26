import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/status_badge.dart';
import 'catat_kondisi_barang_screen.dart';
import 'surat_perjanjian_screen.dart';

class PenyewaanDetailScreen extends StatelessWidget {
  final String orderId;
  const PenyewaanDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final order = provider.rentalOrders.where((o) => o.id == orderId).isEmpty ? null : provider.rentalOrders.firstWhere((o) => o.id == orderId);

    if (order == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final rental = order.rental!;
    final sisaWaktu = rental.returnDate.difference(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Penyewaan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            const Text('ID RESERVASI', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            TagChip(label: 'Hari ke-${rental.daysElapsed + 1} dari ${rental.totalDays}', color: AppColors.info, background: AppColors.infoBg),
          ]),
          Row(children: [
            Text('#${order.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            RentalStatusBadge(status: rental.status),
          ]),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Periode Sewa',
            trailingIcon: const Icon(Icons.event_outlined, color: AppColors.primary),
            children: [
              InfoTile(label: 'Tanggal Ambil', value: Formatters.dateTime(rental.pickupDate)),
              InfoTile(label: 'Tanggal Kembali', value: Formatters.dateTime(rental.returnDate)),
              if (rental.status == RentalStatus.diambil)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: sisaWaktu.isNegative ? AppColors.warningBg : AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    sisaWaktu.isNegative ? 'Terlambat ${sisaWaktu.abs().inHours} jam' : 'Sisa ${sisaWaktu.inHours ~/ 24} hari ${sisaWaktu.inHours % 24} jam',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sisaWaktu.isNegative ? AppColors.warning : AppColors.info),
                  ),
                ),
            ],
          ),
          SectionCard(
            title: 'Profil Penyewa',
            trailingIcon: const Icon(Icons.person_outline, color: AppColors.primary),
            children: [
              InfoTile(label: 'Nama', value: order.customer.name),
              if (order.customer.address != null) InfoTile(label: 'Alamat', value: order.customer.address!),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka WhatsApp...'))),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chat WhatsApp', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungi...'))),
                  child: const Icon(Icons.phone, size: 18),
                ),
              ]),
            ],
          ),
          SectionCard(
            title: 'Item Kostum',
            trailingIcon: TagChip(label: '${order.totalQuantity} Unit', color: AppColors.primary, background: AppColors.infoBg),
            children: order.items
                .map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.checkroom, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${i.name}${i.size != null ? ' (${i.size})' : ''} x${i.quantity}', style: const TextStyle(fontSize: 12.5))),
                      ]),
                    ))
                .toList(),
          ),
          if (rental.itemConditionBefore != null)
            SectionCard(title: 'Kondisi Saat Diserahkan', trailingIcon: const Icon(Icons.fact_check_outlined, color: AppColors.primary), children: [
              Text(rental.itemConditionBefore!, style: const TextStyle(fontSize: 12.5)),
            ]),
          SectionCard(
            title: 'Rincian Pembayaran',
            trailingIcon: TagChip(label: order.isLunas ? 'LUNAS' : 'BELUM LUNAS', color: order.isLunas ? AppColors.success : AppColors.warning, background: order.isLunas ? AppColors.successBg : AppColors.warningBg),
            children: [
              ...order.payments.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(child: Text('${p.paymentType == 'dp' ? 'DP' : p.paymentType == 'pelunasan' ? 'Pelunasan' : 'Refund'} · ${p.paymentMethod ?? '-'}', style: const TextStyle(fontSize: 12.5))),
                      Text(Formatters.rupiah(p.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ]),
                  )),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Tagihan Sewa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          if (rental.status == RentalStatus.diambil)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatatKondisiBarangScreen(orderId: order.id))),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('Catat Pengembalian & Kondisi Barang'),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuratPerjanjianScreen(order: order))),
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Cetak Surat Perjanjian Sewa'),
          ),
        ],
      ),
    );
  }
}
