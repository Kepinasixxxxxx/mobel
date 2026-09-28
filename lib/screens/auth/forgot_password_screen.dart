import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/tap_scale.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailCtrl = TextEditingController(text: widget.initialEmail);
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email yang valid.')));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: email)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Gagal mengirim kode.')));
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
              icon: Icons.key_rounded,
              title: 'Lupa Kata Sandi?',
              subtitle: 'Masukkan alamat email terdaftar Anda untuk menerima kode verifikasi 6 digit',
            ),
            const SizedBox(height: 40),
            AuthCard(children: [
              const AuthLabel('Email'),
              AuthField(controller: _emailCtrl, hint: 'nama@email.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, onSubmitted: (_) => _send()),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 2),
                  child: Icon(Icons.verified_user_rounded, size: 20, color: AuthColors.goldLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kami akan mengirimkan kode 6 digit dengan masa berlaku 15 menit untuk mengatur ulang kata sandi Anda.',
                    style: sans(14, color: AuthColors.text.withValues(alpha: 0.85)).copyWith(height: 1.4),
                  ),
                ),
              ]),
              const SizedBox(height: 28),
              GoldButton(label: 'Kirim', loading: _loading, onPressed: _send),
            ]),
            const SizedBox(height: 40),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: OrDivider('ATAU')),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Ingat kata sandi Anda? ', style: sans(16)),
              TapScale(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Masuk',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AuthColors.goldLight, decoration: TextDecoration.underline, decorationColor: AuthColors.goldLight),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
