import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status_history_model.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import 'photo_docs_screen.dart';

const List<String> kWorkshopPhases = [
  'Pola & Pemotongan Kain (Cutting)',
  'Bordir Komputer Logo',
  'Proses Jahit & Assembling',
  'Quality Control & Pasang Kancing',
  'Steam Pressing & Polybag',
];

const List<String> _phaseDescriptions = [
  'Pembuatan pola sesuai ukuran dan pemotongan kain utama.',
  'Bordir logo, badge, dan emblem sesuai desain.',
  'Penggabungan furing dan penjahitan seluruh bagian pakaian.',
  'Inspeksi jahitan, lubang kancing, dan pemasangan aksesoris.',
  'Penyetrikaan uap, pelipatan, dan pengemasan per stel.',
];

const List<IconData> _phaseIcons = [
  Icons.content_cut_rounded,
  Icons.auto_awesome_outlined,
  Icons.handyman_outlined,
  Icons.verified_outlined,
  Icons.inventory_2_outlined,
];

class WorkshopProgressScreen extends StatefulWidget {
  final String orderId;
  const WorkshopProgressScreen({super.key, required this.orderId});

  @override
  State<WorkshopProgressScreen> createState() => _WorkshopProgressScreenState();
}

class _WorkshopProgressScreenState extends State<WorkshopProgressScreen> {
  int? _phase;
  double _phasePercent = 0;
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final orders = context.read<OrderProvider>();
    Future.microtask(() => orders.fetchOrderDetail(widget.orderId));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  static int _overall(int phase, double phasePercent) => ((phase * 100 + phasePercent) / kWorkshopPhases.length).round();

  static int _phaseOf(int overall) => (overall * kWorkshopPhases.length / 100).floor().clamp(0, kWorkshopPhases.length - 1);

  static double _phasePercentOf(int overall, int phase) => (overall * kWorkshopPhases.length - phase * 100).clamp(0, 100).toDouble();

  OrderStatusHistoryEntry? _entryFor(Order order, int phase) {
    for (final h in order.statusHistory.reversed) {
      if (h.statusLabel == kWorkshopPhases[phase]) return h;
    }
    return null;
  }

  void _ensureDefaults(Order order) {
    if (_phase != null) return;
    final overall = order.latestProgress;
    _phase = _phaseOf(overall);
    _phasePercent = _phasePercentOf(overall, _phase!);
  }

  Future<void> _submit(Order order) async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = int.tryParse(_qtyCtrl.text.trim());
    final note = [
      if (_noteCtrl.text.trim().isNotEmpty) _noteCtrl.text.trim(),
      if (done != null) '$done dari ${order.totalQuantity} pcs selesai pada tahap ini.',
    ].join(' ');
    setState(() => _submitting = true);
    final ok = await provider.updateProgress(order.id, progressPercentage: _overall(_phase!, _phasePercent), statusLabel: kWorkshopPhases[_phase!], note: note);
    if (!mounted) return;
    setState(() => _submitting = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Progres berhasil dipublikasikan.' : provider.errorMessage ?? 'Gagal memperbarui progres.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Update Progres Produksi'), body: Center(child: CircularProgressIndicator()));
    }
    _ensureDefaults(order);

