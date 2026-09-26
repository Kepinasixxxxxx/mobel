import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/info_tile.dart';
import '../../widgets/common/status_badge.dart';

const List<String> kWorkshopPhases = [
  'Pola & Pemotongan Kain (Cutting)',
  'Bordir Komputer Logo',
  'Proses Jahit & Assembling',
  'Quality Control & Pasang Kancing',
  'Steam Pressing & Polybag',
];

class WorkshopProgressScreen extends StatefulWidget {
  final String orderId;
  const WorkshopProgressScreen({super.key, required this.orderId});

  @override
  State<WorkshopProgressScreen> createState() => _WorkshopProgressScreenState();
}

class _WorkshopProgressScreenState extends State<WorkshopProgressScreen> {
  int _selectedPhase = 0;
  double _percent = 50;
  final _kuantitasCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  bool _notifWhatsapp = true;
  bool _submitting = false;

  @override
  void dispose() {
    _kuantitasCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  int _phaseIndexFromLabel(String label) {
    final idx = kWorkshopPhases.indexWhere((p) => label.contains(p) || p.contains(label));
    return idx;
  }

  Future<void> _submit() async {
    final order = context.read<OrderProvider>().orderById(widget.orderId);
    if (order == null) return;
    setState(() => _submitting = true);
    final quantityNote = _kuantitasCtrl.text.trim().isNotEmpty ? ' (${_kuantitasCtrl.text.trim()} dari ${order.totalQuantity} unit selesai)' : '';
    final ok = await context.read<OrderProvider>().updateProgress(
          order.id,
          progressPercentage: _percent.round(),
          statusLabel: kWorkshopPhases[_selectedPhase],
          note: '${_catatanCtrl.text.trim()}$quantityNote'.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Progres berhasil dipublikasikan.' : context.read<OrderProvider>().errorMessage ?? 'Gagal memperbarui progres.')),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final latestPhaseIndex = order.statusHistory.isEmpty ? -1 : _phaseIndexFromLabel(order.statusHistory.last.statusLabel);
    final sisaHari = order.deadlineDate != null ? Formatters.daysLeft(order.deadlineDate!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Update Progres Produksi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.factory_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  const Text('Klien Institusi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  if (sisaHari != null)
                    TagChip(label: sisaHari >= 0 ? 'H-$sisaHari Deadline' : 'Lewat ${-sisaHari} Hari', color: sisaHari <= 4 ? AppColors.warning : AppColors.info, background: sisaHari <= 4 ? AppColors.warningBg : AppColors.infoBg),
                ]),
                const SizedBox(height: 4),
                Text(order.customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(order.items.isNotEmpty ? order.items.first.name : order.orderType.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Akumulasi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('${order.latestProgress}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: order.latestProgress / 100, minHeight: 8, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${latestPhaseIndex + 1} dari ${kWorkshopPhases.length} tahapan rampung'
                  '${order.deadlineDate != null ? ' · Target: ${Formatters.date(order.deadlineDate!)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Alur Pengerjaan Workshop', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...List.generate(kWorkshopPhases.length, (i) {
            final done = i < latestPhaseIndex || (i == latestPhaseIndex && order.latestProgress >= 100);
            final active = i == latestPhaseIndex && !done;
            return _PhaseTile(index: i, title: kWorkshopPhases[i], done: done, active: active, percent: active ? order.latestProgress : null);
          }),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Perbarui Status Hari Ini',
            subtitle: 'Input log aktivitas produksi harian workshop',
            children: [
              const Text('Tahap Pengerjaan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: _selectedPhase,
                items: List.generate(kWorkshopPhases.length, (i) => DropdownMenuItem(value: i, child: Text('${i + 1}. ${kWorkshopPhases[i]}', overflow: TextOverflow.ellipsis))),
                onChanged: (v) => setState(() => _selectedPhase = v ?? 0),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Persentase Selesai Tahap Ini', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('${_percent.round()}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
              Slider(value: _percent, min: 0, max: 100, onChanged: (v) => setState(() => _percent = v), divisions: 20, label: '${_percent.round()}%'),
              const SizedBox(height: 8),
              const Text('Kuantitas Selesai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: _kuantitasCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'contoh: 90', suffixText: 'dari ${order.totalQuantity} unit'),
              ),
              const SizedBox(height: 14),
              const Text('Catatan Workshop & Kendala', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(controller: _catatanCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Tuliskan progres/kendala hari ini...')),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Dokumentasi foto belum didukung oleh backend saat ini.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Notifikasi WhatsApp Klien', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('Terkirim otomatis setiap update progres', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(value: _notifWhatsapp, onChanged: (v) => setState(() => _notifWhatsapp = v)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Simpan & Publikasikan Progres'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  final int index;
  final String title;
  final bool done;
  final bool active;
  final int? percent;

  const _PhaseTile({required this.index, required this.title, required this.done, required this.active, this.percent});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : (active ? AppColors.info : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: done ? AppColors.success : (active ? AppColors.info : AppColors.border), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${index + 1}', style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              if (index < kWorkshopPhases.length - 1) Expanded(child: Container(width: 2, color: AppColors.border)),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                    TagChip(
                      label: done ? '100%' : (active ? 'Aktif ${percent ?? 0}%' : 'Menunggu'),
                      color: color,
                      background: done ? AppColors.successBg : (active ? AppColors.infoBg : AppColors.background),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
