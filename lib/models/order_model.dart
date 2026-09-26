import '../core/utils/parsing.dart';
import 'custom_order_detail_model.dart';
import 'customer_model.dart';
import 'order_item_model.dart';
import 'order_status.dart';
import 'order_status_history_model.dart';
import 'payment_model.dart';
import 'rental_model.dart';

class Order {
  final String id;
  final String orderNumber;
  final OrderType orderType;
  final bool requiresProduction;
  final OrderStatus status;
  final double totalPrice;
  final double? dpAmount;
  final bool isLunas;
  final DateTime? deadlineDate;
  final String? notes;
  final DateTime createdAt;
  final Customer customer;
  final List<OrderItem> items;
  final CustomOrderDetail? customOrderDetail;
  final Rental? rental;
  final List<Payment> payments;
  final List<OrderStatusHistoryEntry> statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.requiresProduction,
    required this.status,
    required this.totalPrice,
    this.dpAmount,
    required this.isLunas,
    this.deadlineDate,
    this.notes,
    required this.createdAt,
    required this.customer,
    required this.items,
    this.customOrderDetail,
    this.rental,
    required this.payments,
    required this.statusHistory,
  });

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  double get amountPaid => payments.where((p) => p.status == PaymentStatus.terverifikasi).fold(0, (sum, p) => sum + p.amount);

  double get sisaTagihan => (totalPrice - amountPaid).clamp(0, double.infinity);

  int get latestProgress => statusHistory.isEmpty ? 0 : statusHistory.last.progressPercentage;

  bool get butuhTindakan => status == OrderStatus.pending;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'].toString(),
        orderNumber: json['orderNumber'] as String,
        orderType: orderTypeFromApi(json['orderType'] as String),
        requiresProduction: json['requiresProduction'] as bool? ?? false,
        status: orderStatusFromApi(json['status'] as String),
        totalPrice: parseDecimal(json['totalPrice']),
        dpAmount: parseDecimalOrNull(json['dpAmount']),
        isLunas: json['isLunas'] as bool? ?? false,
        deadlineDate: parseDateOrNull(json['deadlineDate']),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customer: Customer.fromJson(json['user'] as Map<String, dynamic>? ?? {'id': '0', 'name': 'Pelanggan'}),
        items: (json['items'] as List<dynamic>? ?? []).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
        customOrderDetail: json['customOrderDetail'] != null
            ? CustomOrderDetail.fromJson(json['customOrderDetail'] as Map<String, dynamic>)
            : null,
        rental: json['rental'] != null ? Rental.fromJson(json['rental'] as Map<String, dynamic>) : null,
        payments: (json['payments'] as List<dynamic>? ?? []).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
        statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) => OrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
