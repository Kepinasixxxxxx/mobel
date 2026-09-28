import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../state/report_provider.dart';
import '../../widgets/common/date_range_picker_sheet.dart';
import '../../widgets/common/info_tile.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ReportProvider>().fetchSummary());
  }

  Future<void> _pickRange() async {
    final provider = context.read<ReportProvider>();
    final range = await showCustomDateRangePicker(context, initialStart: provider.rangeStart, initialEnd: provider.rangeEnd);
    if (range != null) provider.setRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final summary = provider.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laporan & Analitik')),
      body: provider.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && summary == null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(provider.errorMessage!, style: const TextStyle(color: AppColors.textSecondary))))
              : summary == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: provider.fetchSummary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          TapScale(
                            onTap: _pickRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
                              child: Row(children: [
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('${Formatters.date(provider.rangeStart)} - ${Formatters.date(provider.rangeEnd)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _StatCard(label: 'Total Omset', value: Formatters.rupiahCompact(summary.totalRevenue), icon: Icons.payments_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(label: 'Pesanan Masuk', value: '${summary.totalOrders}', caption: '${summary.completedOrders} Selesai', icon: Icons.receipt_long_outlined)),
                          ]),
                          const SizedBox(height: 10),
                          _StatCard(label: 'Total Pelanggan Terdaftar', value: '${summary.totalCustomers}', icon: Icons.people_outline, wide: true),
                          const SizedBox(height: 20),
                          SectionCard(
                            title: 'Komposisi Jenis Pesanan',
                            subtitle: 'Distribusi beli / sewa / custom pada periode ini',
                            trailingIcon: const Icon(Icons.pie_chart_outline, color: AppColors.primary),
                            children: summary.ordersByType.isEmpty
                                ? [const Text('Belum ada data pesanan pada periode ini.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]
                                : summary.ordersByType.map((o) {
                                    final pct = summary.totalOrders == 0 ? 0.0 : o.count / summary.totalOrders;
                                    final type = orderTypeFromApi(o.orderType);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                            Text(type.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                            Text('${o.count} pesanan (${(pct * 100).round()}%)', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                          ]),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final bool wide;

  const _StatCard({required this.label, required this.value, this.caption, required this.icon, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            Icon(icon, size: 18, color: AppColors.primary),
          ]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (caption != null) Text(caption!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
