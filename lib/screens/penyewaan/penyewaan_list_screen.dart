import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/penyewaan/rental_calendar_tab.dart';
import '../stok/stok_list_screen.dart';
import 'catat_kondisi_barang_screen.dart';
import 'penyewaan_detail_screen.dart';

class PenyewaanListScreen extends StatefulWidget {
  const PenyewaanListScreen({super.key});

  @override
  State<PenyewaanListScreen> createState() => _PenyewaanListScreenState();
}

class _PenyewaanListScreenState extends State<PenyewaanListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  RentalStatus? _statusFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = context.read<RentalProvider>();
    if (provider.rentalOrders.isEmpty) Future.microtask(() => provider.fetchRentals());
    final productProvider = context.read<ProductProvider>();
    if (productProvider.products.isEmpty) Future.microtask(() => productProvider.fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmAmbil(RentalProvider provider, Order order) async {
    final ok = await provider.updateRentalStatus(order.rental!.id, status: RentalStatus.diambil);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Barang ditandai sudah diambil.' : provider.errorMessage ?? 'Gagal memperbarui.')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final list = provider.filtered(status: _statusFilter, query: _query);
    final dueToday = provider.rentalOrders.where((o) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final ret = DateTime(o.rental!.returnDate.year, o.rental!.returnDate.month, o.rental!.returnDate.day);
      return ret == today && o.rental!.status == RentalStatus.diambil;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penyewaan Alat'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Daftar Sewa'), Tab(text: 'Kalender'), Tab(text: 'Stok')]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: provider.fetchRentals,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(hintText: 'Cari no. sewa, penyewa, nama kostum', prefixIcon: Icon(Icons.search, size: 20)),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(label: 'Semua (${provider.rentalOrders.length})', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Sedang Digunakan (${provider.countByRentalStatus(RentalStatus.diambil)})', selected: _statusFilter == RentalStatus.diambil, onTap: () => setState(() => _statusFilter = RentalStatus.diambil)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Menunggu Ambil (${provider.countByRentalStatus(RentalStatus.dipesan)})', selected: _statusFilter == RentalStatus.dipesan, onTap: () => setState(() => _statusFilter = RentalStatus.dipesan)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Terlambat (${provider.countByRentalStatus(RentalStatus.terlambat)})', selected: _statusFilter == RentalStatus.terlambat, onTap: () => setState(() => _statusFilter = RentalStatus.terlambat)),
                    ],
                  ),
                ),
                if (dueToday > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.schedule, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$dueToday Pengembalian Terjadwal Hari Ini', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning))),
                    ]),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: provider.isLoading && provider.rentalOrders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? const Center(child: Text('Tidak ada data penyewaan', style: TextStyle(color: AppColors.textSecondary)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: list.length,
                              itemBuilder: (context, index) => _RentalCard(
                                order: list[index],
                                onDetail: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PenyewaanDetailScreen(orderId: list[index].id))),
                                onKonfirmasiAmbil: () => _confirmAmbil(provider, list[index]),
                                onProsesKembali: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatatKondisiBarangScreen(orderId: list[index].id))),
                              ),
                            ),
                ),
              ],
            ),
          ),
          const RentalCalendarTab(),
          const StokListScreen(),
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Order order;
  final VoidCallback onDetail;
  final VoidCallback onKonfirmasiAmbil;
  final VoidCallback onProsesKembali;

  const _RentalCard({required this.order, required this.onDetail, required this.onKonfirmasiAmbil, required this.onProsesKembali});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    return TapScale(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: rental.status.color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
              const Spacer(),
              RentalStatusBadge(status: rental.status),
            ]),
            const SizedBox(height: 6),
            Text(order.customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.items.isNotEmpty ? order.items.first.name : '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text('${Formatters.date(rental.pickupDate)} - ${Formatters.date(rental.returnDate)} (${rental.totalDays} hari)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Tagihan Sewa', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
                if (rental.status == RentalStatus.dipesan)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    onPressed: onKonfirmasiAmbil,
                    child: const Text('Konfirmasi Ambil', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  )
                else if (rental.status == RentalStatus.diambil)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    onPressed: onProsesKembali,
                    child: const Text('Proses Kembali', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    onPressed: onDetail,
                    child: const Text('Detail', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
