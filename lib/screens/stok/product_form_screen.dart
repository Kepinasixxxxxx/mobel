import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/product_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';
import 'stok_detail_screen.dart';

class _VariantRow {
  final TextEditingController size;
  int stockRent = 0;
  int stockBuy = 0;
  _VariantRow(String s) : size = TextEditingController(text: s);
}

class _AccessoryRow {
  final TextEditingController name;
  int qty = 1;
  _AccessoryRow(String n) : name = TextEditingController(text: n);
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _maxPhotos = 10;

  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _description = TextEditingController();
  final _priceRent = TextEditingController();
  final _priceBuy = TextEditingController();
  final List<XFile> _photos = [];
  final List<_VariantRow> _variants = [_VariantRow('S'), _VariantRow('M'), _VariantRow('L'), _VariantRow('XL')];
  final List<_AccessoryRow> _accessories = [];
  String? _categoryId;
  String _grade = 'A';
  bool _visible = true;
  bool _custom = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final products = context.read<ProductProvider>();
      if (products.categories.isEmpty) products.fetchAll();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _description, _priceRent, _priceBuy]) {
      c.dispose();
    }
    for (final v in _variants) {
      v.size.dispose();
    }
    for (final a in _accessories) {
      a.name.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '').trim());

  Future<void> _addPhotos() async {
    final picked = await pickPhotos(context);
    if (picked.isEmpty) return;
    setState(() => _photos.addAll(picked.take(_maxPhotos - _photos.length)));
  }

  String? _validate() {
    if (_name.text.trim().length < 2) return 'Nama kostum minimal 2 karakter.';
    if (_categoryId == null) return 'Pilih kategori kostum.';
    if (_num(_priceRent) == null && _num(_priceBuy) == null) return 'Isi harga sewa atau harga jual.';
    final sizes = _variants.map((v) => v.size.text.trim().toUpperCase()).where((s) => s.isNotEmpty).toList();
    if (sizes.isEmpty) return 'Tambahkan minimal satu ukuran.';
    if (sizes.toSet().length != sizes.length) return 'Ada ukuran yang sama lebih dari sekali.';
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    final messenger = ScaffoldMessenger.of(context);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    final created = await provider.createProduct({
      'categoryId': _categoryId,
      'name': _name.text.trim(),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      'basePriceRent': ?_num(_priceRent),
      'basePriceBuy': ?_num(_priceBuy),
      'isVisible': _visible,
      'isCustomAvailable': _custom,
      if (_sku.text.trim().isNotEmpty) 'sku': _sku.text.trim().toUpperCase(),
      'conditionGrade': _grade,
      'variants': [
        for (final v in _variants)
          if (v.size.text.trim().isNotEmpty) {'size': v.size.text.trim().toUpperCase(), 'stockRent': v.stockRent, 'stockBuy': v.stockBuy},
      ],
      'accessories': [
        for (final a in _accessories)
          if (a.name.text.trim().isNotEmpty) {'name': a.name.text.trim(), 'quantityPerSet': a.qty},
      ],
    }, _photos);
    if (!mounted) return;
    setState(() => _saving = false);
    if (created == null) {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan kostum.')));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Kostum baru tersimpan dan siap disewakan.')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StokDetailScreen(productId: created.id)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Tambah Item Kostum'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Foto Kostum',
                subtitle: 'Maks. $_maxPhotos foto • foto pertama jadi sampul katalog',
                trailing: VgPill(label: '${_photos.length}/$_maxPhotos', color: AppColors.primary, background: AppColors.beige),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    VgPhotoTile(file: _photos[i], caption: i == 0 ? 'Sampul' : null, onRemove: () => setState(() => _photos.removeAt(i))),
                  if (_photos.length < _maxPhotos) VgAddPhotoTile(onTap: _addPhotos),
                ],
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(title: 'Informasi Dasar', subtitle: 'Tampil di katalog website pelanggan', trailing: VgIconBadge(icon: Icons.checkroom_rounded, size: 38)),
              const VgLabel('Nama Kostum'),
              VgTextField(controller: _name, hint: 'Contoh: Kostum Tari Gandrung Banyuwangi'),
              const SizedBox(height: 12),
              const VgLabel('Kode SKU (opsional)'),
              VgTextField(controller: _sku, icon: Icons.qr_code_2_rounded, hint: 'KST-TGD-01'),
              const SizedBox(height: 12),
              const VgLabel('Kategori'),
              categories.isEmpty
                  ? const Text('Memuat kategori…', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
                  : VgChoiceChips<String>(options: [for (final c in categories) (c.id, c.name)], selected: _categoryId, onSelected: (v) => setState(() => _categoryId = v)),
              const SizedBox(height: 12),
              const VgLabel('Deskripsi'),
              VgTextField(controller: _description, maxLines: 3, hint: 'Bahan, detail payet, kelengkapan…'),
              const SizedBox(height: 12),
              const VgLabel('Grade Kondisi'),
              VgChoiceChips<String>(
                options: const [('A', 'A · Sangat Terawat'), ('B', 'B · Baik'), ('C', 'C · Perlu Servis')],
                selected: _grade,
                onSelected: (v) => setState(() => _grade = v),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(
                title: 'Harga',
                subtitle: 'Harga dasar, bisa ditimpa per ukuran',
                trailing: VgIconBadge(icon: Icons.sell_outlined, color: AppColors.goldDark, background: AppColors.warningBg, size: 38),
              ),
              const VgLabel('Harga Sewa'),
              VgTextField(controller: _priceRent, prefix: 'Rp', suffix: '/ hari', strong: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 12),
              const VgLabel('Harga Jual (opsional)'),
              VgTextField(controller: _priceBuy, prefix: 'Rp', strong: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Varian Ukuran & Stok',
                subtitle: 'Jumlah unit fisik di gudang. Ketuk angka untuk mengetik langsung.',
                trailing: VgPill(label: '${_variants.length} Ukuran', color: AppColors.primary, background: AppColors.beige),
              ),
              for (var i = 0; i < _variants.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VgInset(
                    child: Column(children: [
                      Row(children: [
                        SizedBox(
                          width: 90,
                          child: VgTextField(controller: _variants[i].size, hint: 'Ukuran', color: AppColors.surface, strong: true),
                        ),
                        const Spacer(),
                        TapScale(
                          onTap: _variants.length > 1 ? () => setState(() => _variants.removeAt(i).size.dispose()) : null,
                          child: Icon(Icons.delete_outline_rounded, color: _variants.length > 1 ? AppColors.danger : AppColors.border),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Expanded(child: Text('Stok sewa', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
                        VgStepper(value: _variants[i].stockRent, onChanged: (v) => setState(() => _variants[i].stockRent = v)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Expanded(child: Text('Stok jual', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
                        VgStepper(value: _variants[i].stockBuy, onChanged: (v) => setState(() => _variants[i].stockBuy = v)),
                      ]),
                    ]),
                  ),
                ),
              VgButton(label: 'Tambah Ukuran', icon: Icons.add_rounded, style: VgButtonStyle.soft, expanded: true, height: 42, onPressed: () => setState(() => _variants.add(_VariantRow('')))),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Aksesoris Wajib',
                subtitle: 'Ikut dicek saat serah terima & pengembalian',
                trailing: VgPill(label: '${_accessories.length} Item', color: AppColors.primary, background: AppColors.beige),
              ),
              for (var i = 0; i < _accessories.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VgInset(
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: VgTextField(controller: _accessories[i].name, hint: 'Nama aksesoris', color: AppColors.surface)),
                        const SizedBox(width: 8),
                        TapScale(onTap: () => setState(() => _accessories.removeAt(i).name.dispose()), child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Expanded(child: Text('Jumlah per stel', style: TextStyle(fontSize: 12.5, color: AppColors.primary))),
                        VgStepper(value: _accessories[i].qty, min: 1, onChanged: (v) => setState(() => _accessories[i].qty = v)),
                      ]),
                    ]),
                  ),
                ),
              VgButton(label: 'Tambah Aksesoris', icon: Icons.add_rounded, style: VgButtonStyle.soft, expanded: true, height: 42, onPressed: () => setState(() => _accessories.add(_AccessoryRow('')))),
            ]),
          ),
          VgCard(
            child: Column(children: [
              VgSwitchRow(title: 'Tampil di Katalog', subtitle: 'Pelanggan bisa melihat & memesan', value: _visible, onChanged: (v) => setState(() => _visible = v)),
              const Divider(height: 20),
              VgSwitchRow(title: 'Bisa Pesan Custom', subtitle: 'Muncul di formulir pesanan custom', value: _custom, onChanged: (v) => setState(() => _custom = v)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(label: 'Simpan Kostum', icon: Icons.save_outlined, expanded: true, height: 52, loading: _saving, onPressed: _save),
        const SizedBox(height: 6),
      ]),
    );
  }
}
