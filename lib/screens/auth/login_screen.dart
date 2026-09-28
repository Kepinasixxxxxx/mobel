import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/tap_scale.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _remember = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final saved = await context.read<AuthProvider>().tokenStorage.readRememberedEmail();
      if (saved != null && mounted) setState(() => _emailCtrl.text = saved);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    await auth.tokenStorage.saveRememberedEmail(_remember ? email : null);
    final ok = await auth.login(email, _passwordCtrl.text);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Login gagal.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: AuthBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            const _Logo(),
            const SizedBox(height: 40),
            AuthCard(children: [
              const AuthLabel('Email'),
              AuthField(controller: _emailCtrl, hint: 'nama@email.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              const AuthLabel('Kata Sandi'),
              AuthField(controller: _passwordCtrl, hint: 'Masukkan kata sandi', icon: Icons.lock_outline_rounded, isPassword: true, onSubmitted: (_) => _submit()),
              const SizedBox(height: 16),
              Row(children: [
                TapScale(
                  onTap: () => setState(() => _remember = !_remember),
                  child: Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _remember ? const Color(0xFF8C0A1E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _remember ? const Color(0xFF8C0A1E) : AuthColors.border),
                      ),
                      child: _remember ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 10),
                    Text('Ingat Saya', style: sans(14)),
                  ]),
                ),
                const Spacer(),
                TapScale(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _emailCtrl.text.trim()))),
                  child: Text('Lupa kata sandi?', style: sans(14)),
                ),
              ]),
              const SizedBox(height: 28),
              GoldButton(label: 'Masuk', loading: auth.isLoading, onPressed: _submit),
              const SizedBox(height: 28),
              const OrDivider('ATAU LANJUTKAN DENGAN'),
              const SizedBox(height: 22),
              TapScale(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login dengan Google belum tersedia untuk akun admin.')),
                ),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0005),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AuthColors.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('G', style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF4285F4))),
                    const SizedBox(width: 12),
                    Text('Google', style: sans(16)),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Image.asset(
        'assets/images/logo.png',
        height: 170,
        errorBuilder: (context, error, stack) => ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [AuthColors.goldDark, AuthColors.goldLight]).createShader(r),
          child: Text('V', style: GoogleFonts.cinzel(fontSize: 120, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
        ),
      ),
      const SizedBox(height: 16),
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(colors: [AuthColors.goldDark, AuthColors.goldLight, AuthColors.goldDark]).createShader(r),
        child: Text('VIEGUARD', style: GoogleFonts.cinzel(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 8)),
      ),
      Text('Selamat Datang!', style: GoogleFonts.greatVibes(fontSize: 44, color: AuthColors.gold)),
    ]);
  }
}
