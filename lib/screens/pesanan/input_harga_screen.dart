import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';

class InputHargaScreen extends StatefulWidget {
  final String orderId;
  const InputHargaScreen({super.key, required this.orderId});

  @override
  State<InputHargaScreen> createState() => _InputHargaScreenState();
}

class _InputHargaScreenState extends State<InputHargaScreen> {
  static const _noteTemplate =
      'Harga sudah termasuk bordir logo, aksesoris standar, dan packing per stel. Garansi penyesuaian ukuran 14 hari setelah barang diterima.';

  final _bahan = TextEditingController();
  final _jahit = TextEditingController();
  final _aksesoris = TextEditingController();
  final _margin = TextEditingController(text: '25');
  final _ongkir = TextEditingController(text: '0');
  final _kurir = TextEditingController(text: 'JNE Trucking / Kargo');
  final _note = TextEditingController();
  int _durasi = 21;
  bool _termin = true;
  bool _sending = false;

  String get _draftKey => 'quote_draft_${widget.orderId}';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    for (final c in [_bahan, _jahit, _aksesoris, _margin, _ongkir, _kurir, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    final d = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _bahan.text = d['bahan'] as String? ?? '';
      _jahit.text = d['jahit'] as String? ?? '';
      _aksesoris.text = d['aksesoris'] as String? ?? '';
      _margin.text = d['margin'] as String? ?? '25';
      _ongkir.text = d['ongkir'] as String? ?? '0';
      _kurir.text = d['kurir'] as String? ?? _kurir.text;
      _note.text = d['note'] as String? ?? '';
      _durasi = d['durasi'] as int? ?? 21;
      _termin = d['termin'] as bool? ?? true;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'bahan': _bahan.text,
        'jahit': _jahit.text,
        'aksesoris': _aksesoris.text,
        'margin': _margin.text,
        'ongkir': _ongkir.text,
        'kurir': _kurir.text,
        'note': _note.text,
        'durasi': _durasi,
        'termin': _termin,
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draf penawaran disimpan di perangkat ini.')));
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  DateTime _targetDate() {
    var date = DateTime.now();
    var added = 0;
    while (added < _durasi) {
      date = date.add(const Duration(days: 1));
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) added++;
    }
    return date;
  }

  Future<void> _send(Order order, double total, double? dp) async {
    final provider = context.read<OrderProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Kirim Penawaran?'),
        content: Text(
          'Total ${Formatters.rupiah(total)}${dp != null ? ' dengan DP ${Formatters.rupiah(dp)}' : ' (bayar penuh)'} akan dikirim ke ${order.customer.name}.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(children: [
            Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 10),
            Expanded(child: VgButton(label: 'Kirim', style: VgButtonStyle.maroon, onPressed: () => Navigator.pop(ctx, true))),
          ]),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _sending = true);
    final note = [
      if (_note.text.trim().isNotEmpty) _note.text.trim(),
      if (_num(_ongkir) > 0) 'Pengiriman: ${_kurir.text.trim()} (${Formatters.rupiah(_num(_ongkir))}).',
    ].join('\n');
    final success = await provider.submitQuote(order.id, totalPrice: total, dpAmount: dp, deadlineDate: _targetDate(), note: note);
    if (!mounted) return;
    setState(() => _sending = false);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penawaran berhasil dikirim ke pelanggan.')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal mengirim penawaran.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Kalkulasi Penawaran'), body: Center(child: Text('Pesanan tidak ditemukan.')));
    }

    final qty = order.totalQuantity == 0 ? 1 : order.totalQuantity;
    final hpp = _num(_bahan) + _num(_jahit) + _num(_aksesoris);
    final marginPerStel = hpp * _num(_margin) / 100;
    final unit = hpp + marginPerStel;
    final subtotal = unit * qty;
    final total = subtotal + _num(_ongkir);
    final dp = _termin ? (total / 2).roundToDouble() : null;
    final editable = order.status == OrderStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VgBackBar(
        title: 'Kalkulasi Penawaran',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'reset') {
                setState(() {
                  for (final c in [_bahan, _jahit, _aksesoris]) {
                    c.clear();
                  }
                  _margin.text = '25';
                  _ongkir.text = '0';
                });
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'reset', child: Text('Reset kalkulasi'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Flexible(child: Text('KALKULASI PROFORMA', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 0.8))),
                ]),
                const SizedBox(height: 2),
                Text('Order #${order.orderNumber}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
            ),
            VgPill(label: 'Pesanan ${order.orderType.label}', color: AppColors.primary, background: AppColors.goldLight, icon: Icons.verified_rounded),
          ]),
          const SizedBox(height: 14),
          VgCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(clipBehavior: Clip.none, children: [
                VgThumb(url: order.coverImage, size: 68, radius: 12),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(12))),
                    child: Text('${order.totalQuantity}x', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(order.headline, style: const TextStyle(fontSize: 13.5, color: AppColors.primary)),
                  if (order.customOrderDetail?.jenisJenjang != null) ...[
                    const SizedBox(height: 8),
                    VgPill(label: order.customOrderDetail!.jenisJenjang!, color: AppColors.primary, background: AppColors.beige, icon: Icons.handyman_outlined),
                  ],
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 4), child: VgIconBadge(icon: Icons.calculate_outlined, size: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Komponen Biaya Pokok (HPP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.2)),
                    Text('Estimasi basis per stel (Total ${order.totalQuantity} stel)', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ]),
                ),
                VgPill(label: '${order.totalQuantity} Stel', color: AppColors.primary, background: AppColors.beige),
              ]),
              const SizedBox(height: 16),
              _FieldLabel('1. Bahan Baku Kain (per stel)'),
              VgMoneyField(controller: _bahan, suffix: '/ stel', onChanged: (_) => setState(() {})),
              _FieldLabel('2. Ongkos Jahit & Finishing (per stel)'),
              VgMoneyField(controller: _jahit, suffix: '/ stel', onChanged: (_) => setState(() {})),
              _FieldLabel('3. Aksesoris & Bordir (per stel)'),
              VgMoneyField(controller: _aksesoris, suffix: '/ stel', onChanged: (_) => setState(() {})),
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text('Termasuk strip reflektif, logo sekolah, kancing & emblem', style: TextStyle(fontSize: 11.5, color: AppColors.primary)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(children: [
                  const Expanded(child: Text('4. Target Margin Profit Admin', style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                  VgPill(label: '+${Formatters.rupiah(marginPerStel)} / stel', color: AppColors.success, background: AppColors.beige, fontSize: 11),
                ]),
              ),
              VgMoneyField(controller: _margin, prefix: null, suffix: '%', onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  _SummaryLine(label: 'HPP Dasar per Stel', value: Formatters.rupiah(hpp)),
                  const SizedBox(height: 6),
                  _SummaryLine(label: 'Harga Satuan Final (+Margin)', value: '${Formatters.rupiah(unit)} / stel', strong: true),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text('Subtotal Produksi (${order.totalQuantity} Stel)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                    Flexible(child: Text(Formatters.rupiah(subtotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                  ]),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.only(top: 4), child: VgIconBadge(icon: Icons.local_shipping_outlined, color: AppColors.goldDark, size: 30)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pengiriman & Skema Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.2)),
                    Text('Biaya logistik kargo & syarat termin', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Expanded(child: Text('Biaya Pengiriman (Kargo)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _kurir,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    decoration: const InputDecoration(isDense: true, filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              VgMoneyField(controller: _ongkir, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              VgInset(
                child: Row(children: [
                  const VgIconBadge(icon: Icons.event_note_outlined, background: AppColors.surface, size: 36, circle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Estimasi Durasi Pengerjaan', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '$_durasi Hari Kerja ', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        TextSpan(text: '(Target Siap Kirim: ${Formatters.date(_targetDate())})', style: const TextStyle(color: AppColors.textSecondary)),
                      ]), style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                  _StepButton(icon: Icons.remove, onTap: _durasi > 1 ? () => setState(() => _durasi--) : null),
                  const SizedBox(width: 6),
                  _StepButton(icon: Icons.add, onTap: () => setState(() => _durasi++)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('Pilihan Skema Pembayaran', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _SchemeTile(title: 'Termin DP 50%', subtitle: '50% DP / 50% Pelunasan', selected: _termin, onTap: () => setState(() => _termin = true))),
                  const SizedBox(width: 10),
                  Expanded(child: _SchemeTile(title: 'Bayar Penuh 100%', subtitle: 'Pelunasan di muka sebelum produksi', selected: !_termin, onTap: () => setState(() => _termin = false))),
                ]),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('TOTAL PENAWARAN RESMI', style: TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Final Netto', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Rp', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600))),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(Formatters.rupiah(total).replaceFirst('Rp ', ''), style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (dp != null) ...[
                _TotalRow(dot: const Color(0xFFF59E0B), label: 'Termin DP 50% (Mulai Produksi)', value: Formatters.rupiah(dp)),
                const SizedBox(height: 8),
                _TotalRow(dot: const Color(0xFF22C55E), label: 'Pelunasan 50% (Sebelum Kirim)', value: Formatters.rupiah(total - dp)),
              ] else
                _TotalRow(dot: const Color(0xFF22C55E), label: 'Pembayaran Penuh (Sebelum Produksi)', value: Formatters.rupiah(total)),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Catatan Resmi untuk Pelanggan', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                TapScale(
                  onTap: () => setState(() => _note.text = _noteTemplate),
                  child: const Padding(padding: EdgeInsets.all(4), child: Text('Template Standar', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tulis ketentuan harga, garansi, atau catatan lainnya…',
                  fillColor: AppColors.beigeSoft,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),
          const VgInset(
            color: Color(0xFFFFF4D6),
            child: Row(children: [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Setiap item melewati Quality Control ganda VIEGUARD dengan standar ketahanan jahitan industri.',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
                ),
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
          minimum: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            VgButton(
              label: editable ? 'Kirim Penawaran ke Pelanggan' : 'Pesanan sudah tidak pending',
              icon: Icons.send_outlined,
              expanded: true,
              height: 52,
              loading: _sending,
              onPressed: editable && total > 0 ? () => _send(order, total, dp) : null,
            ),
            TextButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.bookmark_border_rounded, size: 18, color: AppColors.primary),
              label: const Text('Simpan Draf Penawaran', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  const _SummaryLine({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.primary))),
      Text(value, style: TextStyle(fontSize: strong ? 15 : 13, fontWeight: strong ? FontWeight.w800 : FontWeight.w500, color: strong ? AppColors.primary : AppColors.textPrimary)),
    ]);
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: onTap == null ? AppColors.border : AppColors.primary),
      ),
    );
  }
}

class _SchemeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SchemeTile({required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE08A) : const Color(0xFFFFF1C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.gold : Colors.transparent, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary))),
            if (selected) const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  const _TotalRow({required this.dot, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.white))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }
}
