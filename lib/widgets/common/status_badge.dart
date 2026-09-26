import 'package:flutter/material.dart';

import '../../models/order_status.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RentalStatusBadge extends StatelessWidget {
  final RentalStatus status;
  const RentalStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const TagChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
