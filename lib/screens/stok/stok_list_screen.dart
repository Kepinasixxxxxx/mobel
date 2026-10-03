import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import 'product_form_screen.dart';
import 'stok_detail_screen.dart';

enum _Sort { stok, nama, harga }

class StokListScreen extends StatefulWidget {
  const StokListScreen({super.key});

  @override
  State<StokListScreen> createState() => _StokListScreenState();
}

class _StokListScreenState extends State<StokListScreen> {
  String? _categoryId;
  String _query = '';
  _Sort _sort = _Sort.stok;
  DateTime? _syncedAt;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final products = context.read<ProductProvider>();
      final rentals = context.read<RentalProvider>();
      await Future.wait([
        if (products.products.isEmpty) products.fetchAll(),
        if (rentals.rentalOrders.isEmpty) rentals.fetchRentals(),
      ]);
      if (mounted) setState(() => _syncedAt = DateTime.now());
    });
  }

  Future<void> _refresh() async {
    await Future.wait([context.read<ProductProvider>().fetchAll(), context.read<RentalProvider>().fetchRentals()]);
    if (mounted) setState(() => _syncedAt = DateTime.now());
  }

  String _sortLabel(_Sort s) => switch (s) { _Sort.stok => 'Stok', _Sort.nama => 'Nama', _Sort.harga => 'Harga' };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final rentals = context.watch<RentalProvider>();
    final all = provider.products;
    final total = all.fold<int>(0, (s, p) => s + p.totalStockRent);
    final rented = all.fold<int>(0, (s, p) => s + rentals.rentedQty(p.id));
    final service = all.fold<int>(0, (s, p) => s + p.totalInService);
    final ready = (total - rented - service).clamp(0, total);
    int pct(int v) => total == 0 ? 0 : (v * 100 / total).round();

    final list = provider.filtered(categoryId: _categoryId, query: _query);
    int readyOf(Product p) => (p.totalStockRent - rentals.rentedQty(p.id) - p.totalInService).clamp(0, p.totalStockRent);
    switch (_sort) {
      case _Sort.stok:
        list.sort((a, b) => readyOf(b).compareTo(readyOf(a)));
        break;
      case _Sort.nama:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _Sort.harga:
        list.sort((a, b) => (b.basePriceRent ?? 0).compareTo(a.basePriceRent ?? 0));
        break;
    }

    if (provider.isLoading && all.isEmpty) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('PUSAT LOGISTIK KOSTUM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 2),
                const Text('Manajemen Stok', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
            ),
            TapScale(
              onTap: _refresh,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          VgButton(
            label: 'Tambah Item Kostum',
            icon: Icons.add_rounded,
            expanded: true,
            height: 46,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _StatTile(label: 'Total Koleksi', value: '$total', caption: '${provider.categories.length} Kategori Utama', icon: Icons.inventory_2_outlined),
              _StatTile(label: 'Tersedia Gudang', value: '$ready', caption: '${pct(ready)}% Unit Ready', icon: Icons.check_circle_outline_rounded, valueColor: AppColors.success, dot: AppColors.success),
              _StatTile(label: 'Sedang Disewa', value: '$rented', caption: '${pct(rented)}% Okupansi Aktif', icon: Icons.event_available_outlined),
              _StatTile(label: 'Laundry / Servis', value: '$service', caption: 'Perawatan berkala', icon: Icons.local_laundry_service_outlined, valueColor: AppColors.gold),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari jenis kostum, kategori…',
                    hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(label: 'Semua Kategori', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
                for (final c in provider.categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(label: c.name, selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Flexible(child: Text('Katalog Kostum', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
            const SizedBox(width: 8),
            VgPill(label: '${list.where((p) => p.isVisible).length} Aktif', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
            const Spacer(),
            PopupMenuButton<_Sort>(
              color: AppColors.surface,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => _Sort.values.map((s) => PopupMenuItem(value: s, child: Text('Urutkan: ${_sortLabel(s)}'))).toList(),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Urutkan: ', style: TextStyle(color: AppColors.textPrimary)),
                  TextSpan(text: _sortLabel(_sort), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ]), style: const TextStyle(fontSize: 12.5)),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const VgCard(child: Text('Belum ada produk pada filter ini.', style: TextStyle(color: AppColors.textSecondary)))
          else
            ...list.map((p) => _ProductCard(product: p)),
          Row(children: [
            const Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _syncedAt == null ? 'Menyinkronkan data gudang…' : 'Sinkronisasi data gudang: ${timeAgo(_syncedAt!).toLowerCase()}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.primary),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color valueColor;
  final Color? dot;

  const _StatTile({required this.label, required this.value, required this.caption, required this.icon, this.valueColor = AppColors.textPrimary, this.dot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
      child: Stack(children: [
        Positioned(
          right: -26,
          top: -26,
          child: Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.beigeSoft, shape: BoxShape.circle)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
            Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: valueColor)),
            const SizedBox(width: 4),
            const Text('Stel', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ]),
          Row(children: [
            if (dot != null) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 5)],
            Expanded(child: Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary))),
          ]),
        ]),
      ]),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rentals = context.watch<RentalProvider>();
    final total = product.totalStockRent;
    final rented = rentals.rentedQty(product.id).clamp(0, total);
    final ready = (total - rented - product.totalInService).clamp(0, total);
    final full = total > 0 && ready == 0;
    final returnDate = full ? rentals.earliestReturn(product.id) : null;
    final activeRental = full
        ? rentals.rentalsForProduct(product.id).where((o) => o.rental!.returnDate == returnDate).firstOrNull
        : null;
    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => StokDetailScreen(productId: product.id)));

    return VgCard(
      onTap: open,
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              VgThumb(url: product.imageUrls.isNotEmpty ? product.imageUrls.first : null, size: 82, radius: 8),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomRight: Radius.circular(8))),
                  child: Text(product.categoryName.split(' ').first, style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(product.isVisible ? 'TAMPIL DI KATALOG' : 'DISEMBUNYIKAN', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, letterSpacing: 0.4)),
                  ),
                  full
                      ? const VgPill(label: 'Penuh Disewa', color: AppColors.danger, background: AppColors.dangerBg, fontSize: 10.5)
                      : VgPill(label: '$ready Ready', color: AppColors.success, background: AppColors.beige, fontSize: 10.5),
                ]),
                const SizedBox(height: 2),
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('Kategori: ${product.categoryName}', style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
                const SizedBox(height: 6),
                if (product.basePriceRent != null)
                  Text.rich(TextSpan(children: [
                    TextSpan(text: Formatters.rupiah(product.basePriceRent!), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const TextSpan(text: ' / hari', style: TextStyle(fontSize: 12.5, color: AppColors.primary)),
                  ])),
              ]),
            ),
          ]),
        ),
        Container(
          color: AppColors.beigeSoft,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: full ? 'Tersedia: ' : 'Stok Tersedia: ', style: TextStyle(color: full ? AppColors.danger : AppColors.textSecondary)),
                  TextSpan(text: '$ready', style: TextStyle(fontWeight: FontWeight.w700, color: full ? AppColors.danger : AppColors.textPrimary)),
                  TextSpan(text: ' dari $total Stel', style: TextStyle(color: full ? AppColors.danger : AppColors.textSecondary)),
                ]), style: const TextStyle(fontSize: 12.5)),
              ),
              Text(full ? '100% Terpakai' : '$rented Sedang Disewa', style: TextStyle(fontSize: 12.5, color: full ? AppColors.danger : AppColors.primary)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 7,
                child: Row(children: [
                  if (ready > 0) Expanded(flex: ready, child: Container(color: const Color(0xFF22A447))),
                  if (rented > 0) Expanded(flex: rented, child: Container(color: full ? AppColors.danger : AppColors.primary)),
                  if (total == 0) Expanded(child: Container(color: AppColors.border)),
                ]),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: full
              ? Column(children: [
                  if (returnDate != null)
                    VgInset(
                      color: const Color(0xFFFFF4D6),
                      radius: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.event_available_outlined, size: 16, color: AppColors.goldDark),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Estimasi Kembali Gudang:', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary))),
                        Text(Formatters.date(returnDate), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: VgButton(
                        label: 'Ingatkan Pengembalian',
                        icon: Icons.notifications_active_outlined,
                        style: VgButtonStyle.soft,
                        height: 42,
                        onPressed: activeRental == null ? null : () => openChatWithCustomer(context, activeRental),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TapScale(
                      onTap: open,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                      ),
                    ),
                  ]),
                ])
              : Row(children: [
                  const Text('Ukuran: ', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                  Expanded(
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final v in product.variants)
                        Builder(builder: (context) {
                          final r = (v.stockRent - rentals.rentedQty(product.id, size: v.size) - v.stockInService).clamp(0, v.stockRent);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: r == 0 ? AppColors.dangerBg : AppColors.beige, borderRadius: BorderRadius.circular(6)),
                            child: Text('${v.size} ($r)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r == 0 ? AppColors.danger : AppColors.textPrimary)),
                          );
                        }),
                      if (product.variants.isEmpty) const Text('-', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                  TapScale(
                    onTap: open,
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Kelola', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.primary),
                    ]),
                  ),
                ]),
        ),
      ]),
    );
  }
}
