import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import 'input_harga_screen.dart';
import 'order_actions.dart';
import 'photo_docs_screen.dart';
import 'ship_order_screen.dart';
import 'size_preview_screen.dart';
import 'size_upload_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const VgBackBar(title: 'Detail Pesanan'),
        body: Center(child: _loading ? const CircularProgressIndicator() : const Text('Pesanan tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Detail Pesanan'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<OrderProvider>().fetchOrderDetail(order.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            order.isCustom ? _CustomHeader(order: order) : _StandardHeader(order: order),
            _CustomerCard(order: order, custom: order.isCustom),
            order.isCustom ? _CustomSpecCard(order: order) : _StandardSpecCard(order: order),
            _SizeCard(order: order),
            _DesignCard(order: order),
            if (order.isShipped) _ShippingCard(order: order),
            _DocsCard(order: order),
            if (order.statusHistory.isNotEmpty) _HistoryCard(order: order),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(order: order),
    );
  }
}

class _StandardHeader extends StatelessWidget {
  final Order order;
  const _StandardHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final left = order.deadlineDate != null ? Formatters.daysLeft(order.deadlineDate!) : null;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: OrderStatusPill(order: order, withIcon: true))),
          const SizedBox(width: 8),
          Text(order.orderType == OrderType.sewa ? 'Penyewaan' : 'Standar Batch', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.15))),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: VgPill(label: '${order.totalQuantity} Stel', color: AppColors.primary, background: AppColors.beige, fontSize: 12),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textPrimary),
          const SizedBox(width: 5),
          Expanded(child: Text('Dipesan: ${Formatters.dateTime(order.createdAt)} WIB', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
        ]),
        if (order.rental != null || order.deadlineDate != null) ...[
          const SizedBox(height: 14),
          VgInset(
            child: Row(children: [
              const VgIconBadge(icon: Icons.event_available_rounded, background: AppColors.surface, size: 38, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.rental != null ? 'Periode Sewa' : 'Target Selesai', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  Text(
                    order.rental != null
                        ? '${Formatters.date(order.rental!.pickupDate)} – ${Formatters.date(order.rental!.returnDate)}'
                        : Formatters.date(order.deadlineDate!),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ]),
              ),
              if (left != null)
                VgPill(
                  label: left >= 0 ? 'Sisa $left Hari' : 'Lewat ${-left} Hari',
                  color: left >= 0 ? AppColors.textPrimary : AppColors.danger,
                  background: AppColors.surface,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CustomHeader extends StatelessWidget {
  final Order order;
  const _CustomHeader({required this.order});

  String _orderedAt(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay ? 'Hari ini, ${DateFormat('HH:mm').format(t)}' : Formatters.dateTime(t);
  }

  @override
  Widget build(BuildContext context) {
    final estimasi = order.deadlineDate?.difference(order.createdAt).inDays;
    final pending = order.status == OrderStatus.pending;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
            child: order.needsQuote
                ? const VgPill(label: 'MENUNGGU PENAWARAN HARGA', color: AppColors.warning, background: AppColors.warningBg, dot: true, fontSize: 10.5)
                : OrderStatusPill(order: order),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text('Dipesan: ${_orderedAt(order.createdAt)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kode Pesanan', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              Text('#${order.orderNumber}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.15)),
            ]),
          ),
          const SizedBox(width: 8),
          VgInset(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            radius: 8,
            width: null,
            child: Text('Custom Batch\n${order.totalQuantity} Stel', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 12),
        VgInset(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          radius: 10,
          child: Row(children: [
            const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Target Selesai: ', style: TextStyle(color: AppColors.textSecondary)),
                TextSpan(
                  text: order.deadlineDate != null ? Formatters.date(order.deadlineDate!) : 'Belum ditentukan',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ]), style: const TextStyle(fontSize: 12.5)),
            ),
            if (estimasi != null) Text('Estimasi $estimasi Hari', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ]),
        ),
        if (pending) ...[
          const SizedBox(height: 12),
          VgInset(
            color: const Color(0xFFFFF7E0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.needsQuote ? 'Estimasi Biaya Belum Ditentukan' : 'Penawaran: ${Formatters.rupiah(order.totalPrice)}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(
                      order.needsQuote ? 'Harap kalkulasikan bahan & kirim penawaran segera.' : 'Menunggu persetujuan pelanggan. Penawaran masih dapat diubah.',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              VgButton(
                label: order.needsQuote ? 'Input Harga Custom' : 'Ubah Harga Custom',
                style: VgButtonStyle.amber,
                expanded: true,
                height: 40,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InputHargaScreen(orderId: order.id))),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.35)),
        ]),
      ),
    ]);
  }
}

