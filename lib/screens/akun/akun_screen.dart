import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/notification_provider.dart';
import '../laporan/laporan_screen.dart';
import '../notifikasi/notifikasi_screen.dart';

class AkunScreen extends StatelessWidget {
  const AkunScreen({super.key});

  Future<void> _editProfile(BuildContext context, AuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.currentAdmin?.name);
    final phoneCtrl = TextEditingController(text: auth.currentAdmin?.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', isDense: true)),
              const SizedBox(height: 14),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await auth.updateProfile(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Profil diperbarui.' : auth.errorMessage ?? 'Gagal memperbarui profil.')));
  }

  Future<void> _changePassword(BuildContext context, AuthProvider auth) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Password'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Lama', isDense: true)),
              const SizedBox(height: 14),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ubah')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await auth.changePassword(oldPassword: oldCtrl.text, newPassword: newCtrl.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Password berhasil diubah.' : auth.errorMessage ?? 'Gagal mengubah password.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();
    final admin = auth.currentAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text((admin?.name.isNotEmpty == true ? admin!.name[0] : 'A').toUpperCase(), style: const TextStyle(color: AppColors.onPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(admin?.email ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (admin?.phone != null) Text(admin!.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (admin?.role != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(admin!.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info)),
                      ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: () => _editProfile(context, auth)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('OPERASIONAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            title: 'Laporan & Analitik',
            subtitle: 'Ringkasan omset & pesanan',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen())),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: notif.unreadCount > 0 ? '${notif.unreadCount} belum dibaca' : 'Semua sudah dibaca',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
          ),
          const SizedBox(height: 16),
          const Text('KEAMANAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _MenuTile(icon: Icons.lock_outline, title: 'Ubah Password', onTap: () => _changePassword(context, auth)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
