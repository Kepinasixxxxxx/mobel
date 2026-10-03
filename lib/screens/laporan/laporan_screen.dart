import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../models/report_summary_model.dart';
import '../../state/order_provider.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../state/report_provider.dart';
import '../../widgets/common/date_range_picker_sheet.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';

enum _Period { bulanIni, bulanLalu, tigaPuluhHari, tahunIni, custom }

const _typeColors = {'beli': AppColors.primary, 'custom': Color(0xFFB0303F), 'sewa': Color(0xFFF59E0B)};

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  _Period _period = _Period.bulanIni;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ReportProvider>().fetchSummary();
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
      final rentals = context.read<RentalProvider>();
      if (rentals.rentalOrders.isEmpty) rentals.fetchRentals();
      final products = context.read<ProductProvider>();
      if (products.products.isEmpty) products.fetchAll();
    });
  }

  String _periodLabel(_Period p, ReportProvider r) => switch (p) {
        _Period.bulanIni => 'Bulan Ini (${DateFormat('MMM yyyy', 'id_ID').format(DateTime.now())})',
        _Period.bulanLalu => 'Bulan Lalu',
        _Period.tigaPuluhHari => '30 Hari Terakhir',
        _Period.tahunIni => 'Tahun Ini (${DateTime.now().year})',
        _Period.custom => '${Formatters.date(r.rangeStart)} - ${Formatters.date(r.rangeEnd)}',
      };

  Future<void> _selectPeriod(_Period p) async {
    final provider = context.read<ReportProvider>();
    final now = DateTime.now();
    switch (p) {
      case _Period.bulanIni:
        provider.setRange(DateTime(now.year, now.month, 1), now);
        break;
      case _Period.bulanLalu:
        provider.setRange(DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1)));
        break;
      case _Period.tigaPuluhHari:
        provider.setRange(now.subtract(const Duration(days: 29)), now);
        break;
      case _Period.tahunIni:
        provider.setRange(DateTime(now.year, 1, 1), now);
        break;
      case _Period.custom:
        final range = await showCustomDateRangePicker(context, initialStart: provider.rangeStart, initialEnd: provider.rangeEnd);
        if (range == null) return;
        provider.setRange(range.start, DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59));
    }
    setState(() => _period = p);
  }

  String _typeName(String type) => switch (type) { 'beli' => 'Konveksi Standar', 'custom' => 'Custom Batch', 'sewa' => 'Rental Kostum', _ => type };

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final orders = context.watch<OrderProvider>().orders;
    final rentals = context.watch<RentalProvider>().rentalOrders;
    final products = context.watch<ProductProvider>().products;
    final summary = report.summary;
    final previous = report.previous;

    final inRange = orders.where((o) => !o.createdAt.isBefore(report.rangeStart) && !o.createdAt.isAfter(report.rangeEnd) && o.status != OrderStatus.dibatalkan).toList();

    final totalStock = products.fold<int>(0, (s, p) => s + p.totalStockRent);
    final rentedNow = rentals
        .where((o) => o.rental!.status == RentalStatus.diambil || o.rental!.status == RentalStatus.terlambat)
        .fold<int>(0, (s, o) => s + o.totalQuantity);
    final utilization = totalStock == 0 ? 0.0 : (rentedNow / totalStock).clamp(0.0, 1.0);

    final returned = rentals.where((o) => o.rental!.status == RentalStatus.dikembalikan && o.rental!.actualReturnDate != null).toList();
    final onTime = returned.where((o) => !o.rental!.actualReturnDate!.isAfter(o.rental!.returnDate)).length;
    final onTimeRate = returned.isEmpty ? null : onTime / returned.length;

    final verifyDurations = orders
        .expand((o) => o.payments)
        .where((p) => p.status == PaymentStatus.terverifikasi && p.verifiedAt != null)
        .map((p) => p.verifiedAt!.difference(p.createdAt))
        .where((d) => !d.isNegative)
        .toList();
    final avgVerify = verifyDurations.isEmpty ? null : Duration(minutes: (verifyDurations.fold<int>(0, (s, d) => s + d.inMinutes) / verifyDurations.length).round());

    final best = <String, (double, int, String?)>{};
    for (final o in inRange) {
      for (final i in o.items) {
        final prev = best[i.name];
        best[i.name] = ((prev?.$1 ?? 0) + i.subtotal, (prev?.$2 ?? 0) + 1, prev?.$3 ?? i.imageUrl);
      }
    }
    final topItems = best.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Laporan & Analitik'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: report.fetchSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(children: [
              Expanded(
                child: PopupMenuButton<_Period>(
                  color: AppColors.surface,
                  onSelected: _selectPeriod,
                  itemBuilder: (_) => [
                    for (final p in _Period.values) PopupMenuItem(value: p, child: Text(p == _Period.custom ? 'Pilih Rentang Tanggal…' : _periodLabel(p, report))),
                  ],
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_periodLabel(_period, report), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TapScale(
                onTap: summary == null ? null : () => _copySummary(context, report, summary, topItems.map((e) => e.key).take(3).toList()),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.copy_all_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Salin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (report.isLoading && summary == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()))
            else if (summary == null)
              VgCard(child: Text(report.errorMessage ?? 'Belum ada data laporan.', style: const TextStyle(color: AppColors.textSecondary)))
            else ...[
              _CompletionBanner(summary: summary),
              const SizedBox(height: 12),
              _KpiGrid(summary: summary, previous: previous, utilization: utilization, rentedNow: rentedNow, totalStock: totalStock),
              const SizedBox(height: 14),
              _RevenueComposition(summary: summary, typeName: _typeName),
              VgCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Katalog Terlaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Berdasarkan nilai pesanan pada periode ini', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  if (topItems.isEmpty)
                    const Text('Belum ada pesanan pada periode ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
                  else
                    for (var i = 0; i < topItems.length && i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: VgInset(
                          padding: const EdgeInsets.all(10),
                          child: Row(children: [
                            VgThumb(url: topItems[i].value.$3, size: 46, radius: 8),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(topItems[i].key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text('${topItems[i].value.$2}x dipesan', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(Formatters.rupiahCompact(topItems[i].value.$1), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              if (i == 0) const Text('Top Revenue #1', style: TextStyle(fontSize: 11.5, color: AppColors.success)),
                            ]),
                          ]),
                        ),
                      ),
                ]),
              ),
              VgCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Efisiensi Operasional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  ]),
                  const SizedBox(height: 12),
                  _Efficiency(
                    icon: Icons.task_alt_rounded,
                    label: 'Pesanan Selesai',
                    value: summary.totalOrders == 0 ? '-' : '${(summary.completedOrders * 100 / summary.totalOrders).round()}% (${summary.completedOrders}/${summary.totalOrders})',
                    badge: summary.pendingOrders > 0 ? '${summary.pendingOrders} Pending' : 'Tidak Ada Antrean',
                    good: summary.pendingOrders == 0,
                  ),
                  _Efficiency(
                    icon: Icons.bolt_rounded,
                    label: 'Rata-rata Verifikasi Pembayaran',
                    value: avgVerify == null ? 'Belum ada data' : _duration(avgVerify),
                    badge: avgVerify == null ? '-' : (avgVerify.inHours < 24 ? 'Cepat' : 'Perlu Dipercepat'),
                    good: avgVerify != null && avgVerify.inHours < 24,
                  ),
                  _Efficiency(
                    icon: Icons.history_rounded,
                    label: 'Pengembalian Sewa Tepat Waktu',
                    value: onTimeRate == null ? 'Belum ada data' : '${(onTimeRate * 100).toStringAsFixed(1)}% ($onTime/${returned.length})',
                    badge: onTimeRate == null ? '-' : (onTimeRate >= 0.9 ? 'Disiplin Tinggi' : 'Perlu Pengingat'),
                    good: onTimeRate != null && onTimeRate >= 0.9,
                  ),
                ]),
              ),
              VgButton(
                label: 'Salin Ringkasan Laporan',
                icon: Icons.forward_to_inbox_outlined,
                expanded: true,
                height: 52,
                onPressed: () => _copySummary(context, report, summary, topItems.map((e) => e.key).take(3).toList()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _duration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} Menit';
    if (d.inHours < 24) return '${d.inHours} Jam ${d.inMinutes % 60} Menit';
    return '${d.inDays} Hari ${d.inHours % 24} Jam';
  }

  void _copySummary(BuildContext context, ReportProvider report, ReportSummary s, List<String> top) {
    final lines = [
      'Laporan VIEGUARD ${Formatters.date(report.rangeStart)} - ${Formatters.date(report.rangeEnd)}',
      'Total omset terverifikasi: ${Formatters.rupiah(s.totalRevenue)}',
      for (final e in s.revenueByType.entries) '- ${_typeName(e.key)}: ${Formatters.rupiah(e.value)}',
      'Pesanan masuk: ${s.totalOrders} (${s.completedOrders} selesai, ${s.pendingOrders} pending)',
      'Pelanggan terdaftar: ${s.totalCustomers}',
      if (top.isNotEmpty) 'Katalog terlaris: ${top.join(', ')}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ringkasan laporan disalin. Tempel di email atau WhatsApp.')));
  }
}

