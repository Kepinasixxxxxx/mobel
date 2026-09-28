import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/tap_scale.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode;
  const ResetPasswordScreen({super.key, required this.email, required this.otpCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  bool get _minLength => _newCtrl.text.length >= 8;
  bool get _hasNumberAndSymbol => RegExp(r'\d').hasMatch(_newCtrl.text) && RegExp(r'[^A-Za-z0-9]').hasMatch(_newCtrl.text);
  bool get _matches => _newCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _backToLogin() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _submit() async {
    if (!_minLength || !_hasNumberAndSymbol) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kata sandi belum memenuhi syarat.')));
      return;
    }
    if (!_matches) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi kata sandi tidak sama.')));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(email: widget.email, otpCode: widget.otpCode, newPassword: _newCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      await showAuthResult(
        context,
        success: true,
        title: 'Berhasil!',
        message: 'Kata sandi Anda telah berhasil diubah',
        buttonLabel: 'Kembali Ke Halaman Masuk',
        onPressed: () {
          Navigator.of(context).pop();
          _backToLogin();
        },
      );
    } else {
      await showAuthResult(
        context,
        success: false,
        title: 'Atur Ulang Kata Sandi Gagal',
        message: auth.errorMessage ?? 'Kata sandi Anda gagal diubah, silakan coba lagi',
        buttonLabel: 'Coba Lagi',
        onPressed: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          children: [
            const AuthHeader(
              icon: Icons.lock_reset_rounded,
              title: 'Atur Ulang Kata Sandi',
              subtitle: 'Kata sandi baru Anda harus berbeda dari\nkata sandi yang digunakan sebelumnya',
            ),
            const SizedBox(height: 40),
            AuthCard(children: [
              const AuthLabel('Kata Sandi Baru'),
              AuthField(controller: _newCtrl, hint: 'Kata sandi baru', icon: Icons.lock_outline_rounded, isPassword: true, onChanged: (_) => setState(() {})),
              const SizedBox(height: 14),
              _Rule(ok: _minLength, text: 'Minimal 8 karakter'),
              const SizedBox(height: 6),
              _Rule(ok: _hasNumberAndSymbol, text: 'Sertakan angka dan karakter khusus'),
              const SizedBox(height: 18),
              const AuthLabel('Konfirmasi Kata Sandi'),
              AuthField(controller: _confirmCtrl, hint: 'Ulangi kata sandi baru', icon: Icons.lock_outline_rounded, isPassword: true, onChanged: (_) => setState(() {}), onSubmitted: (_) => _submit()),
              const SizedBox(height: 28),
              GoldButton(label: 'Atur Ulang', loading: _loading, onPressed: _submit),
              const SizedBox(height: 22),
              Center(
                child: TapScale(
                  onTap: _backToLogin,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back, size: 20, color: AuthColors.goldLight),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali ke Halaman Masuk',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AuthColors.goldLight, decoration: TextDecoration.underline, decorationColor: AuthColors.goldLight),
                    ),
                  ]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final bool ok;
  final String text;
  const _Rule({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AuthColors.goldLight : AuthColors.muted;
    return Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 20, color: color),
      const SizedBox(width: 8),
      Text(text, style: sans(14, color: color)),
    ]);
  }
}
