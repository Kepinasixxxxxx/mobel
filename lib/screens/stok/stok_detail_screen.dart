import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../state/product_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/remote_image_tile.dart';
import '../../widgets/common/status_badge.dart';

class StokDetailScreen extends StatelessWidget {
  final String productId;
  const StokDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.productById(productId);
    if (product == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final totalRent = product.variants.fold(0, (sum, v) => sum + v.stockRent);
    final totalBuy = product.variants.fold(0, (sum, v) => sum + v.stockBuy);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Stok Item')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Stack(
            children: [
              RemoteImageTile(url: product.imageUrls.isNotEmpty ? product.imageUrls.first : null, label: product.name, height: 220),
              Positioned(
                left: 10,
                top: 10,
                child: TagChip(label: product.isVisible ? 'Tampil di Katalog' : 'Tersembunyi', color: product.isVisible ? AppColors.success : AppColors.textSecondary, background: AppColors.onPrimary),
              ),
              if (product.isCustomAvailable)
                Positioned(
                  right: 10,
                  top: 10,
                  child: const TagChip(label: 'Bisa Custom', color: AppColors.accent, background: AppColors.onPrimary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(product.categoryName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (product.description != null) ...[
            const SizedBox(height: 6),
            Text(product.description!, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Stok Sewa', style: TextStyle(color: AppColors.onPrimaryMuted, fontSize: 11)),
                    Text('$totalRent Stel', style: const TextStyle(color: AppColors.onPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.onPrimaryFaint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Stok Beli', style: TextStyle(color: AppColors.onPrimaryMuted, fontSize: 11)),
                    Text('$totalBuy Stel', style: const TextStyle(color: AppColors.onPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Harga',
            trailingIcon: const Icon(Icons.sell_outlined, color: AppColors.primary),
            children: [
              if (product.basePriceRent != null) InfoTile(label: 'Harga Sewa', value: '${Formatters.rupiah(product.basePriceRent!)} / hari'),
              if (product.basePriceBuy != null) InfoTile(label: 'Harga Beli', value: Formatters.rupiah(product.basePriceBuy!)),
            ],
          ),
          SectionCard(
            title: 'Breakdown Stok per Ukuran',
            subtitle: '${product.variants.length} Varian Ukuran',
            trailingIcon: const Icon(Icons.straighten, color: AppColors.primary),
            children: product.variants.isEmpty
                ? [const Text('Belum ada varian ukuran.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]
                : product.variants
                    .map((v) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(v.size, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                _MiniStat(label: 'Sewa', value: '${v.stockRent}'),
                                _MiniStat(label: 'Beli', value: '${v.stockBuy}'),
                              ]),
                            ),
                          ]),
                        ))
                    .toList(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await provider.toggleVisibility(product.id, !product.isVisible);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? (product.isVisible ? 'Produk disembunyikan dari katalog.' : 'Produk ditampilkan di katalog.') : provider.errorMessage ?? 'Gagal memperbarui.')));
            },
            icon: Icon(product.isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
            label: Text(product.isVisible ? 'Sembunyikan dari Katalog' : 'Tampilkan di Katalog'),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
