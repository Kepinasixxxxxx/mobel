import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_status.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/status_badge.dart';

enum _KondisiUmum { baik, rusakRingan, hilang }

class CatatKondisiBarangScreen extends StatefulWidget {
  final String orderId;
  const CatatKondisiBarangScreen({super.key, required this.orderId});

  @override
  State<CatatKondisiBarangScreen> createState() => _CatatKondisiBarangScreenState();
}

class _CatatKondisiBarangScreenState extends State<CatatKondisiBarangScreen> {
  _KondisiUmum _kondisi = _KondisiUmum.baik;
  final _catatanCtrl = TextEditingController();
  final _dendaCtrl = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _dendaCtrl.dispose();
    super.dispose();
  }

  String get _kondisiLabel {
    switch (_kondisi) {
      case _KondisiUmum.baik:
        return 'Baik & lengkap, tidak ada catatan.';
      case _KondisiUmum.rusakRingan:
        return 'Ada noda/kerusakan ringan.';
      case _KondisiUmum.hilang:
        return 'Ada barang hilang.';
    }
  }

  Future<void> _submit() async {
    final provider = context.read<RentalProvider>();
    final matches = provider.rentalOrders.where((o) => o.id == widget.orderId);
    if (matches.isEmpty) return;
    final order = matches.first;
    setState(() => _submitting = true);
    final denda = double.tryParse(_dendaCtrl.text) ?? 0;
    final ok = await provider.updateRentalStatus(
      order.rental!.id,
      status: RentalStatus.dikembalikan,
      itemConditionAfter: _kondisiLabel,
      damageNote: _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
      penaltyAmount: denda,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pengembalian dikonfirmasi.' : provider.errorMessage ?? 'Gagal menyimpan.')));
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final matches = provider.rentalOrders.where((o) => o.id == widget.orderId);
    if (matches.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final order = matches.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Catat Kondisi Barang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            TagChip(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.infoBg),
            const Spacer(),
            const TagChip(label: 'Auto-Sync On', color: AppColors.success, background: AppColors.successBg),
          ]),
          const SizedBox(height: 10),
          Text(order.customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Inspeksi Pengembalian · ${order.totalQuantity} Unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Item Yang Diperiksa',
            children: order.items
                .map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${i.name}${i.size != null ? ' (${i.size})' : ''} x${i.quantity}', style: const TextStyle(fontSize: 12.5)),
                    ))
                .toList(),
          ),
          SectionCard(
            title: 'Kondisi Umum Barang',
            subtitle: 'Pilih kondisi keseluruhan hasil inspeksi',
            children: [
              _KondisiOption(label: 'Baik & Lengkap', value: _KondisiUmum.baik, group: _kondisi, color: AppColors.success, onChanged: (v) => setState(() => _kondisi = v)),
              _KondisiOption(label: 'Ada Noda / Rusak Ringan', value: _KondisiUmum.rusakRingan, group: _kondisi, color: AppColors.warning, onChanged: (v) => setState(() => _kondisi = v)),
              _KondisiOption(label: 'Ada Barang Hilang', value: _KondisiUmum.hilang, group: _kondisi, color: AppColors.danger, onChanged: (v) => setState(() => _kondisi = v)),
              const SizedBox(height: 10),
              const Text('Catatan Kerusakan / Kehilangan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(controller: _catatanCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Jelaskan detail kondisi barang...')),
            ],
          ),
          SectionCard(
            title: 'Denda Keterlambatan / Kerusakan',
            subtitle: 'Nominal potongan dari jaminan penyewa',
            children: [
              TextField(
                controller: _dendaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: 'Rp '),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Konfirmasi Pengembalian'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KondisiOption extends StatelessWidget {
  final String label;
  final _KondisiUmum value;
  final _KondisiUmum group;
  final Color color;
  final ValueChanged<_KondisiUmum> onChanged;

  const _KondisiOption({required this.label, required this.value, required this.group, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return TapScale(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? color : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? color : AppColors.textPrimary)),
        ]),
      ),
    );
  }
}
