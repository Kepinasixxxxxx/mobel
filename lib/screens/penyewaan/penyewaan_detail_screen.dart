import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import 'catat_kondisi_barang_screen.dart';
import 'rental_actions.dart';
import 'surat_perjanjian_screen.dart';

class PenyewaanDetailScreen extends StatelessWidget {
  final String orderId;
  const PenyewaanDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<RentalProvider>().rentalOrders.where((o) => o.id == orderId);
    if (matches.isEmpty) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Detail Penyewaan'), body: Center(child: Text('Data sewa tidak ditemukan.')));
    }
    final order = matches.first;
    final rental = order.rental!;
    final active = rental.status == RentalStatus.diambil || rental.status == RentalStatus.terlambat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Detail Penyewaan'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: context.read<RentalProvider>().fetchRentals,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ReservationCard(order: order),
            _RenterCard(order: order),
            _ItemsCard(order: order),
            if (rental.depositAmount != null) _DepositCard(order: order),
            _QcOutCard(order: order),
            if (rental.status == RentalStatus.dikembalikan) _ReturnCard(order: order),
            _PaymentCard(order: order),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (active)
              VgButton(
                label: 'Catat Pengembalian & Kondisi Barang',
                icon: Icons.assignment_turned_in_outlined,
                expanded: true,
                height: 52,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatatKondisiBarangScreen(orderId: order.id))),
              )
            else if (rental.status == RentalStatus.dipesan)
              VgButton(label: 'Konfirmasi Pengambilan', icon: Icons.how_to_reg_outlined, expanded: true, height: 52, onPressed: () => confirmPickupFlow(context, order))
            else if (rental.awaitingRefund)
              VgButton(
                label: 'Refund Deposit ${Formatters.rupiah(rental.refundDue)}',
                icon: Icons.account_balance_wallet_outlined,
                style: VgButtonStyle.green,
                expanded: true,
                height: 52,
                onPressed: () => openRefund(context, order),
              ),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuratPerjanjianScreen(order: order))),
              icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.textPrimary),
              label: const Text('Cetak Surat Perjanjian Sewa', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Order order;
  const _ReservationCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final remaining = rental.returnDate.add(const Duration(days: 1)).difference(DateTime.now());
    final String pill;
    final Color pillFg;
    final Color pillBg;
    switch (rental.status) {
      case RentalStatus.diambil:
        pill = 'Hari ke-${rental.daysElapsed + 1} dari ${rental.totalDays}';
        pillFg = AppColors.warning;
        pillBg = AppColors.warningBg;
        break;
      default:
        pill = rental.status.label;
        pillFg = rental.status.color;
        pillBg = rental.status.background;
    }

    String? countdown;
    if (rental.status == RentalStatus.diambil || rental.status == RentalStatus.terlambat) {
      countdown = remaining.isNegative ? 'Terlambat ${remaining.abs().inDays} Hari' : 'Sisa ${remaining.inDays} Hari ${remaining.inHours % 24} Jam';
    } else if (rental.status == RentalStatus.dipesan) {
      final until = Formatters.daysLeft(rental.pickupDate);
      countdown = until > 0 ? 'Diambil $until Hari Lagi' : (until == 0 ? 'Diambil Hari Ini' : 'Lewat Jadwal Ambil');
    }

    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ID RESERVASI', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, letterSpacing: 0.6)),
              const SizedBox(height: 2),
              TapScale(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.orderNumber));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID reservasi disalin.')));
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.textPrimary),
                ]),
              ),
            ]),
          ),
          VgPill(label: pill, color: pillFg, background: pillBg, dot: true, fontSize: 11),
        ]),
        const SizedBox(height: 14),
        VgInset(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(child: Text('Periode Sewa', style: TextStyle(fontSize: 13, color: AppColors.primary))),
              if (countdown != null) Text(countdown, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: remaining.isNegative ? AppColors.danger : AppColors.primary)),
            ]),
            const SizedBox(height: 10),
            _DateRow(color: AppColors.success, label: 'Ambil', date: rental.pickupDate, time: rental.pickupTime),
            const SizedBox(height: 8),
            _DateRow(color: AppColors.gold, label: 'Kembali', date: rental.returnDate, time: rental.returnTime),
            if (rental.actualReturnDate != null) ...[
              const SizedBox(height: 8),
              _DateRow(color: AppColors.primary, label: 'Dikembalikan', date: rental.actualReturnDate!),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _DateRow extends StatelessWidget {
  final Color color;
  final String label;
  final DateTime date;
  final String? time;
  const _DateRow({required this.color, required this.label, required this.date, this.time});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text('${Formatters.dayDate(date)}${time != null ? ', $time WIB' : ''}', style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
    ]);
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _CardHeader({required this.icon, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgIconBadge(icon: icon, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 13.5, color: AppColors.primary)),
          ]),
        ),
        ?trailing,
      ]),
    );
  }
}

