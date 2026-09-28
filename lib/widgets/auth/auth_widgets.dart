import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../common/tap_scale.dart';

class AuthColors {
  AuthColors._();

  static const maroonTop = Color(0xFF3A0008);
  static const maroonMid = Color(0xFF7A0015);
  static const maroonBottom = Color(0xFF140003);
  static const card = Color(0xFF52000D);
  static const field = Color(0xFF4A000B);
  static const border = Color(0xFF8A5A2A);
  static const gold = Color(0xFFE9C27A);
  static const goldLight = Color(0xFFFFE27A);
  static const goldDark = Color(0xFFDDA22A);
  static const text = Color(0xFFFFF4E0);
  static const muted = Color(0xFFC99A8F);
  static const sheet = Color(0xFF370D18);
}

TextStyle serifGold(double size) => GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.w700, color: AuthColors.gold);

TextStyle sans(double size, {Color color = AuthColors.text, FontWeight weight = FontWeight.w400, double spacing = 0}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, color: color, fontWeight: weight, letterSpacing: spacing);

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuthColors.maroonTop, AuthColors.maroonMid, AuthColors.maroonBottom],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

class AuthCard extends StatelessWidget {
  final List<Widget> children;
  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthColors.border.withValues(alpha: 0.7)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuthColors.card, AuthColors.maroonBottom.withValues(alpha: 0.9)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class AuthLabel extends StatelessWidget {
  final String text;
  const AuthLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(text, style: sans(15, weight: FontWeight.w500)),
    );
  }
}

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AuthColors.field,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AuthColors.border),
      ),
      child: Row(children: [
        const SizedBox(width: 18),
        Icon(widget.icon, color: AuthColors.gold, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: AuthColors.gold,
            style: sans(15, spacing: widget.isPassword ? 1.2 : 0),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: sans(14, color: AuthColors.muted.withValues(alpha: 0.7)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
            ),
          ),
        ),
        if (widget.isPassword)
          IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AuthColors.gold, size: 22),
            onPressed: () => setState(() => _obscure = !_obscure),
          )
        else
          const SizedBox(width: 18),
      ]),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GoldButton({super.key, required this.label, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return TapScale(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [AuthColors.goldDark, AuthColors.goldLight, AuthColors.goldDark]),
            boxShadow: [BoxShadow(color: AuthColors.goldDark.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AuthColors.maroonTop))
              : Text(label, style: sans(17, color: const Color(0xFF2A0006), weight: FontWeight.w700, spacing: 2)),
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(child: Container(height: 1, color: AuthColors.border.withValues(alpha: 0.7)));
    return Row(children: [
      line(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: sans(11, color: AuthColors.muted, weight: FontWeight.w600, spacing: 3)),
      ),
      line(),
    ]);
  }
}

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF45181F),
          boxShadow: [BoxShadow(color: AuthColors.gold.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 4)],
        ),
        child: Icon(icon, size: 52, color: AuthColors.text),
      ),
      const SizedBox(height: 28),
      Text(title, textAlign: TextAlign.center, style: serifGold(32)),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: sans(15, color: AuthColors.gold).copyWith(height: 1.45)),
    ]);
  }
}

Future<void> showAuthResult(
  BuildContext context, {
  required bool success,
  required String title,
  required String message,
  required String buttonLabel,
  required VoidCallback onPressed,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, anim, secondary) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondary, child) {
      final t = Curves.easeOutCubic.transform(anim.value);
      return Stack(children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t),
            child: Container(color: Colors.black.withValues(alpha: 0.35 * t)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: Offset(0, 1 - t),
            child: _ResultSheet(success: success, title: title, message: message, buttonLabel: buttonLabel, onPressed: onPressed),
          ),
        ),
      ]);
    },
  );
}

class _ResultSheet extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ResultSheet({required this.success, required this.title, required this.message, required this.buttonLabel, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final glow = success ? AuthColors.goldDark : const Color(0xFFB0102A);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipPath(
            clipper: _ArcClipper(),
            child: Container(
              width: double.infinity,
              color: AuthColors.sheet,
              padding: const EdgeInsets.fromLTRB(28, 110, 28, 36),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(title, textAlign: TextAlign.center, style: serifGold(34)),
                  const SizedBox(height: 14),
                  Text(message, textAlign: TextAlign.center, style: sans(15, color: AuthColors.gold)),
                  const SizedBox(height: 36),
                  GoldButton(label: buttonLabel, onPressed: onPressed),
                ]),
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glow.withValues(alpha: 0.25)),
              alignment: Alignment.center,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: success ? const [AuthColors.goldLight, AuthColors.goldDark] : const [Color(0xFF8C0A1E), Color(0xFF5A0010)],
                  ),
                  boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: 24)],
                ),
                child: Icon(success ? Icons.check_rounded : Icons.close_rounded, size: 40, color: success ? const Color(0xFF3A1A00) : AuthColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 36)
      ..quadraticBezierTo(size.width / 2, -8, size.width, 36)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
