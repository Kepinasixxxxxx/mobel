import 'package:flutter/material.dart';
import '../common/tap_scale.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../common/status_badge.dart';

class PesananOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const PesananOrderCard({super.key, required this.order, required this.onTap});

  String get _itemSummary {
    if (order.items.isEmpty) return order.orderType.label;
    final first = order.items.first;
    final extra = order.items.length > 1 ? ' +${order.items.length - 1} item lain' : '';
    return '${first.name}$extra';
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: order.status.color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                      TextSpan(text: ' · ${_timeAgo(order.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_itemSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  TagChip(label: order.orderType.label, color: AppColors.primary, background: AppColors.infoBg),
                ],
              ),
            ),
            if (order.status == OrderStatus.diproses) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: order.latestProgress / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.info),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${order.latestProgress}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Nilai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(Formatters.rupiah(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                      if (order.dpAmount != null && !order.isLunas)
                        Text('DP ${Formatters.rupiah(order.dpAmount!)}', style: const TextStyle(fontSize: 10.5, color: AppColors.success)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Detail', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}