class _ChatButton extends StatelessWidget {
  final Order order;
  const _ChatButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => openChatWithCustomer(context, order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF2E7D4F), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_outlined, size: 15, color: Colors.white),
          SizedBox(width: 6),
          Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Order order;
  final bool custom;
  const _CustomerCard({required this.order, required this.custom});

  @override
  Widget build(BuildContext context) {
    final c = order.customer;
    final phoneRow = Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: custom ? Colors.transparent : const Color(0xFFD7EFDD), shape: BoxShape.circle),
        child: const Icon(Icons.phone_outlined, size: 19, color: Color(0xFF2E7D4F)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(custom ? 'WhatsApp / Telepon' : 'WhatsApp PIC', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          Text(c.phone ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
      _ChatButton(order: order),
    ]);

    final rows = <Widget>[
      _InfoRow(icon: custom ? Icons.account_balance_outlined : Icons.school_outlined, label: custom ? 'Institusi Pemesan' : 'Institusi / Sekolah', value: c.name),
      if (c.email != null) _InfoRow(icon: Icons.person_outline_rounded, label: 'Email Penanggung Jawab', value: c.email!),
      custom ? phoneRow : VgInset(padding: const EdgeInsets.fromLTRB(10, 10, 10, 10), child: phoneRow),
      if (c.address != null && c.address!.isNotEmpty)
        _InfoRow(icon: custom ? Icons.location_on_outlined : Icons.local_shipping_outlined, label: custom ? 'Alamat Pengiriman' : 'Alamat Tujuan Pengiriman', value: c.address!),
    ];

    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: 'Informasi Pelanggan',
          subtitle: 'Data Pemesan & Kontak Resmi',
          trailing: custom
              ? const VgIconBadge(icon: Icons.contact_mail_outlined, color: Colors.white, background: AppColors.primary, size: 34)
              : const VgIconBadge(icon: Icons.contact_mail_outlined, background: AppColors.beige, size: 38, circle: true),
        ),
        for (final r in rows) ...[
          custom && r is! VgInset ? VgInset(padding: const EdgeInsets.all(12), child: r) : r,
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

class _StandardSpecCard extends StatelessWidget {
  final Order order;
  const _StandardSpecCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final verifiedDp = order.payments.where((p) => p.status == PaymentStatus.terverifikasi).toList();
    final dpPercent = order.dpAmount != null && order.totalPrice > 0 ? (order.dpAmount! / order.totalPrice * 100).round() : null;
    final subtotal = order.items.fold<double>(0, (s, i) => s + i.subtotal);
    final names = order.items.map((i) => i.size != null ? '${i.name} ${i.size}' : i.name).toSet().join(' + ');

    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: order.orderType == OrderType.sewa ? 'Spesifikasi Penyewaan' : 'Spesifikasi Pesanan Standar',
          subtitle: 'Katalog Produksi Resmi VIEGUARD',
          trailing: const VgIconBadge(icon: Icons.inventory_2_outlined, color: AppColors.goldDark, background: AppColors.warningBg, size: 38, circle: true),
        ),
        VgInset(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PAKET PRODUK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Text(order.headline, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Text(order.orderType == OrderType.sewa ? 'Rental Kostum Marching Band' : 'Konveksi Seragam Musik Drumband', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('${order.totalQuantity} Stel ($names)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        for (final item in order.items)
          _PriceLine(label: '${item.name} (${item.quantity}x)', value: '${Formatters.rupiah(item.unitPrice)} / stel'),
        _PriceLine(label: 'Subtotal Produksi', value: Formatters.rupiah(subtotal)),
        if (order.rental?.penaltyAmount != null && order.rental!.penaltyAmount! > 0) _PriceLine(label: 'Denda Keterlambatan', value: Formatters.rupiah(order.rental!.penaltyAmount!)),
        const SizedBox(height: 6),
        VgInset(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Tagihan Final', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
            Text(dpPercent != null ? 'Termin $dpPercent/${100 - dpPercent}' : 'Bayar Penuh', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 10),
        VgInset(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          radius: 10,
          child: Row(children: [
            Icon(order.amountPaid > 0 ? Icons.check_circle_outline_rounded : Icons.pending_outlined, size: 18, color: order.amountPaid > 0 ? AppColors.success : AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.isLunas
                    ? 'Lunas (${Formatters.rupiah(order.amountPaid)})'
                    : order.amountPaid > 0
                        ? 'DP Diterima (${Formatters.rupiah(order.amountPaid)})'
                        : 'Belum ada pembayaran terverifikasi',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            if (verifiedDp.isNotEmpty && verifiedDp.last.paymentMethod != null)
              Text(verifiedDp.last.paymentMethod!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ]),
        ),
      ]),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  const _PriceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.primary))),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _SpecBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? trailingNote;
  const _SpecBlock({required this.label, required this.value, this.trailingNote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VgInset(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 3),
          Text.rich(TextSpan(children: [
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            if (trailingNote != null) TextSpan(text: ' $trailingNote', style: const TextStyle(color: AppColors.primary, fontSize: 12.5)),
          ]), style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ]),
      ),
    );
  }
}

