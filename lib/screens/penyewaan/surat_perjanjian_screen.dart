import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../state/order_provider.dart';

class SuratPerjanjianScreen extends StatefulWidget {
  final Order order;
  const SuratPerjanjianScreen({super.key, required this.order});

  @override
  State<SuratPerjanjianScreen> createState() => _SuratPerjanjianScreenState();
}

class _SuratPerjanjianScreenState extends State<SuratPerjanjianScreen> {
  bool _downloading = false;

  Future<void> _downloadAndOpen() async {
    setState(() => _downloading = true);
    try {
      final apiClient = context.read<OrderProvider>().apiClient;
      final bytes = await apiClient.downloadBytes('/orders/${widget.order.id}/surat-perjanjian');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/perjanjian-sewa-${widget.order.orderNumber}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF tersimpan, tapi tidak ada aplikasi pembuka PDF di perangkat ini.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final rental = order.rental!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Surat Perjanjian Sewa')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('V', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                    ),
                    const SizedBox(height: 8),
                    const Text('VIEGUARD Kostum & Drumband', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13), textAlign: TextAlign.center),
                    const Text('Jl. Merdeka No. 45, Kota Malang, Jawa Timur', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('SURAT PERJANJIAN SEWA MENYEWA KOSTUM', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Nomor: ${order.orderNumber}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Text(
                  'Pada hari ini, ${Formatters.dayDate(DateTime.now())}, telah dibuat dan disepakati perjanjian sewa menyewa kostum antara kedua belah pihak sebagai berikut:',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 14),
                _PartyBlock(
                  label: 'PIHAK PERTAMA (Penyedia Jasa)',
                  name: 'VIEGUARD Kostum & Drumband',
                  detail: 'Jl. Merdeka No. 45, Kota Malang, Jawa Timur\nTelp: 081234567890',
                ),
                const SizedBox(height: 10),
                _PartyBlock(
                  label: 'PIHAK KEDUA (Penyewa)',
                  name: order.customer.name,
                  detail: '${order.customer.phone ?? '-'}\n${order.customer.address ?? '-'}',
                ),
                const SizedBox(height: 16),
                const _ClauseHeader(number: '1', title: 'Objek Sewa'),
                const SizedBox(height: 6),
                ...order.items.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text('• ${i.name}${i.size != null ? ' (Ukuran ${i.size})' : ''} — ${i.quantity} unit', style: const TextStyle(fontSize: 12)),
                    )),
                const SizedBox(height: 12),
                const _ClauseHeader(number: '2', title: 'Jangka Waktu Sewa'),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Sewa berlaku sejak tanggal ${Formatters.date(rental.pickupDate)} sampai dengan ${Formatters.date(rental.returnDate)} '
                    '(${rental.totalDays} hari), terhitung sejak barang diserahterimakan kepada Pihak Kedua.',
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                const _ClauseHeader(number: '3', title: 'Biaya Sewa'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _CostRow(label: 'Total Biaya Sewa', value: Formatters.rupiah(order.totalPrice)),
                      if (order.dpAmount != null) _CostRow(label: 'Uang Muka (DP)', value: Formatters.rupiah(order.dpAmount!)),
                      _CostRow(label: 'Sisa Pembayaran', value: Formatters.rupiah(order.sisaTagihan)),
                      _CostRow(label: 'Status Pembayaran', value: order.isLunas ? 'LUNAS' : 'BELUM LUNAS', valueColor: order.isLunas ? AppColors.success : AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _ClauseHeader(number: '4', title: 'Ketentuan Umum'),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '1. Pihak Kedua wajib menjaga kebersihan dan kondisi barang selama masa sewa.\n'
                    '2. Kerusakan atau kehilangan barang menjadi tanggung jawab Pihak Kedua sesuai nilai penggantian yang berlaku.\n'
                    '3. Keterlambatan pengembalian dikenakan denda sesuai kebijakan yang berlaku di Pihak Pertama.\n'
                    '4. Uang jaminan/deposit (jika ada) akan dikembalikan setelah barang diperiksa dan dinyatakan sesuai kondisi awal.',
                    style: TextStyle(fontSize: 11.5, height: 1.6, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _SignatureBlock(label: 'Pihak Pertama', name: 'VIEGUARD Kostum & Drumband')),
                    const SizedBox(width: 16),
                    Expanded(child: _SignatureBlock(label: 'Pihak Kedua', name: order.customer.name)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadAndOpen,
              icon: _downloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(_downloading ? 'Mengunduh...' : 'Cetak / Simpan PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyBlock extends StatelessWidget {
  final String label;
  final String name;
  final String detail;
  const _PartyBlock({required this.label, required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _ClauseHeader extends StatelessWidget {
  final String number;
  final String title;
  const _ClauseHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: Text(number, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _CostRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
      ]),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String label;
  final String name;
  const _SignatureBlock({required this.label, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 48),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 6),
        Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
