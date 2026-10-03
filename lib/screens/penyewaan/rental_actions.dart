import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import 'handover_screen.dart';
import 'refund_screen.dart';

Future<void> confirmPickupFlow(BuildContext context, Order order) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => HandoverScreen(orderId: order.id)));

Future<void> openRefund(BuildContext context, Order order) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => RefundScreen(orderId: order.id)));
