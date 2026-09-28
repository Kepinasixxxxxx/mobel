import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_status.dart';
import '../../state/order_provider.dart';
import '../../widgets/pesanan/pesanan_order_card.dart';
import 'detail_pesanan_screen.dart';

class PesananListScreen extends StatefulWidget {
  const PesananListScreen({super.key});

  @override
  State<PesananListScreen> createState() => _PesananListScreenState();
}

class _PesananListScreenState extends State<PesananListScreen> {
  OrderStatus? _statusFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<OrderProvider>();
    if (provider.orders.isEmpty) Future.microtask(() => provider.fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final list = provider.filtered(status: _statusFilter, query: _query);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pesanan')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchOrders(status: _statusFilter, search: _query.isEmpty ? null : _query),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(hintText: 'Cari no. pesanan atau nama pelanggan', prefixIcon: Icon(Icons.search, size: 20)),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(label: 'Semua (${provider.orders.length})', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Pending (${provider.countByStatus(OrderStatus.pending)})', selected: _statusFilter == OrderStatus.pending, onTap: () => setState(() => _statusFilter = OrderStatus.pending)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Dikonfirmasi (${provider.countByStatus(OrderStatus.dikonfirmasi)})', selected: _statusFilter == OrderStatus.dikonfirmasi, onTap: () => setState(() => _statusFilter = OrderStatus.dikonfirmasi)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Diproses (${provider.countByStatus(OrderStatus.diproses)})', selected: _statusFilter == OrderStatus.diproses, onTap: () => setState(() => _statusFilter = OrderStatus.diproses)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Siap Diambil (${provider.countByStatus(OrderStatus.siapDiambil)})', selected: _statusFilter == OrderStatus.siapDiambil, onTap: () => setState(() => _statusFilter = OrderStatus.siapDiambil)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Selesai (${provider.countByStatus(OrderStatus.selesai)})', selected: _statusFilter == OrderStatus.selesai, onTap: () => setState(() => _statusFilter = OrderStatus.selesai)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.isLoading && provider.orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null && provider.orders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 8),
                              Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              ElevatedButton(onPressed: () => provider.fetchOrders(), child: const Text('Coba Lagi')),
                            ]),
                          ),
                        )
                      : list.isEmpty
                          ? const Center(child: Text('Tidak ada pesanan yang cocok', style: TextStyle(color: AppColors.textSecondary)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final order = list[index];
                                return PesananOrderCard(
                                  order: order,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesananScreen(orderId: order.id))),
                                );
                              },
                            ),
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
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.onPrimary : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
