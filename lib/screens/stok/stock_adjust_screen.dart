import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

class _Draft {
  final String size;
  int stockRent;
  int stockBuy;
  int inService;
  final TextEditingController note;
  final TextEditingController price;

  _Draft(ProductVariant v)
      : size = v.size,
        stockRent = v.stockRent,
        stockBuy = v.stockBuy,
        inService = v.stockInService,
        note = TextEditingController(text: v.serviceNote ?? ''),
        price = TextEditingController(text: v.priceRentOverride?.toStringAsFixed(0) ?? '');
}

class StockAdjustScreen extends StatefulWidget {
  final String productId;
  const StockAdjustScreen({super.key, required this.productId});

  @override
  State<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  List<_Draft>? _drafts;
  bool _saving = false;

  @override
  void dispose() {
    for (final d in _drafts ?? <_Draft>[]) {
      d.note.dispose();
      d.price.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Product product) async {
    final provider = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await provider.updateVariants(product.id, [
      for (final d in _drafts!)
        {
          'size': d.size,
          'stockRent': d.stockRent,
          'stockBuy': d.stockBuy,
          'stockInService': d.inService,
          'serviceNote': d.inService > 0 ? d.note.text.trim() : null,
          'priceRentOverride': double.tryParse(d.price.text.trim()),
        },
    ]);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Stok berhasil diperbarui.' : provider.errorMessage ?? 'Gagal menyimpan stok.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().productById(widget.productId);
    final rentals = context.watch<RentalProvider>();
    if (product == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Atur Stok Unit'), body: Center(child: Text('Produk tidak ditemukan.')));
    }
    _drafts ??= product.variants.map(_Draft.new).toList();
    final drafts = _drafts!;

    final total = drafts.fold<int>(0, (s, d) => s + d.stockRent);
    final service = drafts.fold<int>(0, (s, d) => s + d.inService);
    final rented = rentals.rentedQty(product.id);
    final ready = (total - rented - service).clamp(0, total);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Atur Stok Unit'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VgThumb(url: product.imageUrls.isNotEmpty ? product.imageUrls.first : null, size: 64, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (product.sku != null) Text(product.sku!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6)),
                    Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(
                      '${product.categoryName}${product.basePriceRent != null ? ' · ${Formatters.rupiah(product.basePriceRent!)} / hari' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.primary),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              VgInset(
                child: Row(children: [
                  _Summary(label: 'Total', value: total),
                  _Summary(label: 'Ready', value: ready, color: AppColors.success),
                  _Summary(label: 'Disewa', value: rented),
                  _Summary(label: 'Servis', value: service, color: AppColors.goldDark),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(title: 'Stok per Ukuran', subtitle: 'Ketuk angka untuk mengetik jumlah langsung'),
              for (final d in drafts) ...[
                _SizeEditor(
                  draft: d,
                  rented: rentals.rentedQty(product.id, size: d.size),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 10),
              ],
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(title: 'Harga Khusus per Ukuran', subtitle: 'Kosongkan untuk memakai harga dasar'),
              for (final d in drafts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    _SizeBadge(size: d.size),
                    const SizedBox(width: 10),
                    Expanded(
                      child: VgTextField(
                        controller: d.price,
                        prefix: 'Rp',
                        suffix: '/ hari',
                        strong: true,
                        hint: product.basePriceRent?.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(label: 'Simpan Perubahan Stok', icon: Icons.edit_note_rounded, expanded: true, height: 52, loading: _saving, onPressed: () => _save(product)),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Summary({required this.label, required this.value, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11.5, color: color == AppColors.textPrimary ? AppColors.primary : color)),
        Text('$value', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class _SizeBadge extends StatelessWidget {
  final String size;
  final bool warn;
  const _SizeBadge({required this.size, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: warn ? AppColors.warningBg : AppColors.beige, borderRadius: BorderRadius.circular(8)),
      child: Text(size, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: warn ? AppColors.goldDark : AppColors.primary)),
    );
  }
}

class _SizeEditor extends StatelessWidget {
  final _Draft draft;
  final int rented;
  final VoidCallback onChanged;
  const _SizeEditor({required this.draft, required this.rented, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final maintenance = draft.inService > 0;
    final ready = (draft.stockRent - rented - draft.inService).clamp(0, draft.stockRent);
    return VgInset(
      color: maintenance ? const Color(0xFFFFF4D6) : AppColors.beige,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _SizeBadge(size: draft.size, warn: maintenance),
          const SizedBox(width: 10),
          Expanded(child: Text('Ukuran ${draft.size}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          maintenance
              ? const VgPill(label: 'Maintenance', color: AppColors.goldDark, background: AppColors.warningBg, icon: Icons.build_outlined, fontSize: 10.5)
              : VgPill(label: '$ready Ready', color: AppColors.success, background: AppColors.successBg, dot: true, fontSize: 10.5),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(child: Text('Total unit sewa', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
          VgStepper(
            value: draft.stockRent,
            min: rented + draft.inService,
            onChanged: (v) {
              draft.stockRent = v;
              onChanged();
            },
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Text('Sedang servis / cuci', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
          VgStepper(
            value: draft.inService,
            max: (draft.stockRent - rented).clamp(0, draft.stockRent),
            onChanged: (v) {
              draft.inService = v;
              onChanged();
            },
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Text('Stok jual', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
          VgStepper(
            value: draft.stockBuy,
            onChanged: (v) {
              draft.stockBuy = v;
              onChanged();
            },
          ),
        ]),
        if (rented > 0) ...[
          const SizedBox(height: 6),
          Text('$rented unit sedang disewa, total tidak bisa di bawah jumlah ini.', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
        ],
        if (maintenance) ...[
          const SizedBox(height: 10),
          const VgLabel('Catatan servis'),
          VgTextField(controller: draft.note, hint: 'Contoh: jahit ulang kancing, selesai 30 Sep', color: AppColors.surface),
        ],
      ]),
    );
  }
}
