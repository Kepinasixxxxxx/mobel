import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/operations_models.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

const _tabs = [
  ('workshop', 'Workshop', Icons.precision_manufacturing_outlined),
  ('qc', 'QC', Icons.verified_outlined),
  ('kerusakan', 'Kerusakan', Icons.report_outlined),
  ('lainnya', 'Lainnya', Icons.photo_library_outlined),
];

class PhotoDocsScreen extends StatefulWidget {
  final String orderId;
  final String initialCategory;
  const PhotoDocsScreen({super.key, required this.orderId, this.initialCategory = 'workshop'});

  @override
  State<PhotoDocsScreen> createState() => _PhotoDocsScreenState();
}

class _PhotoDocsScreenState extends State<PhotoDocsScreen> {
  late String _tab = _tabs.any((t) => t.$1 == widget.initialCategory) ? widget.initialCategory : 'lainnya';
  final _title = TextEditingController();
  final List<XFile> _staged = [];
  bool _public = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final orders = context.read<OrderProvider>();
    Future.microtask(() => orders.fetchOrderDetail(widget.orderId));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String get _uploadCategory => _tab == 'lainnya' ? 'serah_terima' : _tab;

  List<OrderPhoto> _photosFor(List<OrderPhoto> all) =>
      _tab == 'lainnya' ? all.where((p) => p.category == 'serah_terima' || p.category == 'paket').toList() : all.where((p) => p.category == _tab).toList();

  Future<void> _upload() async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    final ok = await provider.uploadPhotos(widget.orderId, category: _uploadCategory, title: _title.text.trim(), isPublic: _public, files: _staged);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (ok) {
        _staged.clear();
        _title.clear();
      }
    });
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Foto berhasil diunggah.' : provider.errorMessage ?? 'Gagal mengunggah foto.')));
  }

  Future<void> _open(OrderPhoto photo) async {
    final provider = context.read<OrderProvider>();
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: InteractiveViewer(child: Image.network(photo.imageUrl, fit: BoxFit.contain))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(photo.title ?? 'Tanpa judul', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('${Formatters.dateTime(photo.createdAt)} · ${photo.isPublic ? 'Terlihat pelanggan' : 'Internal'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A8A)), onPressed: () => Navigator.pop(ctx, true)),
              IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(ctx, false)),
            ]),
          ),
        ]),
      ),
    );
    if (remove == true) await provider.deletePhoto(widget.orderId, photo.id);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Dokumentasi Foto'), body: Center(child: CircularProgressIndicator()));
    }
    final photos = _photosFor(order.photos);
    final tabLabel = _tabs.firstWhere((t) => t.$1 == _tab).$2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Dokumentasi Foto'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
            const Spacer(),
            Flexible(child: Text(order.customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.primary))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              for (final (key, label, icon) in _tabs)
                Expanded(
                  child: TapScale(
                    onTap: () => setState(() => _tab = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      decoration: BoxDecoration(color: _tab == key ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(icon, size: 16, color: _tab == key ? Colors.white : AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _tab == key ? Colors.white : AppColors.primary))),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Foto $tabLabel',
                subtitle: 'Ketuk foto untuk memperbesar atau menghapus',
                trailing: VgPill(label: '${photos.length} Foto', color: AppColors.success, background: AppColors.successBg),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final p in photos)
                    Stack(fit: StackFit.expand, children: [
                      VgPhotoTile(url: p.imageUrl, caption: p.title, onTap: () => _open(p)),
                      if (!p.isPublic)
                        const Positioned(left: 4, top: 4, child: VgPill(label: 'Internal', color: Colors.white, background: Color(0xAA000000), fontSize: 9.5, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2))),
                    ]),
                  for (var i = 0; i < _staged.length; i++) VgPhotoTile(file: _staged[i], caption: 'Belum diunggah', onRemove: () => setState(() => _staged.removeAt(i))),
                  VgAddPhotoTile(onTap: () async {
                    final picked = await pickPhotos(context);
                    if (picked.isNotEmpty) setState(() => _staged.addAll(picked.take(10 - _staged.length)));
                  }),
                ],
              ),
              if (photos.isEmpty && _staged.isEmpty) ...[
                const SizedBox(height: 10),
                const Text('Belum ada foto pada kategori ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ]),
          ),
          if (_staged.isNotEmpty)
            VgCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VgCardTitle(title: 'Keterangan ${_staged.length} Foto Baru'),
                const VgLabel('Judul'),
                VgTextField(controller: _title, hint: 'Contoh: Bordir nama siswa di dada kiri'),
                const SizedBox(height: 12),
                VgSwitchRow(
                  title: 'Tampilkan ke pelanggan',
                  subtitle: 'Matikan untuk foto internal workshop',
                  value: _public,
                  onChanged: (v) => setState(() => _public = v),
                ),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: _staged.isEmpty
          ? null
          : VgBottomBar(children: [
              VgButton(label: 'Unggah ${_staged.length} Foto', icon: Icons.cloud_upload_outlined, expanded: true, height: 52, loading: _uploading, onPressed: _upload),
              const SizedBox(height: 6),
            ]),
    );
  }
}
