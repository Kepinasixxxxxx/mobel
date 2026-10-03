import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../state/auth_provider.dart';
import '../../state/order_provider.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';
import 'surat_perjanjian_screen.dart';

String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseTime(String? s) {
  if (s == null || !s.contains(':')) return null;
  final parts = s.split(':');
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
}

class HandoverScreen extends StatefulWidget {
  final String orderId;
  const HandoverScreen({super.key, required this.orderId});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final _deposit = TextEditingController();
  final _note = TextEditingController(text: 'Diserahkan dalam kondisi baik & lengkap.');
  final List<XFile> _photos = [];
  final Set<String> _checked = {};
  XFile? _agreement;
  TimeOfDay _pickup = TimeOfDay.now();
  TimeOfDay _return = const TimeOfDay(hour: 18, minute: 0);
  bool _agreed = false;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _deposit.dispose();
    _note.dispose();
    super.dispose();
  }

  List<(String, String)> _checklist(Order order, ProductProvider products) {
    final list = <(String, String)>[];
    final byProduct = <String, List<String>>{};
    for (final item in order.items) {
      list.add(('item-${item.id}', '${item.quantity}x ${item.name}${item.size != null ? ' (${item.size})' : ''}'));
      if (item.productId != null) byProduct.putIfAbsent(item.productId!, () => []).add(item.id);
    }
    for (final entry in byProduct.entries) {
      final product = products.productById(entry.key);
      if (product == null) continue;
      final sets = order.items.where((i) => i.productId == entry.key).fold<int>(0, (s, i) => s + i.quantity);
      for (final acc in product.accessories) {
        list.add(('acc-${entry.key}-${acc.name}', '${sets * acc.quantityPerSet}x ${acc.name}'));
      }
    }
    return list;
  }

  Future<void> _pickTime(bool pickup) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: pickup ? _pickup : _return,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return;
    setState(() => pickup ? _pickup = picked : _return = picked);
  }

  Future<void> _submit(Order order) async {
    final rentals = context.read<RentalProvider>();
    final orders = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    if (_photos.isNotEmpty) {
      await orders.uploadPhotos(order.id, category: 'serah_terima', title: 'Kondisi saat diserahkan', isPublic: false, files: _photos);
    }
    final ok = await rentals.handover(
      order.rental!.id,
      pickupTime: _hhmm(_pickup),
      returnTime: _hhmm(_return),
      depositAmount: double.tryParse(_deposit.text.trim()),
      conditionNote: _note.text.trim(),
      agreementPhoto: _agreement,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Kostum diserahkan ke ${order.customer.name}.' : rentals.errorMessage ?? 'Gagal menyimpan serah terima.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<RentalProvider>().rentalOrders.where((o) => o.id == widget.orderId);
    final products = context.watch<ProductProvider>();
    final admin = context.watch<AuthProvider>().currentAdmin;
    if (matches.isEmpty) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Serah Terima Kostum'), body: Center(child: Text('Data sewa tidak ditemukan.')));
    }
    final order = matches.first;
    final rental = order.rental!;
    if (!_initialized) {
      _initialized = true;
      _pickup = _parseTime(rental.pickupTime) ?? _pickup;
      _return = _parseTime(rental.returnTime) ?? _return;
      if (rental.depositAmount != null) _deposit.text = rental.depositAmount!.toStringAsFixed(0);
      if (products.products.isEmpty) Future.microtask(products.fetchAll);
    }
    final checklist = _checklist(order, products);
    final allChecked = checklist.every((c) => _checked.contains(c.$1));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Serah Terima Kostum'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
                const Spacer(),
                const VgPill(label: 'Siap Ambil', color: AppColors.warning, background: AppColors.warningBg, dot: true, fontSize: 11),
              ]),
              const SizedBox(height: 10),
              Text(order.customer.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (order.notes != null) Text(order.notes!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _TimeBox(label: 'Jam Ambil', date: rental.pickupDate, time: _pickup, onTap: () => _pickTime(true))),
                const SizedBox(width: 10),
                Expanded(child: _TimeBox(label: 'Jam Kembali', date: rental.returnDate, time: _return, onTap: () => _pickTime(false))),
              ]),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Checklist Kelengkapan',
                subtitle: 'Centang setiap barang yang diserahkan',
                trailing: VgPill(
                  label: '${_checked.where((k) => checklist.any((c) => c.$1 == k)).length}/${checklist.length}',
                  color: allChecked ? AppColors.success : AppColors.warning,
                  background: allChecked ? AppColors.successBg : AppColors.warningBg,
                ),
              ),
              for (final (key, label) in checklist)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TapScale(
                    scaleDown: 0.98,
                    onTap: () => setState(() => _checked.contains(key) ? _checked.remove(key) : _checked.add(key)),
                    child: VgInset(
                      child: Row(children: [
                        Icon(_checked.contains(key) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: _checked.contains(key) ? AppColors.success : AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary))),
                      ]),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => setState(() => allChecked ? _checked.clear() : _checked.addAll(checklist.map((c) => c.$1))),
                child: Text(allChecked ? 'Hapus semua centang' : 'Centang semua', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(title: 'Deposit & Kondisi', subtitle: 'Uang jaminan ditahan sampai kostum kembali'),
              const VgLabel('Deposit Diterima'),
              VgTextField(controller: _deposit, prefix: 'Rp', strong: true, hint: '0', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 12),
              const VgLabel('Catatan Kondisi Keluar'),
              VgTextField(controller: _note, maxLines: 3),
              const SizedBox(height: 12),
              VgLabel('Foto Kondisi Keluar', trailing: Text('${_photos.length} foto', style: const TextStyle(fontSize: 12, color: AppColors.primary))),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++) VgPhotoTile(file: _photos[i], onRemove: () => setState(() => _photos.removeAt(i))),
                  VgAddPhotoTile(onTap: () async {
                    final picked = await pickPhotos(context);
                    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              VgInset(
                child: Row(children: [
                  const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Inspektur: ${admin?.name ?? 'Admin'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(title: 'Persetujuan Penyewa', subtitle: 'Pengganti tanda tangan di aplikasi'),
              TapScale(
                scaleDown: 0.98,
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(_agreed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Penyewa sudah memeriksa dan menyetujui kondisi serta kelengkapan kostum di atas.', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: VgButton(
                    label: 'Cetak Surat Perjanjian',
                    icon: Icons.print_outlined,
                    style: VgButtonStyle.outline,
                    height: 42,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuratPerjanjianScreen(order: order))),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _agreement == null
                  ? VgButton(
                      label: 'Foto Surat yang Sudah Ditandatangani',
                      icon: Icons.document_scanner_outlined,
                      style: VgButtonStyle.soft,
                      expanded: true,
                      height: 42,
                      onPressed: () async {
                        final picked = await pickPhotos(context, multiple: false);
                        if (picked.isNotEmpty) setState(() => _agreement = picked.first);
                      },
                    )
                  : SizedBox(height: 110, child: VgPhotoTile(file: _agreement, caption: 'Surat perjanjian bertanda tangan', onRemove: () => setState(() => _agreement = null))),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(
          label: 'Serahkan Kostum',
          icon: Icons.how_to_reg_outlined,
          expanded: true,
          height: 52,
          loading: _saving,
          onPressed: allChecked && _agreed ? () => _submit(order) : null,
        ),
        if (!allChecked || !_agreed)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Lengkapi checklist dan persetujuan penyewa terlebih dahulu.', style: TextStyle(fontSize: 11.5, color: AppColors.primary)),
          ),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeBox({required this.label, required this.date, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: VgInset(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary))),
            const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
          ]),
          const SizedBox(height: 2),
          Text('${_hhmm(time)} WIB', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(Formatters.date(date), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