class _CustomSpecCard extends StatelessWidget {
  final Order order;
  const _CustomSpecCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final d = order.customOrderDetail;
    final names = order.items.map((i) => i.name).toSet().join(' + ');
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const VgCardTitle(
          title: 'Spesifikasi Permintaan',
          subtitle: 'Detail Konfigurasi Pakaian',
          trailing: VgIconBadge(icon: Icons.handyman_outlined, color: Colors.white, background: AppColors.primary, size: 34),
        ),
        _SpecBlock(label: 'Kategori & Tipe Produk', value: d?.jenisJenjang ?? order.headline),
        if (d?.designDescription != null) _SpecBlock(label: 'Deskripsi Desain & Bahan', value: d!.designDescription!),
        _SpecBlock(label: 'Total Kuantitas', value: '${order.totalQuantity} Stel', trailingNote: names.isEmpty ? null : '($names)'),
        if (d?.consultationNote != null) _SpecBlock(label: 'Catatan Konsultasi', value: d!.consultationNote!),
        if (order.notes != null && order.notes!.isNotEmpty)
          VgInset(
            color: AppColors.beigeSoft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.sticky_note_2_outlined, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Catatan Khusus Pelanggan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              const SizedBox(height: 4),
              Text('"${order.notes!}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary, height: 1.4)),
            ]),
          ),
      ]),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final Order order;
  const _SizeCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final sizes = order.sizeBreakdown;
    final complete = sizes.isNotEmpty && order.sizedQuantity >= order.totalQuantity;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: order.isCustom ? 'Data Ukuran Siswa' : 'Data Ukuran Siswa',
          subtitle: 'Rekapitulasi Ukuran per Stel',
          trailing: sizes.isEmpty
              ? const VgPill(label: 'Belum Ada', color: AppColors.warning, background: AppColors.warningBg, icon: Icons.info_outline)
              : VgPill(
                  label: complete ? 'Data Lengkap' : 'Sebagian',
                  color: complete ? AppColors.success : AppColors.warning,
                  background: complete ? AppColors.successBg : AppColors.warningBg,
                  icon: Icons.check_circle_outline_rounded,
                ),
        ),
        if (sizes.isEmpty) ...[
          const VgInset(child: Text('Pelanggan belum melampirkan ukuran pada pesanan ini.', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
          const SizedBox(height: 10),
          VgButton(
            label: 'Upload Data Ukuran Siswa',
            icon: Icons.upload_file_rounded,
            expanded: true,
            height: 44,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SizeUploadScreen(orderId: order.id))),
          ),
        ] else
          VgInset(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF1E7B45), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.straighten_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      order.hasStudentSizes ? '${order.sizeEntries.length} siswa · ${sizes.length} ukuran' : '${sizes.length} ukuran tercatat',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(sizes.entries.map((e) => '${e.key} × ${e.value}').join(' • '), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ]),
                ),
                Text('${order.sizedQuantity} Stel', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
              const SizedBox(height: 12),
              VgButton(
                label: 'Kelola Data Ukuran Siswa',
                icon: Icons.manage_accounts_outlined,
                expanded: true,
                height: 44,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SizeUploadScreen(orderId: order.id))),
              ),
              const SizedBox(height: 10),
              VgButton(label: 'Pratinjau Data Ukuran (Preview)', icon: Icons.visibility_outlined, style: VgButtonStyle.outline, expanded: true, height: 44, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SizePreviewScreen(orderId: order.id)))),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sizeRecapText(order)));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rekap ukuran disalin.')));
                },
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                label: const Text('Salin Rekap Ukuran', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final Order order;
  const _DesignCard({required this.order});

  void _zoom(BuildContext context, String url) {
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
    final images = <(String, String)>[];
    final ref = order.customOrderDetail?.designReference;
    if (ref != null && ref.startsWith('http')) images.add((ref, 'Referensi Pelanggan'));
    for (final item in order.items) {
      if (item.imageUrl != null && images.every((e) => e.$1 != item.imageUrl)) images.add((item.imageUrl!, item.name));
    }
    final note = order.customOrderDetail?.designDescription;
    if (images.isEmpty && note == null) return const SizedBox.shrink();

    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: order.isCustom ? 'Lampiran Referensi Desain' : 'Referensi Desain & Mockup',
          subtitle: order.isCustom ? 'Mockup Visual Pakaian Pesanan' : 'Spesifikasi Warna & Aksesoris',
          trailing: order.isCustom
              ? VgPill(label: '${images.length} Foto', color: AppColors.primary, background: AppColors.beige)
              : const VgIconBadge(icon: Icons.palette_outlined, color: AppColors.goldDark, background: AppColors.warningBg, size: 38, circle: true),
        ),
        if (images.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: images
                .map((img) => TapScale(
                      onTap: () => _zoom(context, img.$1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.network(img.$1, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige, child: const Icon(Icons.image_not_supported_outlined, color: AppColors.primary))),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 18, 8, 8),
                              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.85)])),
                              child: Row(children: [
                                Expanded(child: Text(img.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                                const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        if (note != null) ...[
          const SizedBox(height: 12),
          VgInset(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.palette_outlined, size: 20, color: AppColors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Spesifikasi Warna & Pola', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(note, style: const TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Order order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(title: 'Riwayat Status', subtitle: 'Progres ${order.latestProgress}%', trailing: const VgIconBadge(icon: Icons.history_rounded, size: 38, circle: true)),
        for (final h in order.statusHistory.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 5), width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${h.statusLabel} · ${h.progressPercentage}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (h.note != null && h.note!.isNotEmpty) Text(h.note!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  Text('${Formatters.dateTime(h.createdAt)} · ${h.adminName ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final Order order;
  const _BottomActions({required this.order});

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons;
    switch (order.status) {
      case OrderStatus.pending:
        buttons = order.isCustom
            ? [
                VgButton(
                  label: order.needsQuote ? 'Buat & Kirim Penawaran Harga' : 'Ubah Penawaran Harga',
                  icon: Icons.request_quote_outlined,
                  style: VgButtonStyle.gold,
                  expanded: true,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InputHargaScreen(orderId: order.id))),
                ),
                const SizedBox(height: 10),
                VgButton(label: 'Tolak / Minta Revisi Desain', icon: Icons.cancel_outlined, style: VgButtonStyle.soft, expanded: true, height: 42, onPressed: () => rejectOrderFlow(context, order)),
              ]
            : [VgButton(label: 'Konfirmasi Pesanan', icon: Icons.verified_outlined, style: VgButtonStyle.gold, expanded: true, onPressed: () => confirmOrderFlow(context, order))];
        break;
      case OrderStatus.dikonfirmasi:
      case OrderStatus.diproses:
        buttons = [
          order.requiresProduction
              ? VgButton(
                  label: 'Update Progres Produksi',
                  icon: Icons.edit_note_rounded,
                  expanded: true,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkshopProgressScreen(orderId: order.id))),
                )
              : VgButton(
                  label: 'Tandai Siap Diambil',
                  icon: Icons.inventory_2_outlined,
                  expanded: true,
                  onPressed: () => changeStatusFlow(context, order, OrderStatus.siapDiambil, 'Ditandai siap diambil.'),
                ),
        ];
        break;
      case OrderStatus.siapDiambil:
        final canShip = order.orderType != OrderType.sewa && !order.isShipped;
        buttons = [
          if (canShip) ...[
            VgButton(
              label: 'Kirim Pesanan & Input Resi',
              icon: Icons.local_shipping_outlined,
              style: VgButtonStyle.green,
              expanded: true,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShipOrderScreen(orderId: order.id))),
            ),
            const SizedBox(height: 10),
          ],
          VgButton(
            label: order.isShipped ? 'Tandai Selesai (Sudah Diterima)' : 'Tandai Selesai',
            icon: Icons.task_alt_rounded,
            style: canShip ? VgButtonStyle.soft : VgButtonStyle.maroon,
            expanded: true,
            height: canShip ? 42 : 48,
            onPressed: () => changeStatusFlow(context, order, OrderStatus.selesai, 'Pesanan diselesaikan.'),
          ),
        ];
        break;
      case OrderStatus.selesai:
      case OrderStatus.dibatalkan:
        return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  final Order order;
  const _ShippingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final pickup = order.trackingNumber == null;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: pickup ? 'Siap Diambil Pelanggan' : 'Pengiriman',
          subtitle: '${order.courier ?? '-'} · ${Formatters.dateTime(order.shippedAt!)}',
          trailing: const VgIconBadge(icon: Icons.local_shipping_outlined, color: AppColors.success, background: AppColors.successBg, size: 38, circle: true),
        ),
        if (!pickup)
          VgInset(
            child: Row(children: [
              const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nomor Resi', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  Text(order.trackingNumber!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ]),
              ),
              TapScale(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.trackingNumber!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor resi disalin.')));
                },
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Salin', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
        if (order.shippingCost != null) ...[
          const SizedBox(height: 10),
          _PriceLine(label: 'Biaya Pengiriman', value: Formatters.rupiah(order.shippingCost!)),
        ],
        if (order.etaDate != null) _PriceLine(label: 'Estimasi Tiba', value: Formatters.date(order.etaDate!)),
      ]),
    );
  }
}

class _DocsCard extends StatelessWidget {
  final Order order;
  const _DocsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final photos = order.photos;
    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoDocsScreen(orderId: order.id)));
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgCardTitle(
          title: 'Dokumentasi Foto',
          subtitle: 'Workshop, QC, kerusakan & pengiriman',
          trailing: VgPill(label: '${photos.length} Foto', color: photos.isEmpty ? AppColors.primary : AppColors.success, background: photos.isEmpty ? AppColors.beige : AppColors.successBg),
        ),
        if (photos.isNotEmpty) ...[
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length.clamp(0, 6),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SizedBox(
                width: 84,
                child: TapScale(
                  onTap: open,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(photos[i].imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        VgButton(label: photos.isEmpty ? 'Tambah Foto Dokumentasi' : 'Kelola Foto Dokumentasi', icon: Icons.add_a_photo_outlined, style: VgButtonStyle.soft, expanded: true, height: 44, onPressed: open),
      ]),
    );
  }
}
