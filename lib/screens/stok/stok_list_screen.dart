import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../state/product_provider.dart';
import '../../widgets/common/status_badge.dart';
import 'stok_detail_screen.dart';

class StokListScreen extends StatefulWidget {
  const StokListScreen({super.key});

  @override
  State<StokListScreen> createState() => _StokListScreenState();
}

class _StokListScreenState extends State<StokListScreen> {
  String? _categoryId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    if (provider.products.isEmpty) Future.microtask(() => provider.fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final list = provider.filtered(categoryId: _categoryId, query: _query);
    final totalKoleksi = provider.products.fold<int>(0, (sum, p) => sum + p.totalStockRent);

    if (provider.isLoading && provider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: provider.fetchAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Row(children: [
            Expanded(child: _StatBox(label: 'Total Koleksi', value: '$totalKoleksi Stel', caption: '${provider.categories.length} Kategori')),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Total Produk', value: '${provider.products.length}', caption: '${provider.products.where((p) => p.isVisible).length} Aktif Tampil')),
          ]),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: 'Cari jenis kostum, kategori...', prefixIcon: Icon(Icons.search, size: 20)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(label: 'Semua Kategori', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
                ...provider.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(label: c.name, selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Katalog Kostum · ${list.length} Item', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Belum ada produk', style: TextStyle(color: AppColors.textSecondary))))
          else
            ...list.map((p) => _ProductCard(product: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StokDetailScreen(productId: p.id))))),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _StatBox({required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(caption, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ready = product.totalStockRent;
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.background,
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(product.imageUrls.first, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom, color: AppColors.textSecondary))
                      : const Icon(Icons.checkroom, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(product.categoryName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (product.basePriceRent != null) Text('${Formatters.rupiah(product.basePriceRent!)} / hari', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
              TagChip(label: ready > 0 ? '$ready Ready' : 'Kosong', color: ready > 0 ? AppColors.success : AppColors.danger, background: ready > 0 ? AppColors.successBg : AppColors.background),
            ]),
            if (product.variants.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: product.variants.map((v) => TagChip(label: '${v.size} (${v.stockRent})', color: AppColors.textSecondary, background: AppColors.background)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
