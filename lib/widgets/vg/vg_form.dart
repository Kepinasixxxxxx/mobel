import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../common/tap_scale.dart';
import 'vg_ui.dart';

class VgLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const VgLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ?trailing,
      ]),
    );
  }
}

class VgTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool strong;
  final Color color;

  const VgTextField({
    super.key,
    required this.controller,
    this.icon,
    this.hint,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.strong = false,
    this.color = AppColors.beigeSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: maxLines == 1 ? 52 : 0),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines == 1 ? 0 : 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 10)],
        if (prefix != null) ...[Text(prefix!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)), const SizedBox(width: 10)],
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 2,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? AppColors.primary : AppColors.textPrimary,
              height: maxLines == 1 ? null : 1.45,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: maxLines == 1 ? 16 : 0),
            ),
          ),
        ),
        if (suffix != null) Text(suffix!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }
}

class VgStepper extends StatefulWidget {
  final int value;
  final int min;
  final int? max;
  final ValueChanged<int> onChanged;

  const VgStepper({super.key, required this.value, this.min = 0, this.max, required this.onChanged});

  @override
  State<VgStepper> createState() => _VgStepperState();
}

class _VgStepperState extends State<VgStepper> {
  late final TextEditingController _ctrl = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
      } else {
        _commit(_ctrl.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VgStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && _ctrl.text != '${widget.value}') _ctrl.text = '${widget.value}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  int _clamp(int v) {
    var out = v < widget.min ? widget.min : v;
    if (widget.max != null && out > widget.max!) out = widget.max!;
    return out;
  }

  void _commit(String text) {
    final v = _clamp(int.tryParse(text) ?? widget.value);
    _ctrl.text = '$v';
    if (v != widget.value) widget.onChanged(v);
  }

  void _step(int delta) {
    _focus.unfocus();
    final v = _clamp(widget.value + delta);
    _ctrl.text = '$v';
    if (v != widget.value) widget.onChanged(v);
  }

  Widget _button(IconData icon, int delta, bool enabled) {
    return TapScale(
      onTap: enabled ? () => _step(delta) : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
        child: Icon(icon, size: 16, color: enabled ? AppColors.primary : AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _button(Icons.remove_rounded, -1, widget.value > widget.min),
      const SizedBox(width: 6),
      Container(
        width: 52,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
          onSubmitted: _commit,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      const SizedBox(width: 6),
      _button(Icons.add_rounded, 1, widget.max == null || widget.value < widget.max!),
    ]);
  }
}

class VgBottomBar extends StatelessWidget {
  final List<Widget> children;
  const VgBottomBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class VgSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;

  const VgSwitchRow({super.key, required this.title, this.subtitle, required this.value, required this.onChanged, this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (leading != null) ...[leading!, const SizedBox(width: 12)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: AppColors.primary, height: 1.35)),
        ]),
      ),
      Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: AppColors.primary, inactiveTrackColor: AppColors.beige),
    ]);
  }
}

class VgChoiceChips<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  const VgChoiceChips({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (value, label) in options)
        TapScale(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: value == selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: value == selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value == selected ? Colors.white : AppColors.textPrimary)),
          ),
        ),
    ]);
  }
}

class VgPhotoTile extends StatelessWidget {
  final XFile? file;
  final String? url;
  final String? caption;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const VgPhotoTile({super.key, this.file, this.url, this.caption, this.onRemove, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (file != null) {
      image = kIsWeb ? Image.network(file!.path, fit: BoxFit.cover) : FutureBuilder<Uint8List>(
          future: file!.readAsBytes(),
          builder: (context, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : Container(color: AppColors.beige),
        );
    } else {
      image = Image.network(url ?? '', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.beige, child: const Icon(Icons.image_not_supported_outlined, color: AppColors.primary)));
    }
    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          image,
          if (caption != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 5),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.88)])),
                child: Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          if (onRemove != null)
            Positioned(
              right: 4,
              top: 4,
              child: TapScale(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class VgAddPhotoTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const VgAddPhotoTile({super.key, this.label = '+ Foto', required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.goldDark, width: 1.2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_a_photo_outlined, size: 26, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}

Future<List<XFile>> pickPhotos(BuildContext context, {bool multiple = true}) async {
  final picker = ImagePicker();
  final source = kIsWeb
      ? ImageSource.gallery
      : await showModalBottomSheet<ImageSource>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                VgButton(label: 'Ambil dari Kamera', icon: Icons.photo_camera_outlined, expanded: true, onPressed: () => Navigator.pop(ctx, ImageSource.camera)),
                const SizedBox(height: 10),
                VgButton(label: 'Pilih dari Galeri', icon: Icons.photo_library_outlined, style: VgButtonStyle.soft, expanded: true, onPressed: () => Navigator.pop(ctx, ImageSource.gallery)),
              ]),
            ),
          ),
        );
  if (source == null) return [];
  if (source == ImageSource.gallery && multiple) return picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
  final single = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
  return single == null ? [] : [single];
}

Future<String?> _askPin(BuildContext context) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Masukkan PIN Otorisasi'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 10, color: AppColors.primary),
        decoration: const InputDecoration(counterText: '', hintText: '••••••'),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        Row(children: [
          Expanded(child: VgButton(label: 'Batal', style: VgButtonStyle.soft, onPressed: () => Navigator.pop(ctx))),
          const SizedBox(width: 10),
          Expanded(child: VgButton(label: 'Lanjutkan', onPressed: () => Navigator.pop(ctx, ctrl.text))),
        ]),
      ],
    ),
  );
}

Future<(bool, String?)> requirePin(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final security = auth.security ?? await auth.fetchSecurity();
  if (security == null || !security.hasPin) return (true, null);
  if (!context.mounted) return (false, null);
  final pin = await _askPin(context);
  if (pin == null || pin.length != 6) return (false, null);
  return (true, pin);
}
