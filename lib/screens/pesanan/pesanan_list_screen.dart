import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../state/payment_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_ui.dart';
import '../pembayaran/payment_verification_list_screen.dart';
import 'detail_pesanan_screen.dart';
import 'input_harga_screen.dart';
import 'order_actions.dart';
import 'ship_order_screen.dart';
import 'workshop_progress_screen.dart';

enum _Filter { semua, menunggu, diproduksi, siap, selesai, dibatalkan }

class PesananListScreen extends StatefulWidget {
  const PesananListScreen({super.key});

  @override
  State<PesananListScreen> createState() => _PesananListScreenState();
}

class _PesananListScreenState extends State<PesananListScreen> {
  static const _pageSize = 10;

  _Filter _filter = _Filter.semua;
  OrderType? _type;
  String _query = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
      context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu);
    });
  }

  Future<void> _refresh() => Future.wait([
        context.read<OrderProvider>().fetchOrders(),
        context.read<PaymentProvider>().fetchPayments(status: PaymentStatus.menunggu),
      ]);

  bool _matches(Order o, _Filter f) {
    switch (f) {
      case _Filter.semua:
        return true;
      case _Filter.menunggu:
        return o.status == OrderStatus.pending;
      case _Filter.diproduksi:
        return o.status == OrderStatus.dikonfirmasi || o.status == OrderStatus.diproses;
      case _Filter.siap:
        return o.status == OrderStatus.siapDiambil;
      case _Filter.selesai:
        return o.status == OrderStatus.selesai;
      case _Filter.dibatalkan:
        return o.status == OrderStatus.dibatalkan;
    }
  }

  String _label(_Filter f) {
    switch (f) {
      case _Filter.semua:
        return 'Semua';
      case _Filter.menunggu:
        return 'Menunggu';
      case _Filter.diproduksi:
        return 'Diproduksi';
      case _Filter.siap:
        return 'Siap Kirim';
      case _Filter.selesai:
        return 'Selesai';
      case _Filter.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Future<void> _pickType() async {
    final picked = await showModalBottomSheet<List<OrderType?>>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Jenis Pesanan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 12),
            for (final option in <OrderType?>[null, ...OrderType.values])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option?.label ?? 'Semua Jenis', style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: option == _type ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, [option]),
              ),
          ]),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _type = picked.first;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final pendingPayments = context.watch<PaymentProvider>().payments.length;
    final base = provider.filtered(orderType: _type, query: _query);
    final list = base.where((o) => _matches(o, _filter)).toList();
    final pages = (list.length / _pageSize).ceil().clamp(1, 999);
    final page = _page.clamp(0, pages - 1);
    final visible = list.skip(page * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 68,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              leading: Navigator.canPop(context) ? const BackButton(color: AppColors.primary) : null,
              title: const VgTopBar(subtitle: 'Pesanan'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() {
                            _query = v;
                            _page = 0;
                          }),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Cari no. pesanan, nama sekolah/pemesan',
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
                      TapScale(
                        onTap: _pickType,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.tune_rounded, color: _type == null ? AppColors.primary : AppColors.goldDark, size: 22),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _Filter.values.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final f = _Filter.values[i];
                        final selected = f == _filter;
                        final count = base.where((o) => _matches(o, f)).length;
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
                            child: Text('${_label(f)} ($count)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? AppColors.onPrimary : AppColors.textPrimary)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (pendingPayments > 0) ...[
                    TapScale(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentVerificationListScreen())),
                      child: VgInset(
                        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                        child: Row(children: [
                          const VgIconBadge(icon: Icons.bolt_rounded, color: AppColors.goldLight, background: AppColors.primary, size: 36, circle: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('$pendingPayments Pembayaran Butuh Verifikasi', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              const Text('Cek bukti transfer sebelum produksi dimulai', style: TextStyle(fontSize: 11.5, color: AppColors.primary)),
                            ]),
                          ),
                          const Text('Tinjau', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (provider.isLoading && provider.orders.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                  else if (provider.errorMessage != null && provider.orders.isEmpty)
                    VgCard(child: Text(provider.errorMessage!, style: const TextStyle(color: AppColors.danger)))
                  else if (visible.isEmpty)
                    const VgCard(child: Text('Tidak ada pesanan pada filter ini.', style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ...visible.map((o) => _OrderCard(order: o)),
                  if (list.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Text.rich(TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Menampilkan '),
                            TextSpan(text: '${visible.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const TextSpan(text: ' dari '),
                            TextSpan(text: '${list.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const TextSpan(text: ' pesanan'),
                          ],
                        )),
                      ),
                      _PageButton(icon: Icons.chevron_left_rounded, onTap: page > 0 ? () => setState(() => _page = page - 1) : null),
                      for (var i = 0; i < pages && i < 3; i++) ...[
                        const SizedBox(width: 6),
                        _PageButton(label: '${i + 1}', selected: i == page, onTap: () => setState(() => _page = i)),
                      ],
                      const SizedBox(width: 6),
                      _PageButton(icon: Icons.chevron_right_rounded, onTap: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
                    ]),
                  ],
                ]),
              ),
            ),
          ],
        ),
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
    final fg = selected ? AppColors.onPrimary : (onTap == null ? AppColors.border : AppColors.textPrimary);
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: icon != null ? Icon(icon, size: 20, color: fg) : Text(label!, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final inProduction = status == OrderStatus.dikonfirmasi || status == OrderStatus.diproses;
    final itemNames = order.items.map((i) => i.name).toSet().toList();
    final detailLine = order.isCustom
        ? (order.customOrderDetail?.designDescription ?? order.customOrderDetail?.jenisJenjang)
        : (itemNames.length > 1 ? itemNames.skip(1).join(' • ') : order.orderType.label);
    final sizes = order.sizeBreakdown;

    Widget priceBlock;
    if (order.needsQuote) {
      priceBlock = const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Estimasi Biaya', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        Text('Belum Ditentukan', style: TextStyle(fontSize: 19, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ]);
    } else {
      Widget? sub;
      if (order.isLunas) {
        sub = const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.success),
          SizedBox(width: 4),
          Text('Lunas Terverifikasi', style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600)),
        ]);
      } else if (order.amountPaid > 0) {
        sub = Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.success),
          const SizedBox(width: 4),
          Flexible(child: Text('DP Diterima: ${Formatters.rupiahCompact(order.amountPaid)}', style: const TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600))),
        ]);
      } else if (order.dpAmount != null) {
        sub = Text('DP ${Formatters.rupiah(order.dpAmount!)} belum dibayar', style: const TextStyle(fontSize: 11.5, color: AppColors.primary));
      }
      priceBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(status == OrderStatus.siapDiambil ? 'Total Tagihan' : 'Total Nilai', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        FittedBox(fit: BoxFit.scaleDown, child: Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary))),
        ?sub,
      ]);
    }

    final List<Widget> actions;
    if (order.isCustom && status == OrderStatus.pending) {
      actions = [
        VgButton(
          label: order.needsQuote ? 'Input Estimasi' : 'Ubah Estimasi',
          icon: Icons.calculate_outlined,
          style: VgButtonStyle.gold,
          height: 42,
          onPressed: () => _open(context, InputHargaScreen(orderId: order.id)),
        ),
      ];
    } else if (status == OrderStatus.pending) {
      actions = [
        VgButton(label: 'Detail', style: VgButtonStyle.soft, height: 42, onPressed: () => _open(context, DetailPesananScreen(orderId: order.id))),
        const SizedBox(width: 8),
        VgButton(label: 'Konfirmasi', style: VgButtonStyle.gold, height: 42, onPressed: () => confirmOrderFlow(context, order)),
      ];
    } else if (inProduction) {
      actions = [
        VgButton(
          label: order.requiresProduction ? 'Update Progres' : 'Tandai Siap',
          icon: order.requiresProduction ? Icons.edit_note_rounded : Icons.inventory_2_outlined,
          style: VgButtonStyle.soft,
          height: 42,
          onPressed: order.requiresProduction
              ? () => _open(context, WorkshopProgressScreen(orderId: order.id))
              : () => changeStatusFlow(context, order, OrderStatus.siapDiambil, 'Pesanan ditandai siap.'),
        ),
      ];
    } else if (status == OrderStatus.siapDiambil) {
      final canShip = order.orderType != OrderType.sewa && !order.isShipped;
      actions = [
        canShip
            ? VgButton(
                label: 'Kirim Resi',
                icon: Icons.local_shipping_outlined,
                style: VgButtonStyle.maroon,
                height: 42,
                onPressed: () => _open(context, ShipOrderScreen(orderId: order.id)),
              )
            : VgButton(
                label: 'Selesaikan',
                icon: Icons.task_alt_rounded,
                style: VgButtonStyle.maroon,
                height: 42,
                onPressed: () => changeStatusFlow(context, order, OrderStatus.selesai, 'Pesanan diselesaikan.'),
              ),
      ];
    } else {
      actions = [VgButton(label: 'Detail', style: VgButtonStyle.soft, height: 42, onPressed: () => _open(context, DetailPesananScreen(orderId: order.id)))];
    }

    return VgCard(
      onTap: () => _open(context, DetailPesananScreen(orderId: order.id)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '#${order.orderNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const TextSpan(text: '  •  ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              TextSpan(text: timeAgo(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ])),
          ),
          const SizedBox(width: 8),
          OrderStatusPill(order: order, useProgressLabel: true),
        ]),
        const SizedBox(height: 4),
        Text(order.customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        VgInset(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(order.headline, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              const SizedBox(width: 8),
              VgPill(label: '${order.totalQuantity} Stel', color: AppColors.onGold, background: AppColors.goldLight, fontSize: 11),
            ]),
            if (detailLine != null && detailLine.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(detailLine, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
            if (status == OrderStatus.siapDiambil) ...[
              const SizedBox(height: 4),
              Text(
                order.isShipped
                    ? (order.trackingNumber != null ? '${order.courier} · Resi ${order.trackingNumber}' : 'Menunggu diambil pelanggan')
                    : 'Sudah melewati QC & siap dikirim',
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ],
            if (inProduction && order.requiresProduction) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(
                    order.deadlineDate != null
                        ? 'Target: ${Formatters.date(order.deadlineDate!)} (H-${Formatters.daysLeft(order.deadlineDate!).clamp(0, 999)})'
                        : 'Target belum ditentukan',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                Text('${order.latestProgress}% Rampung', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: order.latestProgress / 100, minHeight: 6, backgroundColor: AppColors.surface.withValues(alpha: 0.6), color: AppColors.gold),
              ),
            ],
            if (sizes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.description_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 5),
                  Flexible(child: Text('Data Ukuran: ${order.sizedQuantity}/${order.totalQuantity} Lengkap', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: priceBlock),
          const SizedBox(width: 8),
          ...actions,
        ]),
      ]),
    );
  }
}
