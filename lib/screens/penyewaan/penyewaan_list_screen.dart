import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/penyewaan/rental_calendar_tab.dart';
import '../../widgets/vg/vg_ui.dart';
import '../stok/stok_list_screen.dart';
import 'catat_kondisi_barang_screen.dart';
import 'penyewaan_detail_screen.dart';
import 'rental_actions.dart';

enum _RentFilter { semua, aktif, menungguAmbil, jatuhTempo, terlambat, selesai }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

bool _dueToday(Order o) => o.rental!.status == RentalStatus.diambil && _day(o.rental!.returnDate) == _day(DateTime.now());

class PenyewaanListScreen extends StatefulWidget {
  const PenyewaanListScreen({super.key});

  @override
  State<PenyewaanListScreen> createState() => _PenyewaanListScreenState();
}

class _PenyewaanListScreenState extends State<PenyewaanListScreen> {
  static const _pageSize = 10;

  int _tab = 0;
  _RentFilter _filter = _RentFilter.semua;
  String _query = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final rentals = context.read<RentalProvider>();
      if (rentals.rentalOrders.isEmpty) rentals.fetchRentals();
      final products = context.read<ProductProvider>();
      if (products.products.isEmpty) products.fetchAll();
    });
  }

  bool _matches(Order o, _RentFilter f) {
    final s = o.rental!.status;
    switch (f) {
      case _RentFilter.semua:
        return true;
      case _RentFilter.aktif:
        return s == RentalStatus.diambil;
      case _RentFilter.menungguAmbil:
        return s == RentalStatus.dipesan;
      case _RentFilter.jatuhTempo:
        return _dueToday(o);
      case _RentFilter.terlambat:
        return s == RentalStatus.terlambat;
      case _RentFilter.selesai:
        return s == RentalStatus.dikembalikan;
    }
  }

  String _label(_RentFilter f) => switch (f) {
        _RentFilter.semua => 'Semua',
        _RentFilter.aktif => 'Aktif / Berjalan',
        _RentFilter.menungguAmbil => 'Menunggu Ambil',
        _RentFilter.jatuhTempo => 'Kembali Hari Ini',
        _RentFilter.terlambat => 'Terlambat',
        _RentFilter.selesai => 'Selesai',
      };

  Widget _tabButton(int index, IconData icon, String label) {
    final selected = _tab == index;
    return Expanded(
      child: TapScale(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: selected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.primary))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(canPop ? 4 : 16, 10, 16, 10),
            child: Row(children: [
              if (canPop) const BackButton(color: AppColors.primary),
              const Expanded(child: VgTopBar(subtitle: 'Penyewaan Alat')),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
            child: Row(children: [
              _tabButton(0, Icons.list_alt_rounded, 'Daftar Sewa'),
              _tabButton(1, Icons.calendar_month_outlined, 'Kalender'),
              _tabButton(2, Icons.inventory_2_outlined, 'Stok'),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: IndexedStack(index: _tab, children: [
              _buildList(context),
              const RentalCalendarTab(),
              const StokListScreen(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final base = provider.filtered(query: _query);
    final list = base.where((o) => _matches(o, _filter)).toList();
    final pages = (list.length / _pageSize).ceil().clamp(1, 999);
    final page = _page.clamp(0, pages - 1);
    final visible = list.skip(page * _pageSize).take(_pageSize).toList();
    final dueToday = provider.rentalOrders.where(_dueToday).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.fetchRentals,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          Row(children: [
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() {
                        _query = v;
                        _page = 0;
                      }),
                      decoration: const InputDecoration(
                        hintText: 'Cari no. sewa, penyewa',
                        hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            TapScale(
              onTap: provider.fetchRentals,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
                child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _RentFilter.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _RentFilter.values[i];
                final selected = f == _filter;
                return TapScale(
                  onTap: () => setState(() {
                    _filter = f;
                    _page = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text('${_label(f)} (${base.where((o) => _matches(o, f)).length})',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (dueToday > 0) ...[
            TapScale(
              onTap: () => setState(() {
                _filter = _RentFilter.jatuhTempo;
                _page = 0;
              }),
              child: VgInset(
                color: const Color(0xFFFFF1C7),
                child: Row(children: [
                  const VgIconBadge(icon: Icons.schedule_rounded, color: AppColors.goldDark, background: Color(0xFFFFE08A), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$dueToday Pengembalian Terjadwal Hari Ini', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const Text('Siapkan inspeksi kondisi barang saat diterima', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Cek', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (provider.isLoading && provider.rentalOrders.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
          else if (provider.errorMessage != null && provider.rentalOrders.isEmpty)
            VgCard(child: Text(provider.errorMessage!, style: const TextStyle(color: AppColors.danger)))
          else if (visible.isEmpty)
            const VgCard(child: Text('Tidak ada data penyewaan pada filter ini.', style: TextStyle(color: AppColors.textSecondary)))
          else
            ...visible.map((o) => _RentalCard(order: o)),
          if (list.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Menampilkan ${visible.length} dari ${list.length} rental', style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
            ]),
            if (pages > 1) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _PageButton(icon: Icons.chevron_left_rounded, onTap: page > 0 ? () => setState(() => _page = page - 1) : null),
                for (var i = 0; i < pages && i < 5; i++) ...[
                  const SizedBox(width: 6),
                  _PageButton(label: '${i + 1}', selected: i == page, onTap: () => setState(() => _page = i)),
                ],
                const SizedBox(width: 6),
                _PageButton(icon: Icons.chevron_right_rounded, onTap: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({this.icon, this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : (onTap == null ? AppColors.border : AppColors.textPrimary);
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
        child: icon != null ? Icon(icon, size: 20, color: fg) : Text(label!, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Order order;
  const _RentalCard({required this.order});

  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final due = _dueToday(order);
    final late = rental.status == RentalStatus.terlambat;
    final days = rental.totalDays;
    final itemNames = order.items.map((i) => i.name).toSet().toList();

    final String pill;
    final Color pillFg;
    final Color pillBg;
    if (late) {
      pill = 'Terlambat';
      pillFg = AppColors.danger;
      pillBg = AppColors.dangerBg;
    } else if (due) {
      pill = 'Batas Kembali Hari Ini';
      pillFg = AppColors.warning;
      pillBg = AppColors.warningBg;
    } else if (rental.status == RentalStatus.dipesan) {
      final until = Formatters.daysLeft(rental.pickupDate);
      pill = until == 0 ? 'Siap Ambil Hari Ini' : (until == 1 ? 'Siap Ambil Besok' : (until > 1 ? 'Ambil $until Hari Lagi' : 'Lewat Jadwal Ambil'));
      pillFg = AppColors.primary;
      pillBg = AppColors.beige;
    } else {
      pill = rental.status.label;
      pillFg = rental.status.color;
      pillBg = rental.status.background;
    }

    final Widget paymentLine;
    if (order.isLunas) {
      paymentLine = const Text('Sudah Lunas Penuh (100%)', style: TextStyle(fontSize: 12, color: AppColors.success));
    } else if (order.amountPaid > 0) {
      paymentLine = Text('DP ${Formatters.rupiah(order.amountPaid)} diterima', style: const TextStyle(fontSize: 12, color: AppColors.primary));
    } else {
      paymentLine = const Text('Belum ada pembayaran', style: TextStyle(fontSize: 12, color: AppColors.warning));
    }

    final List<Widget> actions;
    if (late || due) {
      actions = [
        VgButton(
          label: 'Proses Kembali',
          icon: Icons.assignment_turned_in_outlined,
          style: VgButtonStyle.amber,
          height: 46,
          onPressed: () => _open(context, CatatKondisiBarangScreen(orderId: order.id)),
        ),
      ];
    } else if (rental.status == RentalStatus.dipesan) {
      actions = [VgButton(label: 'Konfirmasi Ambil', icon: Icons.how_to_reg_outlined, height: 44, onPressed: () => confirmPickupFlow(context, order))];
    } else if (rental.status == RentalStatus.diambil) {
      actions = [
        VgButton(label: 'Inspeksi', style: VgButtonStyle.soft, height: 42, onPressed: () => _open(context, CatatKondisiBarangScreen(orderId: order.id))),
        const SizedBox(width: 8),
        VgButton(label: 'Detail', height: 42, onPressed: () => _open(context, PenyewaanDetailScreen(orderId: order.id))),
      ];
    } else if (rental.awaitingRefund) {
      actions = [VgButton(label: 'Refund Deposit', icon: Icons.account_balance_wallet_outlined, style: VgButtonStyle.green, height: 42, onPressed: () => openRefund(context, order))];
    } else {
      actions = [VgButton(label: 'Detail', style: VgButtonStyle.soft, height: 42, onPressed: () => _open(context, PenyewaanDetailScreen(orderId: order.id)))];
    }

    final accent = late ? AppColors.danger : (due ? const Color(0xFFF59E0B) : null);

    return TapScale(
      scaleDown: 0.98,
      onTap: () => _open(context, PenyewaanDetailScreen(orderId: order.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: accent == null ? null : BoxDecoration(border: Border(left: BorderSide(color: accent, width: 4))),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '#${order.orderNumber}', style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const TextSpan(text: '  •  ', style: TextStyle(color: AppColors.border)),
                    TextSpan(text: order.notes!.split('\n').first, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              VgPill(label: pill, color: pillFg, background: pillBg, dot: true, fontSize: 11),
            ]),
            const SizedBox(height: 4),
            Text(order.customer.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            VgInset(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                VgThumb(url: order.coverImage, size: 56, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.headline, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    Text(
                      '${order.totalQuantity} Stel${itemNames.length > 1 ? ' • ${itemNames.skip(1).join(', ')}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(due || late ? Icons.alarm_rounded : Icons.date_range_rounded, size: 14, color: due || late ? AppColors.goldDark : AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          due
                              ? 'Jatuh Tempo: Hari ini${rental.returnTime != null ? ', ${rental.returnTime} WIB' : ''}'
                              : '${Formatters.date(rental.pickupDate)}${rental.pickupTime != null ? ' ${rental.pickupTime}' : ''} - ${Formatters.date(rental.returnDate)} ($days Hari)',
                          style: TextStyle(fontSize: 12, color: due || late ? AppColors.goldDark : AppColors.primary),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Tagihan Sewa', style: TextStyle(fontSize: 12.5, color: AppColors.primary)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                  paymentLine,
                ]),
              ),
              const SizedBox(width: 8),
              ...actions,
            ]),
          ]),
        ),
      ),
    );
  }
}
