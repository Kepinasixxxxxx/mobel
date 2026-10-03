import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';

const _sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

int _sizeRank(String s) {
  final i = _sizeOrder.indexOf(s.toUpperCase());
  return i == -1 ? 99 : i;
}

String sizeRecapText(Order order) {
  final lines = order.sizeBreakdown.entries.map((e) => '${e.key}: ${e.value} stel').join('\n');
  return 'Rekap Ukuran #${order.orderNumber} (${order.customer.name})\n$lines\nTotal: ${order.sizedQuantity} dari ${order.totalQuantity} stel';
}

class SizePreviewScreen extends StatefulWidget {
  final String orderId;
  const SizePreviewScreen({super.key, required this.orderId});

  @override
  State<SizePreviewScreen> createState() => _SizePreviewScreenState();
}

class _SizePreviewScreenState extends State<SizePreviewScreen> {
  static const _preview = 7;
  bool _showAll = false;

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _csv(Order order) {
    final rows = order.items.where((i) => i.size != null).toList();
    return ['No,Item,Ukuran,Jumlah', for (var i = 0; i < rows.length; i++) '${i + 1},"${rows[i].name}",${rows[i].size},${rows[i].quantity}'].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Pratinjau Data Ukuran'), body: Center(child: Text('Pesanan tidak ditemukan.')));
    }

