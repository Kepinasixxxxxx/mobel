import 'package:flutter/material.dart';
import '../../widgets/common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../state/notification_provider.dart';
import '../pesanan/detail_pesanan_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().fetchNotifications());
  }

  IconData _iconFor(String type) {
    final t = type.toUpperCase();
    if (t.contains('PAYMENT')) return Icons.account_balance_outlined;
    if (t.contains('PROGRESS')) return Icons.precision_manufacturing_outlined;
    if (t.contains('ORDER')) return Icons.receipt_long_outlined;
    return Icons.notifications_outlined;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final list = _unreadOnly ? provider.notifications.where((n) => !n.isRead).toList() : provider.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifikasi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              _FilterChip(label: 'Semua (${provider.notifications.length})', selected: !_unreadOnly, onTap: () => setState(() => _unreadOnly = false)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Belum Dibaca (${provider.unreadCount})', selected: _unreadOnly, onTap: () => setState(() => _unreadOnly = true)),
              const Spacer(),
              if (provider.unreadCount > 0)
                TextButton(onPressed: provider.markAllAsRead, child: const Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 11.5))),
            ]),
          ),
          Expanded(
            child: provider.isLoading && provider.notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: provider.fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: list.length,
                          itemBuilder: (context, index) => _NotificationCard(
                            notification: list[index],
                            icon: _iconFor(list[index].type),
                            timeLabel: _timeAgo(list[index].createdAt),
                            onTap: () {
                              provider.markAsRead(list[index].id);
                              if (list[index].relatedOrderId != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesananScreen(orderId: list[index].relatedOrderId!)));
                              }
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.icon, required this.timeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.infoBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    if (!notification.isRead) Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 3),
                  Text(notification.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(timeLabel, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
        child: Text(label, style: TextStyle(color: selected ? AppColors.onPrimary : AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