class _CompletionBanner extends StatelessWidget {
  final ReportSummary summary;
  const _CompletionBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final rate = summary.totalOrders == 0 ? 0.0 : summary.completedOrders / summary.totalOrders;
    final good = rate >= 0.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.auto_graph_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Tingkat penyelesaian pesanan '),
            TextSpan(text: '${(rate * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w700, color: good ? AppColors.success : AppColors.warning)),
          ]), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
        Text(good ? 'On-track' : 'Perlu Dorongan', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.goldDark)),
        const SizedBox(width: 4),
        Icon(good ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, size: 16, color: AppColors.goldDark),
      ]),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final ReportSummary summary;
  final ReportSummary? previous;
  final double utilization;
  final int rentedNow;
  final int totalStock;

  const _KpiGrid({required this.summary, required this.previous, required this.utilization, required this.rentedNow, required this.totalStock});

  @override
  Widget build(BuildContext context) {
    final prevRevenue = previous?.totalRevenue ?? 0;
    final growth = prevRevenue == 0 ? null : (summary.totalRevenue - prevRevenue) / prevRevenue * 100;
    final orderDelta = previous == null ? null : summary.totalOrders - previous!.totalOrders;
    final sewa = summary.revenueByType['sewa'] ?? 0;
    final sewaPct = summary.totalRevenue == 0 ? 0 : (sewa / summary.totalRevenue * 100).round();

    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _Kpi(
              label: 'Total Omset',
              value: Formatters.rupiahCompact(summary.totalRevenue),
              caption: 'Konveksi ${summary.totalRevenue == 0 ? 0 : 100 - sewaPct}% • Sewa $sewaPct%',
              badge: growth == null
                  ? null
                  : Text('${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% ${growth >= 0 ? '↗' : '↘'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: growth >= 0 ? AppColors.success : AppColors.danger)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Kpi(
              label: 'Pesanan Masuk',
              value: '${summary.totalOrders} Pesanan',
              caption: '${summary.completedOrders} Selesai • ${summary.pendingOrders} Pending',
              badge: orderDelta == null || orderDelta == 0
                  ? null
                  : VgPill(label: '${orderDelta > 0 ? '+' : ''}$orderDelta', color: AppColors.textPrimary, background: AppColors.beige, fontSize: 11),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _Kpi(
              label: 'Utilisasi Sewa',
              value: '${(utilization * 100).toStringAsFixed(1)}%',
              valueColor: AppColors.primary,
              caption: '$rentedNow dari $totalStock stel keluar',
              captionDot: utilization >= 0.75 ? const Color(0xFFF59E0B) : null,
              badge: utilization >= 0.75 ? const VgPill(label: 'Padat', color: AppColors.goldDark, background: Color(0xFFFFF1C7), fontSize: 11) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Kpi(
              label: 'Pelanggan Terdaftar',
              value: '${summary.totalCustomers}',
              valueColor: AppColors.success,
              caption: 'Total akun pelanggan',
              captionIcon: Icons.people_outline_rounded,
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Widget? badge;
  final Color valueColor;
  final Color? captionDot;
  final IconData? captionIcon;

  const _Kpi({required this.label, required this.value, required this.caption, this.badge, this.valueColor = AppColors.textPrimary, this.captionDot, this.captionIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
          ?badge,
        ]),
        const SizedBox(height: 8),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: valueColor))),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (captionDot != null) Container(margin: const EdgeInsets.only(top: 5, right: 5), width: 6, height: 6, decoration: BoxDecoration(color: captionDot, shape: BoxShape.circle)),
          if (captionIcon != null) Padding(padding: const EdgeInsets.only(right: 4, top: 1), child: Icon(captionIcon, size: 14, color: AppColors.success)),
          Expanded(child: Text(caption, style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.35))),
        ]),
      ]),
    );
  }
}