    final overall = order.latestProgress;
    final currentPhase = _phaseOf(overall);
    final completedPhases = overall >= 100 ? kWorkshopPhases.length : currentPhase;
    final daysLeft = order.deadlineDate != null ? Formatters.daysLeft(order.deadlineDate!) : null;
    final done = int.tryParse(_qtyCtrl.text.trim());
    final newOverall = _overall(_phase!, _phasePercent);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Update Progres Produksi'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const VgIconBadge(icon: Icons.precision_manufacturing_outlined, size: 32, circle: true),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Update Progres Produksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
                SizedBox(height: 4),
                Text('Pantau dan sinkronisasi tahapan pengerjaan seragam secara real-time', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ]),
            ),
            VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 10.5),
          ]),
          const SizedBox(height: 14),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.school_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Flexible(child: Text('Klien Institusi', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.primary))),
                    ]),
                    const SizedBox(height: 4),
                    Text(order.customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(order.headline, style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ]),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (daysLeft != null)
                    VgPill(
                      label: daysLeft >= 0 ? 'H-$daysLeft Deadline' : 'Lewat ${-daysLeft} Hari',
                      color: daysLeft <= 4 ? AppColors.warning : AppColors.info,
                      background: daysLeft <= 4 ? AppColors.warningBg : AppColors.infoBg,
                      icon: Icons.schedule_rounded,
                      fontSize: 11,
                    ),
                  if (order.deadlineDate != null) ...[
                    const SizedBox(height: 6),
                    Text('Target: ${Formatters.date(order.deadlineDate!)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ],
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              VgInset(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Total Akumulasi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(order.latestStatusLabel ?? 'Belum dimulai', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                    Text('$overall%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: overall / 100, minHeight: 9, backgroundColor: AppColors.surface, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('$completedPhases dari ${kWorkshopPhases.length} Tahapan Rampung', style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
                  ]),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Alur Pengerjaan Workshop',
                trailing: Text('${kWorkshopPhases.length} Fase Mutu', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
              for (var i = 0; i < kWorkshopPhases.length; i++)
                _PhaseTile(
                  index: i,
                  state: i < completedPhases ? _PhaseState.done : (i == currentPhase && overall > 0 ? _PhaseState.active : _PhaseState.queued),
                  activePercent: _phasePercentOf(overall, i).round(),
                  entry: _entryFor(order, i),
                  isLast: i == kWorkshopPhases.length - 1,
                  deadline: order.deadlineDate,
                ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgCardTitle(
                title: 'Perbarui Status Hari Ini',
                subtitle: 'Input log aktivitas produksi harian workshop',
                trailing: VgIconBadge(icon: Icons.edit_calendar_outlined, color: AppColors.goldDark, background: AppColors.warningBg, size: 36),
              ),
              const Text('Tahap Pengerjaan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _phase,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
                    items: List.generate(
                      kWorkshopPhases.length,
                      (i) => DropdownMenuItem(value: i, child: Text('${i + 1}. ${kWorkshopPhases[i]}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary))),
                    ),
                    onChanged: (v) => setState(() => _phase = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VgInset(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(children: [
                  Row(children: [
                    const Expanded(child: Text('Persentase Selesai Tahap Ini', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_phasePercent.round()} %', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  ]),
                  Slider(
                    value: _phasePercent,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surface,
                    onChanged: (v) => setState(() => _phasePercent = v),
                  ),
                  Row(children: [
                    const Text('0%', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                    const Spacer(),
                    const Text('50%', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('Total jadi $newOverall%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              const Text('Kuantitas Selesai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              VgMoneyField(controller: _qtyCtrl, prefix: null, suffix: 'dari ${order.totalQuantity} Pcs', onChanged: (_) => setState(() {})),
              if (done != null && done < order.totalQuantity)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text('Sisa ${order.totalQuantity - done} unit dalam antrean tahap ini', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                ),
              const SizedBox(height: 14),
              Row(children: [
                const Expanded(child: Text('Catatan Workshop & Kendala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                for (final chip in const ['Bahan Siap', 'Sesuai Jadwal'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: TapScale(
                      onTap: () => setState(() => _noteCtrl.text = _noteCtrl.text.isEmpty ? '$chip.' : '${_noteCtrl.text} $chip.'),
                      child: VgPill(label: chip, color: AppColors.success, background: AppColors.successBg, fontSize: 10.5),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 13.5, height: 1.45),
                decoration: InputDecoration(
                  hintText: 'Tulis perkembangan, kendala bahan, atau catatan penjahit…',
                  fillColor: AppColors.beige,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Dokumentasi Foto Workshop',
                subtitle: 'Bukti hasil jahitan & kerapihan',
                trailing: VgPill(label: '${order.photosIn('workshop').length} Foto', color: AppColors.success, background: AppColors.successBg, fontSize: 11),
              ),
              if (order.photosIn('workshop').isNotEmpty) ...[
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.photosIn('workshop').length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = order.photosIn('workshop')[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 130,
                          child: Stack(fit: StackFit.expand, children: [
                            Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige)),
                            if (p.title != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)])),
                                  child: Text(p.title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.white)),
                                ),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              VgButton(
                label: '+ Ambil Foto / Unggah Dokumentasi',
                icon: Icons.add_a_photo_outlined,
                style: VgButtonStyle.soft,
                expanded: true,
                height: 46,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoDocsScreen(orderId: order.id))),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            VgButton(label: 'Simpan & Publikasikan Progres', icon: Icons.cloud_upload_outlined, expanded: true, height: 52, loading: _submitting, onPressed: () => _submit(order)),
            TextButton.icon(
              onPressed: () => openChatWithCustomer(context, order),
              icon: const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.primary),
              label: const Text('Hubungi Pelanggan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}

enum _PhaseState { done, active, queued }

class _PhaseTile extends StatelessWidget {
  final int index;
  final _PhaseState state;
  final int activePercent;
  final OrderStatusHistoryEntry? entry;
  final bool isLast;
  final DateTime? deadline;

  const _PhaseTile({required this.index, required this.state, required this.activePercent, required this.entry, required this.isLast, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final done = state == _PhaseState.done;
    final active = state == _PhaseState.active;
    final Widget marker = done
        ? const VgIconBadge(icon: Icons.check_rounded, color: Colors.white, background: Color(0xFF2E7D4F), size: 30, circle: true)
        : active
            ? VgIconBadge(icon: _phaseIcons[index], color: Colors.white, background: AppColors.primary, size: 30, circle: true)
            : VgIconBadge(icon: _phaseIcons[index], color: AppColors.primary, background: AppColors.beige, size: 30, circle: true);

    final String pill;
    final Color pillFg;
    final Color pillBg;
    if (done) {
      pill = '100%';
      pillFg = AppColors.textPrimary;
      pillBg = AppColors.surface;
    } else if (active) {
      pill = 'Aktif $activePercent%';
      pillFg = AppColors.textPrimary;
      pillBg = AppColors.surface;
    } else {
      pill = index == 0 ? 'Antrean' : 'Menunggu';
      pillFg = AppColors.primary;
      pillBg = AppColors.surface;
    }

    String footer;
    IconData footerIcon;
    if (done) {
      footer = entry != null ? 'Selesai pada ${Formatters.date(entry!.createdAt)}' : 'Selesai';
      footerIcon = Icons.check_circle_outline_rounded;
    } else if (active) {
      footer = 'Sedang Berjalan';
      footerIcon = Icons.construction_rounded;
    } else {
      footer = 'Menunggu tahap sebelumnya';
      footerIcon = Icons.schedule_rounded;
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 34,
          child: Column(children: [
            marker,
            if (!isLast)
              Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: done ? const Color(0xFF2E7D4F) : (active ? AppColors.primary : AppColors.border))),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))] : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text('${index + 1}. ${kWorkshopPhases[index]}',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.textPrimary)),
                ),
                const SizedBox(width: 6),
                VgPill(label: pill, color: pillFg, background: pillBg, fontSize: 10.5, dot: active),
              ]),
              const SizedBox(height: 4),
              Text(
                entry?.note?.isNotEmpty == true ? entry!.note! : _phaseDescriptions[index],
                style: TextStyle(fontSize: 12, color: state == _PhaseState.queued ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(footerIcon, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(child: Text(footer, style: const TextStyle(fontSize: 11.5, color: AppColors.primary))),
                if (active && deadline != null) Text('Target: ${Formatters.date(deadline!)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