class _RenterCard extends StatelessWidget {
  final Order order;
  const _RenterCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = order.customer;
    final verified = order.amountPaid > 0;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(
          icon: Icons.theater_comedy_outlined,
          title: 'Profil Penyewa',
          trailing: VgPill(
            label: verified ? 'Terverifikasi' : 'Belum Bayar',
            color: verified ? AppColors.success : AppColors.warning,
            background: verified ? AppColors.successBg : AppColors.warningBg,
            icon: verified ? Icons.verified_outlined : Icons.info_outline,
            fontSize: 11,
          ),
        ),
        Text(c.name, style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary)),
        if (c.email != null) Text(c.email!, style: const TextStyle(fontSize: 13.5, color: AppColors.primary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TapScale(
              onTap: () => openChatWithCustomer(context, order),
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: const Color(0xFF22A447), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Chat Penyewa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          TapScale(
            onTap: () {
              if (c.phone == null) return;
              Clipboard.setData(ClipboardData(text: c.phone!));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nomor ${c.phone} disalin.')));
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.phone_outlined, color: AppColors.primary),
            ),
          ),
        ]),
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          VgInset(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.celebration_outlined, size: 18, color: AppColors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tujuan & Agenda Acara', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(order.notes!, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.35)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final products = <String, List<OrderItem>>{};
    final accessories = <OrderItem>[];
    for (final item in order.items) {
      if (item.itemType == 'accessory') {
        accessories.add(item);
      } else {
        products.putIfAbsent(item.name, () => []).add(item);
      }
    }
    final summary = '${order.totalQuantity} Stel${accessories.isNotEmpty ? ' + Aksesoris' : ''}';

    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(
          icon: Icons.checkroom_rounded,
          title: 'Item Kostum',
          subtitle: summary,
          trailing: VgPill(label: '${order.totalQuantity} Unit', color: AppColors.primary, background: AppColors.beige, fontSize: 12),
        ),
        VgInset(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final entry in products.entries) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VgThumb(url: entry.value.first.imageUrl, size: 76, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.key, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3)),
                    const SizedBox(height: 4),
                    Text('${entry.value.fold<int>(0, (s, i) => s + i.quantity)} stel', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final i in entry.value)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                          child: Text('${i.size ?? 'All'}: ${i.quantity}', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                        ),
                    ]),
                  ]),
                ),
              ]),
              if (entry.key != products.keys.last) const SizedBox(height: 12),
            ],
            if (accessories.isNotEmpty) ...[
              const SizedBox(height: 12),
              VgInset(
                color: AppColors.beigeSoft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Aksesoris Termasuk:', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  for (final a in accessories)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(margin: const EdgeInsets.only(top: 6, right: 10), width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                        Expanded(child: Text('${a.quantity}x ${a.name}', style: const TextStyle(fontSize: 13, color: AppColors.primary))),
                      ]),
                    ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _QcOutCard extends StatelessWidget {
  final Order order;
  const _QcOutCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final handed = rental.itemConditionBefore != null && rental.itemConditionBefore!.isNotEmpty;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(
          icon: Icons.fact_check_outlined,
          title: 'Inspeksi Pengeluaran (QC Out)',
          subtitle: 'Kondisi serah terima kostum',
          trailing: VgPill(
            label: handed ? 'Approved' : 'Belum Diserahkan',
            color: handed ? AppColors.success : AppColors.warning,
            background: handed ? AppColors.successBg : AppColors.warningBg,
            icon: handed ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
            fontSize: 11,
          ),
        ),
        VgInset(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.assignment_ind_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                handed ? rental.itemConditionBefore! : 'Kondisi serah terima dicatat saat penyewa mengambil kostum.',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
              ),
            ),
          ]),
        ),
        if (rental.handoverAt != null) ...[
          const SizedBox(height: 8),
          Text('Diserahkan ${Formatters.dateTime(rental.handoverAt!)} WIB', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        if (rental.agreementPhoto != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(rental.agreementPhoto!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige)),
                const Positioned(left: 8, bottom: 8, child: VgPill(label: 'Surat perjanjian bertanda tangan', color: Colors.white, background: Color(0xAA7A0015), fontSize: 10.5)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final Order order;
  const _ReturnCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(
          icon: Icons.assignment_return_outlined,
          title: 'Inspeksi Pengembalian',
          subtitle: 'Hasil pengecekan fisik',
          trailing: (rental.penaltyAmount ?? 0) > 0
              ? VgPill(label: 'Denda ${Formatters.rupiah(rental.penaltyAmount!)}', color: AppColors.danger, background: AppColors.dangerBg, fontSize: 11)
              : const VgPill(label: 'Bebas Cacat', color: AppColors.success, background: AppColors.successBg, fontSize: 11),
        ),
        if (rental.itemConditionAfter != null) VgInset(child: Text(rental.itemConditionAfter!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45))),
        if (rental.damageNote != null) ...[
          const SizedBox(height: 10),
          VgInset(
            color: const Color(0xFFFFF4D6),
            child: Text(rental.damageNote!, style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.45)),
          ),
        ],
      ]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Order order;
  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final verified = order.payments.where((p) => p.status == PaymentStatus.terverifikasi).toList();
    final methods = verified.map((p) => p.paymentMethod).whereType<String>().toSet().join(', ');
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(
          icon: Icons.receipt_long_outlined,
          title: 'Rincian Pembayaran',
          trailing: VgPill(
            label: order.isLunas ? 'LUNAS' : 'BELUM LUNAS',
            color: order.isLunas ? AppColors.success : AppColors.warning,
            background: order.isLunas ? AppColors.successBg : AppColors.warningBg,
            icon: order.isLunas ? Icons.check_circle_outline_rounded : null,
            fontSize: 11.5,
          ),
        ),
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text('Biaya Sewa (${item.quantity} × ${Formatters.rupiah(item.unitPrice)})', style: const TextStyle(fontSize: 13.5, color: AppColors.primary))),
              Text(Formatters.rupiah(item.subtotal), style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
            ]),
          ),
        if ((order.rental!.penaltyAmount ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Expanded(child: Text('Denda / Potongan', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
              Text(Formatters.rupiah(order.rental!.penaltyAmount!), style: const TextStyle(fontSize: 13.5, color: AppColors.danger)),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            const Expanded(child: Text('Total Tagihan Sewa', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
            Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
        ),
        VgInset(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Ditransfer & Diterima', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                Text(methods.isEmpty ? 'Belum ada pembayaran terverifikasi' : 'Metode: $methods', style: TextStyle(fontSize: 12.5, color: methods.isEmpty ? AppColors.warning : AppColors.success)),
              ]),
            ),
            Text(Formatters.rupiah(order.amountPaid), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
        ),
      ]),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final Order order;
  const _DepositCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final done = rental.refundStatus == 'selesai';
    final String status;
    final Color fg;
    final Color bg;
    if (done) {
      status = 'Dikembalikan';
      fg = AppColors.success;
      bg = AppColors.successBg;
    } else if (rental.awaitingRefund) {
      status = 'Menunggu Refund';
      fg = AppColors.warning;
      bg = AppColors.warningBg;
    } else {
      status = 'Ditahan';
      fg = AppColors.primary;
      bg = AppColors.beige;
    }
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(icon: Icons.shield_outlined, title: 'Deposit Keamanan', subtitle: Formatters.rupiah(rental.depositAmount ?? 0), trailing: VgPill(label: status, color: fg, background: bg, dot: true, fontSize: 11)),
        VgInset(
          color: done ? AppColors.successBg : const Color(0xFFFFF4D6),
          child: Text(
            done
                ? 'Refund ${Formatters.rupiah(rental.refundAmount ?? 0)} ditransfer${rental.refundedAt != null ? ' ${Formatters.dateTime(rental.refundedAt!)}' : ''}${rental.refundBank != null ? ' ke ${rental.refundBank} ${rental.refundAccount ?? ''}' : ''}.'
                : rental.awaitingRefund
                    ? 'Kostum sudah kembali. Refund ${Formatters.rupiah(rental.refundDue)} setelah dipotong denda ${Formatters.rupiah(rental.penaltyAmount ?? 0)}.'
                    : 'Deposit ditahan sampai kostum kembali lengkap dan lolos inspeksi fisik.',
            style: TextStyle(fontSize: 12.5, color: done ? AppColors.success : AppColors.primary, height: 1.4),
          ),
        ),
      ]),
    );
  }
}