    final sizes = order.sizeBreakdown.entries.toList()..sort((a, b) => _sizeRank(a.key).compareTo(_sizeRank(b.key)));
    final rows = order.items.where((i) => i.size != null && i.size!.isNotEmpty).toList()..sort((a, b) => _sizeRank(a.size!).compareTo(_sizeRank(b.size!)));
    final complete = sizes.isNotEmpty && order.sizedQuantity >= order.totalQuantity;
    final maxQty = sizes.isEmpty ? 0 : sizes.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final shown = _showAll ? rows : rows.take(_preview).toList();
    final readyForProduction = complete && order.requiresProduction && order.status != OrderStatus.selesai && order.status != OrderStatus.dibatalkan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Pratinjau Data Ukuran'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          VgInset(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            radius: 10,
            child: Row(children: [
              const Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Dihitung otomatis dari item pesanan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary))),
              Text('${rows.length} baris', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 14),
          VgCard(
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const VgIconBadge(icon: Icons.table_chart_outlined, color: Color(0xFF1E7B45), size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Rekap Ukuran ${order.customer.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.sell_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Pesanan #${order.orderNumber}', style: const TextStyle(fontSize: 12.5, color: AppColors.primary))),
                    ]),
                  ]),
                ),
                VgPill(
                  label: complete ? '100% Valid' : (sizes.isEmpty ? 'Belum Ada' : 'Sebagian'),
                  color: complete ? AppColors.success : AppColors.warning,
                  background: complete ? AppColors.successBg : AppColors.warningBg,
                  dot: true,
                  fontSize: 10.5,
                ),
              ]),
              const SizedBox(height: 14),
              VgInset(
                color: AppColors.beigeSoft,
                child: Row(children: [
                  _Summary(label: 'Total Pesanan', value: '${order.totalQuantity} Stel'),
                  _Summary(label: 'Variasi Ukuran', value: sizes.isEmpty ? '-' : sizes.map((e) => e.key).join(', ')),
                  _Summary(label: 'Kelengkapan', value: complete ? 'Lengkap' : '${order.sizedQuantity}/${order.totalQuantity}', color: complete ? AppColors.success : AppColors.warning),
                ]),
              ),
            ]),
          ),
          if (sizes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Distribusi Ukuran Seragam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              Text('${sizes.length} Kluster', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sizes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = sizes[i];
                  final isMax = e.value == maxQty && sizes.length > 1;
                  final tileWidth = ((MediaQuery.of(context).size.width - 32 - 8 * 3) / 4).clamp(72.0, 120.0);
                  return Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: tileWidth,
                      decoration: BoxDecoration(
                        color: isMax ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isMax ? AppColors.primary : AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: isMax ? Colors.white.withValues(alpha: 0.2) : AppColors.beige, shape: BoxShape.circle),
                          child: FittedBox(child: Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isMax ? Colors.white : AppColors.primary))),
                        ),
                        const SizedBox(height: 4),
                        Text('${e.value}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isMax ? Colors.white : AppColors.textPrimary)),
                        Text(isMax ? 'Mayoritas' : 'Stel', style: TextStyle(fontSize: 11, color: isMax ? Colors.white70 : AppColors.primary)),
                      ]),
                    ),
                    if (isMax)
                      Positioned(
                        right: 4,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                          child: const Text('MAX', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.onGold)),
                        ),
                      ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(child: Text('Rincian Item & Ukuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              VgPill(label: '${shown.length} dari ${rows.length}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
              if (rows.length > _preview) ...[
                const SizedBox(width: 8),
                TapScale(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll ? 'Ringkas' : 'Lihat Semua ›', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(children: [
                Container(
                  color: AppColors.beige,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: const Row(children: [
                    SizedBox(width: 34, child: Text('NO', style: _headerStyle)),
                    Expanded(child: Text('NAMA ITEM', style: _headerStyle)),
                    SizedBox(width: 60, child: Center(child: Text('UKURAN', style: _headerStyle))),
                    SizedBox(width: 60, child: Text('JUMLAH', textAlign: TextAlign.right, style: _headerStyle)),
                  ]),
                ),
                for (var i = 0; i < shown.length; i++)
                  Container(
                    color: i.isEven ? AppColors.surface : AppColors.beigeSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(children: [
                      SizedBox(width: 34, child: Text((i + 1).toString().padLeft(2, '0'), style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600))),
                      Expanded(child: Text(shown[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: _sizeRank(shown[i].size!) >= 4 ? AppColors.warningBg : AppColors.beige, borderRadius: BorderRadius.circular(6)),
                            child: Text(shown[i].size!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                        ),
                      ),
                      SizedBox(width: 60, child: Text('${shown[i].quantity} stel', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                    ]),
                  ),
                Container(
                  width: double.infinity,
                  color: AppColors.beigeSoft,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text.rich(
                    TextSpan(style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), children: [
                      const TextSpan(text: 'Menampilkan '),
                      TextSpan(text: '${shown.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const TextSpan(text: ' dari total '),
                      TextSpan(text: '${order.sizedQuantity}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const TextSpan(text: ' stel berukuran'),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),
          ] else
            const VgCard(child: Text('Pelanggan belum melampirkan ukuran pada pesanan ini.', style: TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),
          if (readyForProduction)
            VgInset(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const VgIconBadge(icon: Icons.lightbulb_outline_rounded, color: AppColors.goldDark, background: Color(0xFFFFE08A), size: 34, circle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Siap Produksi Cutting & Bordir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Seluruh ${order.totalQuantity} stel sudah memiliki ukuran. Data siap dikirim ke workshop untuk pemotongan pola kain dan bordir.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.45),
                    ),
                  ]),
                ),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: order.sizeBreakdown.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  VgButton(
                    label: 'Salin Tabel untuk Excel',
                    icon: Icons.table_view_outlined,
                    expanded: true,
                    height: 50,
                    onPressed: () => _copy(_csv(order), 'Tabel ukuran disalin. Tempel langsung di Excel.'),
                  ),
                  const SizedBox(height: 10),
                  VgButton(
                    label: 'Salin Rekap untuk Workshop',
                    icon: Icons.ios_share_rounded,
                    style: VgButtonStyle.outline,
                    expanded: true,
                    height: 48,
                    onPressed: () => _copy(sizeRecapText(order), 'Rekap ukuran disalin.'),
                  ),
                ]),
              ),
            ),
    );
  }
}

const _headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary);

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Summary({required this.label, required this.value, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}
