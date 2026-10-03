import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/auth_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import 'refund_screen.dart';

enum _Kondisi { lolos, rusak, hilang }

class _ItemCheck {
  _Kondisi kondisi = _Kondisi.lolos;
  final note = TextEditingController();
  final biaya = TextEditingController(text: '0');
}

class CatatKondisiBarangScreen extends StatefulWidget {
  final String orderId;
  const CatatKondisiBarangScreen({super.key, required this.orderId});

  @override
  State<CatatKondisiBarangScreen> createState() => _CatatKondisiBarangScreenState();
}

class _CatatKondisiBarangScreenState extends State<CatatKondisiBarangScreen> {
  final Map<String, _ItemCheck> _checks = {};
  final _denda = TextEditingController(text: '0');
  final DateTime _startedAt = DateTime.now();
  bool _agreed = false;
  bool _submitting = false;
  bool _draftLoaded = false;

  String get _draftKey => 'return_draft_${widget.orderId}';

  @override
  void dispose() {
    for (final c in _checks.values) {
      c.note.dispose();
      c.biaya.dispose();
    }
    _denda.dispose();
    super.dispose();
  }

  Order? _order(RentalProvider provider) {
    final matches = provider.rentalOrders.where((o) => o.id == widget.orderId);
    return matches.isEmpty ? null : matches.first;
  }

