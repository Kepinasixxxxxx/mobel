import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/operations_models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    Future.microtask(auth.fetchSecurity);
  }

  Future<bool?> _dialog(String title, List<Widget> fields, String action) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: fields)),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            Row(children: [
              Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx, false))),
              const SizedBox(width: 10),
              Expanded(child: VgButton(label: action, onPressed: () => Navigator.pop(ctx, true))),
            ]),
          ],
        ),
      );

  InputDecoration _pinDecoration(String label) => InputDecoration(labelText: label, counterText: '', isDense: true);

  Future<void> _setPin(bool hasPin) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final pin = TextEditingController();
    final confirm = TextEditingController();
    final password = TextEditingController();
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final ok = await _dialog(hasPin ? 'Ubah PIN Otorisasi' : 'Buat PIN Otorisasi', [
      TextField(controller: pin, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, inputFormatters: digits, decoration: _pinDecoration('PIN baru (6 digit)')),
      const SizedBox(height: 10),
      TextField(controller: confirm, obscureText: true, maxLength: 6, keyboardType: TextInputType.number, inputFormatters: digits, decoration: _pinDecoration('Ulangi PIN')),
      const SizedBox(height: 10),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi akun', isDense: true)),
    ], 'Simpan');
    if (ok != true) return;
    if (pin.text.length != 6 || pin.text != confirm.text) {
      messenger.showSnackBar(const SnackBar(content: Text('PIN harus 6 digit dan kedua isian harus sama.')));
      return;
    }
    final success = await auth.setPin(pin: pin.text, password: password.text);
    messenger.showSnackBar(SnackBar(content: Text(success ? 'PIN otorisasi tersimpan.' : auth.errorMessage ?? 'Gagal menyimpan PIN.')));
  }

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await _dialog('Ubah Kata Sandi', [
      TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi lama', isDense: true)),
      const SizedBox(height: 14),
      TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi baru (min. 8 karakter)', isDense: true)),
    ], 'Ubah');
    if (ok != true) return;
    if (newCtrl.text.length < 8) {
      messenger.showSnackBar(const SnackBar(content: Text('Kata sandi baru minimal 8 karakter.')));
      return;
    }
    final success = await auth.changePassword(oldPassword: oldCtrl.text, newPassword: newCtrl.text);
    if (success) await auth.fetchSecurity();
    messenger.showSnackBar(SnackBar(content: Text(success ? 'Kata sandi berhasil diubah.' : auth.errorMessage ?? 'Gagal mengubah kata sandi.')));
  }

  Future<void> _revoke(AdminSession session) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _dialog('Keluarkan Perangkat?', [
      Text('${session.deviceName ?? 'Perangkat tidak dikenal'} harus login ulang untuk mengakses akun ini.', style: const TextStyle(fontSize: 13.5, height: 1.4)),
    ], 'Keluarkan');
    if (ok != true) return;
    final success = await auth.revokeSession(session.id);
    messenger.showSnackBar(SnackBar(content: Text(success ? 'Perangkat dikeluarkan.' : auth.errorMessage ?? 'Gagal mengeluarkan perangkat.')));
  }

  IconData _deviceIcon(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('android') || n.contains('iphone') || n.contains('dart')) return Icons.smartphone_rounded;
    if (n.contains('windows') || n.contains('mac') || n.contains('mozilla')) return Icons.computer_rounded;
    return Icons.devices_other_rounded;
  }

  String _deviceLabel(String? name) {
    if (name == null || name.isEmpty) return 'Perangkat tidak dikenal';
    final n = name.toLowerCase();
    if (n.contains('dart')) return 'Aplikasi VIEGUARD (Android)';
    if (n.contains('android')) return 'Browser Android';
    if (n.contains('windows')) return 'Browser Windows';
    if (n.contains('iphone')) return 'iPhone';
    if (n.contains('mac')) return 'Browser macOS';
    return name.length > 40 ? '${name.substring(0, 40)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final security = auth.security;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Keamanan Akun'),
      body: security == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: auth.fetchSecurity,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  VgCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        VgIconBadge(icon: Icons.pin_outlined, color: Colors.white, background: AppColors.primary, size: 38),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('PIN Otorisasi', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            Text('Diminta saat verifikasi pembayaran & refund deposit', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < 6; i++)
                          Container(
                            width: 40,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.beigeSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: security.hasPin ? AppColors.primary : AppColors.border, width: security.hasPin ? 1.5 : 1),
                            ),
                            child: Text(security.hasPin ? '•' : '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      Center(
                        child: VgPill(
                          label: security.hasPin ? 'PIN aktif' : 'PIN belum dibuat',
                          color: security.hasPin ? AppColors.success : AppColors.warning,
                          background: security.hasPin ? AppColors.successBg : AppColors.warningBg,
                          dot: true,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      VgButton(label: security.hasPin ? 'Ubah PIN' : 'Buat PIN', icon: Icons.lock_reset_rounded, style: VgButtonStyle.soft, expanded: true, height: 42, onPressed: () => _setPin(security.hasPin)),
                    ]),
                  ),
                  VgCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      VgCardTitle(
                        title: 'Kata Sandi',
                        subtitle: security.passwordChangedAt != null ? 'Terakhir diubah ${Formatters.date(security.passwordChangedAt!)}' : 'Belum pernah diubah',
                        trailing: const VgIconBadge(icon: Icons.password_rounded, size: 38),
                      ),
                      VgButton(label: 'Ubah Kata Sandi', style: VgButtonStyle.outline, expanded: true, height: 42, onPressed: _changePassword),
                    ]),
                  ),
                  VgCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      VgCardTitle(
                        title: 'Perangkat Aktif',
                        subtitle: 'Keluarkan perangkat yang tidak dikenal',
                        trailing: VgPill(label: '${security.sessions.length}', color: AppColors.primary, background: AppColors.beige),
                      ),
                      if (security.sessions.isEmpty) const Text('Tidak ada sesi aktif.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      for (final s in security.sessions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: VgInset(
                            child: Row(children: [
                              Icon(_deviceIcon(s.deviceName), color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_deviceLabel(s.deviceName), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text('Login ${timeAgo(s.createdAt).toLowerCase()}', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                                ]),
                              ),
                              TapScale(
                                onTap: () => _revoke(s),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Text('Keluarkan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                  VgCard(
                    child: VgSwitchRow(
                      leading: const VgIconBadge(icon: Icons.notifications_active_outlined, color: Colors.white, background: AppColors.primary, size: 38),
                      title: 'Terima Pesanan Otomatis',
                      subtitle: 'Pesanan katalog (beli & sewa) langsung dikonfirmasi. Pesanan custom tetap perlu penawaran.',
                      value: security.autoAcceptOrders,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await auth.setAutoAccept(v);
                        messenger.showSnackBar(SnackBar(content: Text(ok ? (v ? 'Penerimaan otomatis diaktifkan.' : 'Penerimaan otomatis dimatikan.') : auth.errorMessage ?? 'Gagal menyimpan.')));
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
