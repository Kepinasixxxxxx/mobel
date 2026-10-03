import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../models/product_model.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../../widgets/vg/vg_form.dart';
import '../penyewaan/penyewaan_detail_screen.dart';
import 'stock_adjust_screen.dart';

class StokDetailScreen extends StatefulWidget {
  final String productId;
  const StokDetailScreen({super.key, required this.productId});

  @override
  State<StokDetailScreen> createState() => _StokDetailScreenState();
}

class _StokDetailScreenState extends State<StokDetailScreen> {
  int _image = 0;
  bool _showAllHistory = false;

  void _zoom(String url) {
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

  Future<void> _toggleVisibility(Product product) async {
    final provider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.toggleVisibility(product.id, !product.isVisible);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? (product.isVisible ? 'Produk disembunyikan dari katalog.' : 'Produk ditampilkan di katalog.') : provider.errorMessage ?? 'Gagal memperbarui.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().productById(widget.productId);
    final rentals = context.watch<RentalProvider>();
    if (product == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Detail Stok Item'), body: Center(child: Text('Produk tidak ditemukan.')));
    }

    final total = product.totalStockRent;
    final rented = rentals.rentedQty(product.id).clamp(0, total);
    final service = product.totalInService;
    final ready = (total - rented - service).clamp(0, total);
    final history = rentals.rentalsForProduct(product.id);
    final year = DateTime.now().year;
    final revenue = history
        .where((o) => o.rental!.pickupDate.year == year && o.rental!.status != RentalStatus.dipesan)
        .expand((o) => o.items)
        .where((i) => i.productId == product.id)
        .fold<double>(0, (s, i) => s + i.subtotal);
    final images = product.imageUrls;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Detail Stok Item'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              child: Stack(fit: StackFit.expand, children: [
                images.isEmpty
                    ? Container(color: AppColors.beige, child: const Icon(Icons.checkroom_rounded, size: 72, color: AppColors.primary))
                    : Image.network(images[_image], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige, child: const Icon(Icons.checkroom_rounded, size: 72, color: AppColors.primary))),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC3A0008)], stops: [0.45, 1])),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: VgPill(
                    label: product.conditionGrade != null
                        ? 'Grade ${product.conditionGrade} · ${const {'A': 'Sangat Terawat', 'B': 'Baik', 'C': 'Perlu Servis'}[product.conditionGrade] ?? ''}'
                        : (product.isVisible ? 'Tampil di Katalog' : 'Disembunyikan'),
                    color: product.isVisible ? AppColors.success : AppColors.textSecondary,
                    background: Colors.white,
                    dot: true,
                    fontSize: 11,
                  ),
                ),
                if (product.isCustomAvailable)
                  const Positioned(right: 12, top: 12, child: VgPill(label: 'Bisa Custom', color: AppColors.onGold, background: AppColors.goldLight, icon: Icons.star_rounded, fontSize: 11)),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 60,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(product.sku != null ? 'SKU Inventaris' : 'Kategori', style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                    Text(product.sku != null ? '#${product.sku}' : product.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
                if (images.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: TapScale(
                      onTap: () => _zoom(images[_image]),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                        child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) => TapScale(
                  onTap: () => setState(() => _image = i),
                  child: VgPill(
                    label: 'Foto ${i + 1}',
                    color: i == _image ? Colors.white : AppColors.primary,
                    background: i == _image ? AppColors.primary : AppColors.beige,
                    icon: Icons.photo_outlined,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(product.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2))),
            TapScale(
              onTap: () => _toggleVisibility(product),
              child: VgIconBadge(icon: product.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 34, circle: true),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            [product.categoryName, if (product.description != null && product.description!.isNotEmpty) product.description!].join(' • '),
            style: const TextStyle(fontSize: 13.5, color: AppColors.primary, height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.sensors_rounded, size: 16, color: AppColors.goldLight),
                const SizedBox(width: 6),
                const Expanded(child: Text('KETERSEDIAAN REAL-TIME', style: TextStyle(fontSize: 12, color: Colors.white, letterSpacing: 0.8))),
                VgPill(label: 'Sinkron Data Sewa', color: Colors.white, background: Colors.white.withValues(alpha: 0.15), dot: true, fontSize: 10.5),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total Inventaris Sewa', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text('$total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(width: 6),
                      const Text('Stel', style: TextStyle(fontSize: 14, color: Colors.white)),
                    ]),
                  ]),
                ),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Rasio Siap Pakai', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text('${total == 0 ? 0 : (ready * 100 / total).round()}% Available', textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _AvailTile(icon: Icons.inventory_2_outlined, title: 'Di Rak', value: ready, caption: 'Siap Sewa', color: const Color(0xFFFF8A8A)),
                  _AvailTile(icon: Icons.local_shipping_outlined, title: 'Di Luar', value: rented, caption: 'Disewa Aktif', color: Colors.white70),
                  _AvailTile(icon: Icons.local_laundry_service_outlined, title: 'Servis', value: service, caption: 'Cuci / Jahit', color: AppColors.goldLight),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.straighten_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Breakdown Stok Unit Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            Text('${product.variants.length} Variasi Ukuran', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          if (product.variants.isEmpty)
            const VgCard(child: Text('Belum ada varian ukuran.', style: TextStyle(color: AppColors.textSecondary)))
          else
            for (final v in product.variants) _SizeCard(variant: v, rented: rentals.rentedQty(product.id, size: v.size)),
          const SizedBox(height: 6),
          if (product.accessories.isNotEmpty)
            VgCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VgCardTitle(
                  title: 'Aset & Aksesoris Wajib',
                  subtitle: 'Dicek saat serah terima & pengembalian',
                  trailing: VgPill(label: '${product.accessories.length} Item', color: AppColors.primary, background: AppColors.beige),
                ),
                for (final a in product.accessories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VgInset(
                      child: Row(children: [
                        const Icon(Icons.workspace_premium_outlined, size: 20, color: AppColors.goldDark),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        Text('${a.quantityPerSet} / stel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ]),
                    ),
                  ),
              ]),
            ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Riwayat & Utilisasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                if (history.length > 3)
                  TapScale(
                    onTap: () => setState(() => _showAllHistory = !_showAllHistory),
                    child: Text(_showAllHistory ? 'Ringkas' : 'Lihat Semua', style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: 12),
              VgInset(
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.payments_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Omset Sewa Item Ini', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(Formatters.rupiah(revenue), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary))),
                    ]),
                  ),
                  VgPill(label: 'Tahun $year', color: AppColors.textPrimary, background: AppColors.surface, fontSize: 11),
                ]),
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                const Text('Belum ada riwayat penyewaan untuk item ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
              else
                for (final o in (_showAllHistory ? history : history.take(3)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TapScale(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PenyewaanDetailScreen(orderId: o.id))),
                      child: VgInset(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: o.rental!.status == RentalStatus.dikembalikan ? AppColors.success : AppColors.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(o.customer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              Text('#${o.orderNumber}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(
                              '${o.items.where((i) => i.productId == product.id).fold<int>(0, (s, i) => s + i.quantity)} Stel',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              o.rental!.status == RentalStatus.dikembalikan ? 'Selesai ${Formatters.date(o.rental!.actualReturnDate ?? o.rental!.returnDate)}' : 'Kembali ${Formatters.date(o.rental!.returnDate)}',
                              style: TextStyle(fontSize: 11.5, color: o.rental!.status == RentalStatus.dikembalikan ? AppColors.success : AppColors.primary),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(
          label: 'Update Status & Stok Unit',
          icon: Icons.edit_note_rounded,
          expanded: true,
          height: 52,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockAdjustScreen(productId: product.id))),
        ),
        const SizedBox(height: 10),
        VgButton(
          label: product.isVisible ? 'Sembunyikan dari Katalog' : 'Tampilkan di Katalog',
          icon: product.isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          style: VgButtonStyle.soft,
          expanded: true,
          height: 44,
          onPressed: () => _toggleVisibility(product),
        ),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _AvailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final String caption;
  final Color color;

  const _AvailTile({required this.icon, required this.title, required this.value, required this.caption, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: color))),
          ]),
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(caption, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final ProductVariant variant;
  final int rented;

  const _SizeCard({required this.variant, required this.rented});

  @override
  Widget build(BuildContext context) {
    final total = variant.stockRent;
    final ready = (total - rented - variant.stockInService).clamp(0, total);
    final empty = ready == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
      child: Column(children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: empty ? AppColors.warningBg : AppColors.beige, borderRadius: BorderRadius.circular(8)),
            child: FittedBox(child: Text(variant.size, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: empty ? AppColors.goldDark : AppColors.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Ukuran ${variant.size}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          if (variant.stockInService > 0)
            const VgPill(label: 'Maintenance', color: AppColors.goldDark, background: AppColors.warningBg, icon: Icons.build_outlined, fontSize: 10.5)
          else if (empty)
            const VgPill(label: 'Habis', color: AppColors.danger, background: AppColors.dangerBg, icon: Icons.inventory_outlined, fontSize: 10.5)
          else
            const VgPill(label: 'Aktif', color: AppColors.success, background: AppColors.successBg, dot: true, fontSize: 10.5),
        ]),
        if (variant.serviceNote != null && variant.stockInService > 0) ...[
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: Text(variant.serviceNote!, style: const TextStyle(fontSize: 11.5, color: AppColors.goldDark))),
        ],
        const SizedBox(height: 10),
        VgInset(
          padding: const EdgeInsets.symmetric(vertical: 8),
          radius: 8,
          child: Row(children: [
            _Cell(label: 'Total', value: total, color: AppColors.textPrimary),
            _Cell(label: 'Ready', value: ready, color: empty ? AppColors.danger : AppColors.success),
            _Cell(label: 'Disewa', value: rented, color: AppColors.primary),
            _Cell(label: 'Servis', value: variant.stockInService, color: variant.stockInService > 0 ? AppColors.goldDark : AppColors.textPrimary),
          ]),
        ),
      ]),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Cell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: color)),
        Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    );
  }
}