  _ItemCheck _check(OrderItem item) => _checks.putIfAbsent(item.id, _ItemCheck.new);

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll('.', '')) ?? 0;

  Future<void> _loadDraft(Order order) async {
    _draftLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      for (final item in order.items) {
        final saved = (data['items'] as Map<String, dynamic>?)?[item.id] as Map<String, dynamic>?;
        if (saved == null) continue;
        final c = _check(item);
        c.kondisi = _Kondisi.values[saved['kondisi'] as int? ?? 0];
        c.note.text = saved['note'] as String? ?? '';
        c.biaya.text = saved['biaya'] as String? ?? '0';
      }
      _denda.text = data['denda'] as String? ?? '0';
    });
  }

  Future<void> _saveDraft(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'denda': _denda.text,
        'items': {
          for (final item in order.items) item.id: {'kondisi': _check(item).kondisi.index, 'note': _check(item).note.text, 'biaya': _check(item).biaya.text},
        },
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draf pengecekan disimpan di perangkat ini.')));
  }

  String _label(_Kondisi k) => switch (k) { _Kondisi.lolos => 'Baik & lengkap', _Kondisi.rusak => 'Ada noda/rusak', _Kondisi.hilang => 'Hilang' };

  Future<void> _submit(Order order, double potongan) async {
    final provider = context.read<RentalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final summary = order.items.map((i) {
      final c = _check(i);
      return '${i.quantity}x ${i.name}${i.size != null ? ' (${i.size})' : ''}: ${_label(c.kondisi)}${c.note.text.trim().isNotEmpty ? ' - ${c.note.text.trim()}' : ''}';
    }).join('\n');
    final damages = order.items.where((i) => _check(i).kondisi != _Kondisi.lolos).map((i) {
      final c = _check(i);
      return '${i.name}: ${c.note.text.trim().isEmpty ? _label(c.kondisi) : c.note.text.trim()} (${Formatters.rupiah(_num(c.biaya))})';
    }).join('\n');

    setState(() => _submitting = true);
    final ok = await provider.updateRentalStatus(
      order.rental!.id,
      status: RentalStatus.dikembalikan,
      itemConditionAfter: summary,
      damageNote: damages.isEmpty ? null : damages,
      penaltyAmount: potongan,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Pengembalian barang dikonfirmasi.' : provider.errorMessage ?? 'Gagal menyimpan pengembalian.')));
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      if ((order.rental!.depositAmount ?? 0) > 0) {
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => RefundScreen(orderId: order.id)));
      } else {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order(context.watch<RentalProvider>());
    final admin = context.watch<AuthProvider>().currentAdmin;
    if (order == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Catat Kondisi Barang'), body: Center(child: CircularProgressIndicator()));
    }
    if (!_draftLoaded) _loadDraft(order);

    int qtyOf(_Kondisi k) => order.items.where((i) => _check(i).kondisi == k).fold(0, (s, i) => s + i.quantity);
    final repair = order.items.where((i) => _check(i).kondisi != _Kondisi.lolos).fold<double>(0, (s, i) => s + _num(_check(i).biaya));
    final denda = _num(_denda);
    final potongan = repair + denda;
    final lateDays = DateTime.now().difference(order.rental!.returnDate).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VgBackBar(
        title: 'Catat Kondisi Barang',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
            color: AppColors.surface,
            onSelected: (_) => setState(() {
              for (final c in _checks.values) {
                c.kondisi = _Kondisi.lolos;
                c.note.clear();
                c.biaya.text = '0';
              }
              _denda.text = '0';
            }),
            itemBuilder: (_) => const [PopupMenuItem(value: 'reset', child: Text('Reset pengecekan'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
            const Spacer(),
            const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            const Text('Tersinkron', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const VgIconBadge(icon: Icons.theater_comedy_outlined, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.customer.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
                    const SizedBox(height: 4),
                    Text('Inspeksi Pengembalian ${order.totalQuantity} Stel ${order.headline}', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text('Masuk: Hari ini, ${DateFormat('HH:mm').format(_startedAt)} WIB • Petugas: ${admin?.name ?? 'Admin'}', style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
                ),
              ]),
            ]),
          ),
          Row(children: [
            Expanded(child: _CountTile(icon: Icons.check_circle_outline_rounded, value: qtyOf(_Kondisi.lolos), label: 'Baik & Lengkap', color: AppColors.success, background: AppColors.surface, iconBg: AppColors.successBg)),
            const SizedBox(width: 8),
            Expanded(
              child: _CountTile(
                icon: Icons.warning_amber_rounded,
                value: qtyOf(_Kondisi.rusak),
                label: 'Ada Noda/Rusak',
                color: AppColors.warning,
                background: qtyOf(_Kondisi.rusak) > 0 ? const Color(0xFFFFF4D6) : AppColors.surface,
                iconBg: AppColors.warningBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _CountTile(icon: Icons.search_off_rounded, value: qtyOf(_Kondisi.hilang), label: 'Barang Hilang', color: AppColors.primary, background: AppColors.surface, iconBg: AppColors.dangerBg)),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('Rincian Fisik Pakaian & Properti', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            Text('${order.items.length} Kelompok Unit', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          for (final item in order.items) _ItemCard(item: item, check: _check(item), onChanged: () => setState(() {})),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('Rekonsiliasi Denda & Potongan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Flexible(child: Text('Denda Keterlambatan', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
                const SizedBox(width: 8),
                VgPill(
                  label: lateDays > 0 ? 'Telat $lateDays Hari' : 'Tepat Waktu',
                  color: lateDays > 0 ? AppColors.danger : AppColors.success,
                  background: lateDays > 0 ? AppColors.dangerBg : AppColors.successBg,
                  fontSize: 10.5,
                ),
              ]),
              const SizedBox(height: 8),
              VgMoneyField(controller: _denda, onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Potongan Perbaikan / Laundry', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
                Text('- ${Formatters.rupiah(repair)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              if ((order.rental!.depositAmount ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Text('Deposit Ditahan', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
                  Text(Formatters.rupiah(order.rental!.depositAmount!), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Expanded(child: Text('Estimasi Refund ke Penyewa', style: TextStyle(fontSize: 13.5, color: AppColors.primary))),
                  Text(
                    Formatters.rupiah((order.rental!.depositAmount! - potongan).clamp(0, double.infinity).toDouble()),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.success),
                  ),
                ]),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TOTAL DENDA & POTONGAN', style: TextStyle(fontSize: 12, color: AppColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      SizedBox(height: 2),
                      Text('Ditagihkan ke penyewa', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                    ]),
                  ),
                  Text(Formatters.rupiah(potongan), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
              ),
            ]),
          ),
          TapScale(
            onTap: () => setState(() => _agreed = !_agreed),
            child: VgCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: _agreed ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Penyewa menyetujui hasil inspeksi fisik dan total potongan sebesar ${Formatters.rupiah(potongan)}.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ]),
            ),
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
            Opacity(
              opacity: _agreed ? 1 : 0.5,
              child: TapScale(
                onTap: _agreed && !_submitting ? () => _submit(order, potongan) : null,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF2E7D4F), borderRadius: BorderRadius.circular(14)),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Flexible(child: Text('Konfirmasi Pengembalian', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                        ]),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _saveDraft(order),
              child: const Text('Simpan Draft Pengecekan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;
  final Color iconBg;

  const _CountTile({required this.icon, required this.value, required this.label, required this.color, required this.background, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VgIconBadge(icon: icon, color: color, background: iconBg, size: 28, circle: true),
        const Spacer(),
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: color, height: 1.2)),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final OrderItem item;
  final _ItemCheck check;
  final VoidCallback onChanged;

  const _ItemCard({required this.item, required this.check, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ok = check.kondisi == _Kondisi.lolos;
    return VgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ok
              ? const VgIconBadge(icon: Icons.check_rounded, color: AppColors.success, background: AppColors.beige, size: 32, circle: true)
              : VgIconBadge(
                  icon: check.kondisi == _Kondisi.hilang ? Icons.search_off_rounded : Icons.warning_amber_rounded,
                  color: check.kondisi == _Kondisi.hilang ? AppColors.danger : AppColors.goldDark,
                  background: check.kondisi == _Kondisi.hilang ? AppColors.dangerBg : AppColors.warningBg,
                  size: 32,
                  circle: true,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (item.size != null) ...[
                const SizedBox(height: 2),
                Text('Ukuran: ${item.size} (${item.quantity})', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              ],
            ]),
          ),
          if (ok) const VgPill(label: 'Lolos', color: AppColors.success, background: AppColors.successBg, fontSize: 10.5),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          for (final k in _Kondisi.values) ...[
            Expanded(
              child: TapScale(
                onTap: () {
                  check.kondisi = k;
                  onChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: check.kondisi == k ? AppColors.primary : AppColors.beigeSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    switch (k) { _Kondisi.lolos => 'Baik', _Kondisi.rusak => 'Rusak', _Kondisi.hilang => 'Hilang' },
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: check.kondisi == k ? Colors.white : AppColors.primary),
                  ),
                ),
              ),
            ),
            if (k != _Kondisi.hilang) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 10),
        if (ok)
          const VgInset(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            radius: 10,
            child: Row(children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(child: Text('Kondisi utuh dan lengkap.', style: TextStyle(fontSize: 12, color: AppColors.primary))),
            ]),
          )
        else ...[
          TextField(
            controller: check.note,
            onChanged: (_) => onChanged(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: check.kondisi == _Kondisi.hilang ? 'Barang apa yang hilang?' : 'Jelaskan noda / kerusakan',
              isDense: true,
              fillColor: AppColors.beigeSoft,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          VgInset(
            child: Row(children: [
              const Icon(Icons.build_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(check.kondisi == _Kondisi.hilang ? 'Biaya Penggantian' : 'Estimasi Biaya Perbaikan', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: check.biaya,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger),
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
