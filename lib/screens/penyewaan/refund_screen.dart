import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../state/rental_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

class RefundScreen extends StatefulWidget {
  final String orderId;
  const RefundScreen({super.key, required this.orderId});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();
  XFile? _proof;
  bool _saving = false;
  bool _initialized = false;
  bool _editAccount = false;

  @override
  void dispose() {
    _bank.dispose();
    _account.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _submit(String rentalId, double amount) async {
    final rentals = context.read<RentalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (amount > 0 && _proof == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Unggah bukti transfer refund terlebih dahulu.')));
      return;
    }
    final (proceed, pin) = await requirePin(context);
    if (!proceed || !mounted) return;
    setState(() => _saving = true);
    final ok = await rentals.refund(
      rentalId,
      amount: amount,
      bank: _bank.text.trim(),
      account: _account.text.trim(),
      holder: _holder.text.trim(),
      proof: _proof,
      pin: pin,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Refund ${Formatters.rupiah(amount)} tercatat dan pelanggan diberi tahu.' : rentals.errorMessage ?? 'Gagal mencatat refund.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<RentalProvider>().rentalOrders.where((o) => o.id == widget.orderId);
    if (matches.isEmpty) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Refund Deposit'), body: Center(child: Text('Data sewa tidak ditemukan.')));
    }
    final order = matches.first;
    final rental = order.rental!;
    if (!_initialized) {
      _initialized = true;
      _bank.text = rental.refundBank ?? '';
      _account.text = rental.refundAccount ?? '';
      _holder.text = rental.refundHolder ?? order.customer.name;
      _editAccount = rental.refundAccount == null;
    }
    final deposit = rental.depositAmount ?? 0;
    final penalty = rental.penaltyAmount ?? 0;
    final refund = rental.refundDue;
    final done = rental.refundStatus == 'selesai';
    final returnedAt = rental.actualReturnDate;
    final late = returnedAt != null && returnedAt.isAfter(rental.returnDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Refund Deposit'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.spaceBetween, children: [
                VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
                done
                    ? const VgPill(label: 'Refund Selesai', color: AppColors.success, background: AppColors.successBg, dot: true, fontSize: 11)
                    : const VgPill(label: 'Menunggu Refund', color: AppColors.warning, background: AppColors.warningBg, dot: true, fontSize: 11),
              ]),
              const SizedBox(height: 10),
              Text(order.customer.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(
                returnedAt != null ? 'Dikembalikan ${Formatters.date(returnedAt)} · ${late ? 'terlambat' : 'tepat waktu'}' : 'Belum dikembalikan',
                style: const TextStyle(fontSize: 12.5, color: AppColors.primary),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                VgIconBadge(icon: Icons.account_balance_wallet_outlined, size: 38),
                SizedBox(width: 10),
                Expanded(child: Text('Rekonsiliasi Uang Jaminan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary))),
              ]),
              const SizedBox(height: 14),
              _Line(label: 'Deposit Ditahan Awal', value: Formatters.rupiah(deposit)),
              _Line(label: 'Denda & Potongan Perbaikan', value: '- ${Formatters.rupiah(penalty)}', badge: late ? 'Terlambat' : null),
              if (rental.damageNote != null) ...[
                VgInset(color: const Color(0xFFFFF4D6), child: Text(rental.damageNote!, style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4))),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: AppColors.maroonGradient, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TOTAL DEPOSIT DIKEMBALIKAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLight, letterSpacing: 0.6)),
                      SizedBox(height: 2),
                      Text('Ditransfer maks. 1×24 jam', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                    ]),
                  ),
                  Text(Formatters.rupiah(done ? (rental.refundAmount ?? refund) : refund), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
              ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Rekening Tujuan',
                subtitle: 'Data dari pelanggan saat pemesanan',
                trailing: done
                    ? null
                    : TapScale(
                        onTap: () => setState(() => _editAccount = !_editAccount),
                        child: Text(_editAccount ? 'Selesai' : 'Ubah', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
              ),
              if (_editAccount && !done) ...[
                const VgLabel('Bank'),
                VgTextField(controller: _bank, icon: Icons.account_balance_outlined, hint: 'BCA / BRI / Mandiri…'),
                const SizedBox(height: 10),
                const VgLabel('Nomor Rekening'),
                VgTextField(controller: _account, hint: '088-291-3819', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                const VgLabel('Atas Nama'),
                VgTextField(controller: _holder),
              ] else
                VgInset(
                  child: Row(children: [
                    const VgIconBadge(icon: Icons.account_balance_outlined, background: AppColors.surface, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_bank.text.isEmpty ? 'Bank belum diisi' : 'Bank ${_bank.text}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(_account.text.isEmpty ? '-' : _account.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('a/n ${_holder.text}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ]),
                    ),
                    if (_account.text.isNotEmpty)
                      TapScale(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _account.text));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor rekening disalin.')));
                        },
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Salin', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                      ),
                  ]),
                ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(title: 'Bukti Transfer Refund', subtitle: refund > 0 ? 'Wajib sebelum ditandai selesai' : 'Tidak ada dana yang dikembalikan'),
              SizedBox(
                height: 120,
                child: Row(children: [
                  if (done && rental.refundProofImage != null)
                    Expanded(child: VgPhotoTile(url: rental.refundProofImage, caption: 'Bukti refund'))
                  else if (_proof != null)
                    Expanded(child: VgPhotoTile(file: _proof, caption: 'Bukti refund', onRemove: () => setState(() => _proof = null)))
                  else if (!done)
                    Expanded(
                      child: VgAddPhotoTile(
                        label: '+ Bukti Transfer',
                        onTap: () async {
                          final picked = await pickPhotos(context, multiple: false);
                          if (picked.isNotEmpty) setState(() => _proof = picked.first);
                        },
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: done
          ? null
          : VgBottomBar(children: [
              VgButton(
                label: 'Konfirmasi Refund ${Formatters.rupiah(refund)}',
                icon: Icons.verified_user_outlined,
                style: VgButtonStyle.green,
                expanded: true,
                height: 52,
                loading: _saving,
                onPressed: () => _submit(rental.id, refund),
              ),
              const SizedBox(height: 6),
            ]),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  const _Line({required this.label, required this.value, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.primary))),
        if (badge != null) ...[const SizedBox(width: 6), VgPill(label: badge!, color: AppColors.danger, background: AppColors.dangerBg, fontSize: 10)],
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    );
  }
}
