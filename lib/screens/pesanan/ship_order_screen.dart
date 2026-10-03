import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

const _couriers = ['J&T Cargo', 'JNE Trucking', 'SiCepat Gokil', 'Lalamove', 'Ambil Sendiri'];

class ShipOrderScreen extends StatefulWidget {
  final String orderId;
  const ShipOrderScreen({super.key, required this.orderId});

  @override
  State<ShipOrderScreen> createState() => _ShipOrderScreenState();
}

class _ShipOrderScreenState extends State<ShipOrderScreen> {
  final _resi = TextEditingController();
  final _cost = TextEditingController();
  final List<XFile> _photos = [];
  String _courier = _couriers.first;
  DateTime _eta = DateTime.now().add(const Duration(days: 2));
  bool _saving = false;

  bool get _pickup => _courier == 'Ambil Sendiri';

  @override
  void dispose() {
    _resi.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickEta() async {
    final picked = await showDatePicker(context: context, initialDate: _eta, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
    if (picked != null) setState(() => _eta = picked);
  }

  Future<void> _submit() async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!_pickup && _resi.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Isi nomor resi dari ekspedisi terlebih dahulu.')));
      return;
    }
    setState(() => _saving = true);
    if (_photos.isNotEmpty) {
      await provider.uploadPhotos(widget.orderId, category: 'paket', title: _pickup ? 'Paket siap diambil' : 'Paket ${_resi.text.trim()}', isPublic: true, files: _photos);
    }
    final ok = await provider.shipOrder(
      widget.orderId,
      courier: _courier,
      trackingNumber: _pickup ? null : _resi.text.trim(),
      shippingCost: _pickup ? null : double.tryParse(_cost.text.trim()),
      etaDate: _pickup ? null : _eta,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? (_pickup ? 'Pelanggan diberi tahu pesanan siap diambil.' : 'Resi terkirim ke pelanggan.') : provider.errorMessage ?? 'Gagal menyimpan pengiriman.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Kirim Pesanan'), body: Center(child: Text('Pesanan tidak ditemukan.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Kirim Pesanan'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const VgPill(label: 'Siap Kirim', color: AppColors.success, background: AppColors.successBg, dot: true),
                const Spacer(),
                Text('#${order.orderNumber}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ]),
              const SizedBox(height: 10),
              Text(order.customer.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${order.headline} · ${order.totalQuantity} Stel', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 12),
              VgInset(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Alamat Tujuan', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      Text(order.customer.address ?? 'Alamat belum diisi pelanggan', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              VgInset(
                child: Row(children: [
                  const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF2E7D4F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Penerima', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      Text('${order.customer.name}${order.customer.phone != null ? ' · ${order.customer.phone}' : ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(
                title: 'Ekspedisi',
                subtitle: 'Pilih kurir pengiriman',
                trailing: VgIconBadge(icon: Icons.local_shipping_outlined, color: AppColors.goldDark, background: AppColors.warningBg, size: 38),
              ),
              VgChoiceChips<String>(options: [for (final c in _couriers) (c, c)], selected: _courier, onSelected: (v) => setState(() => _courier = v)),
              if (!_pickup) ...[
                const SizedBox(height: 14),
                const VgLabel('Nomor Resi'),
                VgTextField(controller: _resi, icon: Icons.qr_code_scanner_rounded, hint: 'Contoh: JTC-5520019381'),
                const SizedBox(height: 12),
                const VgLabel('Biaya Pengiriman'),
                VgTextField(controller: _cost, prefix: 'Rp', strong: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 12),
                const VgLabel('Estimasi Tiba'),
                TapScale(
                  onTap: _pickEta,
                  child: VgInset(
                    color: AppColors.beigeSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    child: Row(children: [
                      const Icon(Icons.event_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(Formatters.dayDate(_eta), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.primary),
                    ]),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const VgInset(
                  child: Text('Pelanggan akan diberi tahu bahwa pesanan siap diambil di workshop.', style: TextStyle(fontSize: 12.5, color: AppColors.primary)),
                ),
              ],
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(title: 'Foto Paket', subtitle: 'Bukti barang sudah dikemas (opsional)', trailing: VgPill(label: '${_photos.length} Foto', color: AppColors.primary, background: AppColors.beige)),
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
            ]),
          ),
          const VgInset(
            color: Color(0xFFFFF4D6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Expanded(child: Text('Nomor resi dikirim otomatis ke notifikasi pelanggan setelah disimpan.', style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4))),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(
          label: _pickup ? 'Tandai Siap Diambil' : 'Tandai Dikirim & Kirim Resi',
          icon: _pickup ? Icons.storefront_outlined : Icons.local_shipping_outlined,
          style: VgButtonStyle.green,
          expanded: true,
          height: 52,
          loading: _saving,
          onPressed: _submit,
        ),
        const SizedBox(height: 6),
      ]),
    );
  }
}

