import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/tap_scale.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());
  bool _resending = false;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < _length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      _nodes[(digits.length.clamp(1, _length)) - 1].requestFocus();
    } else if (v.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  void _next() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: widget.email, otpCode: _code)));
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.requestPasswordReset(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Kode baru telah dikirim.' : auth.errorMessage ?? 'Gagal mengirim ulang kode.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          children: [
            AuthHeader(
              icon: Icons.mark_email_read_outlined,
              title: 'Verifikasi Kode',
              subtitle: 'Masukkan 6 digit kode yang dikirim ke\n${widget.email}',
            ),
            const SizedBox(height: 40),
            AuthCard(children: [
              const AuthLabel('Kode Verifikasi'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_length, (i) {
                  return SizedBox(
                    width: 44,
                    height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      cursorColor: AuthColors.gold,
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AuthColors.text),
                      onChanged: (v) => _onChanged(i, v),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AuthColors.field,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AuthColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AuthColors.goldLight, width: 1.6)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              GoldButton(label: 'Verifikasi', onPressed: _code.length == _length ? _next : null),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Tidak menerima kode? ', style: sans(14)),
                TapScale(
                  onTap: _resending ? null : _resend,
                  child: Text(_resending ? 'Mengirim...' : 'Kirim ulang', style: sans(14, color: AuthColors.goldLight, weight: FontWeight.w700)),
                ),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}