class _RevenueComposition extends StatelessWidget {
  final ReportSummary summary;
  final String Function(String) typeName;
  const _RevenueComposition({required this.summary, required this.typeName});

  @override
  Widget build(BuildContext context) {
    final entries = summary.revenueByType.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalRevenue;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Expanded(child: Text('Komposisi Pendapatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary),
        ]),
        const SizedBox(height: 14),
        if (entries.isEmpty || total == 0)
          const Text('Belum ada pembayaran terverifikasi pada periode ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(children: [
                for (final e in entries) Expanded(flex: (e.value / total * 1000).round().clamp(1, 1000), child: Container(color: _typeColors[e.key] ?? AppColors.success)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(runSpacing: 12, children: [
            for (final e in entries)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: 4), width: 9, height: 9, decoration: BoxDecoration(color: _typeColors[e.key] ?? AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(typeName(e.key), style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
                      Text('${(e.value / total * 100).round()}% (${Formatters.rupiahCompact(e.value)})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ],
      ]),
    );
  }
}

class _Efficiency extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final bool good;

  const _Efficiency({required this.icon, required this.label, required this.value, required this.badge, required this.good});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VgInset(
        child: Row(children: [
          VgIconBadge(icon: icon, color: AppColors.primary, background: AppColors.surface, size: 36, circle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(width: 8),
          VgPill(label: badge, color: good ? AppColors.success : AppColors.goldDark, background: AppColors.surface, fontSize: 11),
        ]),
      ),
    );
  }
}

