import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../screens/akun/akun_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/notifikasi/notifikasi_screen.dart';
import '../../state/auth_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/notification_provider.dart';
import '../common/tap_scale.dart';

class VgCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const VgCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin = const EdgeInsets.only(bottom: 14), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
    return onTap == null ? card : TapScale(onTap: onTap, scaleDown: 0.98, child: card);
  }
}

class VgInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final double? width;

  const VgInset({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.color = AppColors.beige, this.radius = 14, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

class VgPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  final bool dot;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const VgPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
    this.dot = false,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6)],
        if (icon != null) ...[Icon(icon, size: fontSize + 2, color: color), const SizedBox(width: 5)],
        Flexible(child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }
}

class OrderStatusPill extends StatelessWidget {
  final Order order;
  final bool useProgressLabel;
  final bool withIcon;

  const OrderStatusPill({super.key, required this.order, this.useProgressLabel = false, this.withIcon = false});

  @override
  Widget build(BuildContext context) {
    if (order.needsQuote) {
      return VgPill(label: 'Menunggu Penawaran', color: AppColors.warning, background: AppColors.warningBg, icon: withIcon ? Icons.hourglass_top_rounded : null);
    }
    if (order.status == OrderStatus.siapDiambil && order.isShipped) {
      return VgPill(label: order.trackingNumber == null ? 'Siap Diambil' : 'Dikirim', color: AppColors.info, background: AppColors.infoBg, icon: withIcon ? Icons.local_shipping_outlined : null);
    }
    if (useProgressLabel && order.status == OrderStatus.diproses && order.latestStatusLabel != null) {
      return VgPill(label: order.latestStatusLabel!, color: AppColors.primary, background: AppColors.beige);
    }
    return VgPill(
      label: order.status.label,
      color: order.status.color,
      background: order.status.background,
      icon: withIcon ? (order.status == OrderStatus.pending ? Icons.hourglass_top_rounded : Icons.circle) : null,
    );
  }
}

enum VgButtonStyle { gold, maroon, soft, outline, amber, green }

class VgButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VgButtonStyle style;
  final double height;
  final bool expanded;
  final bool loading;
  final bool trailingIcon;

  const VgButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.style = VgButtonStyle.maroon,
    this.height = 48,
    this.expanded = false,
    this.loading = false,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    Color fg;
    Color? bg;
    Gradient? gradient;
    BoxBorder? border;
    switch (style) {
      case VgButtonStyle.gold:
        fg = AppColors.onGold;
        gradient = AppColors.goldGradient;
        break;
      case VgButtonStyle.maroon:
        fg = AppColors.onPrimary;
        bg = AppColors.primary;
        break;
      case VgButtonStyle.soft:
        fg = AppColors.primary;
        bg = AppColors.beige;
        break;
      case VgButtonStyle.outline:
        fg = AppColors.primary;
        bg = AppColors.surface;
        border = Border.all(color: AppColors.beige, width: 1.5);
        break;
      case VgButtonStyle.amber:
        fg = Colors.white;
        bg = const Color(0xFFF59E0B);
        break;
      case VgButtonStyle.green:
        fg = Colors.white;
        bg = const Color(0xFF2E7D4F);
        break;
    }
    final iconWidget = icon == null ? null : Icon(icon, size: 18, color: fg);
    final content = loading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (iconWidget != null && !trailingIcon) ...[iconWidget, const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14))),
            if (iconWidget != null && trailingIcon) ...[const SizedBox(width: 8), iconWidget],
          ]);
    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: TapScale(
        onTap: disabled ? null : onPressed,
        child: Container(
          height: height,
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(14),
            boxShadow: style == VgButtonStyle.gold ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

class VgIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final bool circle;

  const VgIconBadge({super.key, required this.icon, this.color = AppColors.primary, this.background = AppColors.beige, this.size = 40, this.circle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

class VgCardTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const VgCardTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ],
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}

class VgSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? badge;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const VgSectionHeader({super.key, required this.title, this.icon, this.badge, this.actionLabel, this.onAction, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 8)],
        Expanded(
          child: Row(children: [
            Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary))),
            if (badge != null) ...[const SizedBox(width: 10), Flexible(child: badge!)],
          ]),
        ),
        const SizedBox(width: 8),
        ?trailing,
        if (actionLabel != null)
          TapScale(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(actionLabel!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.goldDark),
              ]),
            ),
          ),
      ]),
    );
  }
}

class VgLogo extends StatelessWidget {
  final double size;
  const VgLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/logo.png',
        width: size * 0.78,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.shield_outlined, color: AppColors.primary, size: size * 0.6),
      ),
    );
  }
}

class VgAvatar extends StatelessWidget {
  final String name;
  final double size;
  const VgAvatar({super.key, required this.name, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.maroonGradient,
        border: Border.all(color: AppColors.goldLight, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(name.isEmpty ? 'A' : name[0].toUpperCase(), style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: size * 0.4)),
    );
  }
}

class VgTopBar extends StatelessWidget {
  final String subtitle;
  const VgTopBar({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    final unread = context.watch<NotificationProvider>().unreadCount;
    return Row(children: [
      const VgLogo(),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('VIEGUARD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.1)),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ]),
      ),
      TapScale(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 26),
            if (unread > 0)
              Positioned(
                top: 9,
                right: 10,
                child: Container(width: 9, height: 9, decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 1.5))),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 6),
      TapScale(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AkunScreen())),
        child: VgAvatar(name: admin?.name ?? 'Admin'),
      ),
    ]);
  }
}

class VgThumb extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  const VgThumb({super.key, this.url, this.size = 64, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: AppColors.beige, alignment: Alignment.center, child: Icon(Icons.checkroom_rounded, color: AppColors.primary, size: size * 0.45));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null ? placeholder : Image.network(url!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => placeholder),
      ),
    );
  }
}

class VgMoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  const VgMoneyField({super.key, required this.controller, this.prefix = 'Rp', this.suffix, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        if (prefix != null) ...[Text(prefix!, style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600)), const SizedBox(width: 10)],
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
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
        if (suffix != null) Text(suffix!, style: const TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class VgBackBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  const VgBackBar({super.key, required this.title, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.textPrimary), onPressed: () => Navigator.maybePop(context)),
            const VgLogo(size: 32),
            const SizedBox(width: 10),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
            ...actions,
            Padding(padding: const EdgeInsets.only(right: 16, left: 4), child: VgAvatar(name: admin?.name ?? 'Admin', size: 34)),
          ]),
        ),
      ),
    );
  }
}

Future<void> openChatWithCustomer(BuildContext context, Order order) async {
  final chat = context.read<ChatProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (chat.conversations.isEmpty) await chat.fetchConversations();
  final matches = chat.conversations.where((c) => c.customerId == order.customer.id);
  if (matches.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Belum ada percakapan dengan pelanggan ini.')));
    return;
  }
  navigator.push(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: matches.first)));
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  return '${diff.inDays} hari lalu';
}
