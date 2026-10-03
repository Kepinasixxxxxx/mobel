import '../core/utils/parsing.dart';
import 'custom_order_detail_model.dart';
import 'customer_model.dart';
import 'order_item_model.dart';
import 'order_status.dart';
import 'order_status_history_model.dart';
import 'operations_models.dart';
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
  final String? courier;
  final String? trackingNumber;
  final double? shippingCost;
  final DateTime? shippedAt;
  final DateTime? etaDate;
  final List<SizeEntry> sizeEntries;
  final List<OrderPhoto> photos;

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
    this.courier,
    this.trackingNumber,
    this.shippingCost,
    this.shippedAt,
    this.etaDate,
    this.sizeEntries = const [],
    this.photos = const [],
  });

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  double get amountPaid => payments.where((p) => p.status == PaymentStatus.terverifikasi).fold(0, (sum, p) => sum + p.amount);

  double get sisaTagihan => (totalPrice - amountPaid).clamp(0, double.infinity);

  int get latestProgress => statusHistory.isEmpty ? 0 : statusHistory.last.progressPercentage;

  bool get butuhTindakan => status == OrderStatus.pending;

  bool get isCustom => orderType == OrderType.custom;

  bool get needsQuote => isCustom && status == OrderStatus.pending && totalPrice <= 0;

  String get headline => items.isNotEmpty ? items.first.name : (customOrderDetail?.jenisJenjang ?? 'Pesanan ${orderType.label}');

  String? get coverImage {
    for (final item in items) {
      if (item.imageUrl != null) return item.imageUrl;
    }
    return customOrderDetail?.designReference;
  }

  String? get latestStatusLabel => statusHistory.isEmpty ? null : statusHistory.last.statusLabel;

  bool get hasStudentSizes => sizeEntries.isNotEmpty;

  bool get isShipped => shippedAt != null;

  List<OrderPhoto> photosIn(String category) => photos.where((p) => p.category == category).toList();

  Map<String, int> get sizeBreakdown {
    final map = <String, int>{};
    if (sizeEntries.isNotEmpty) {
      for (final e in sizeEntries) {
        map[e.size] = (map[e.size] ?? 0) + 1;
      }
      return map;
    }
    for (final item in items) {
      if (item.size == null || item.size!.isEmpty) continue;
      map[item.size!] = (map[item.size!] ?? 0) + item.quantity;
    }
    return map;
  }

  int get sizedQuantity => sizeBreakdown.values.fold(0, (sum, q) => sum + q);

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
        courier: json['courier'] as String?,
        trackingNumber: json['trackingNumber'] as String?,
        shippingCost: parseDecimalOrNull(json['shippingCost']),
        shippedAt: parseDateOrNull(json['shippedAt'])?.toLocal(),
        etaDate: parseDateOrNull(json['etaDate']),
        sizeEntries: (json['orderSizeEntries'] as List<dynamic>? ?? []).map((e) => SizeEntry.fromJson(e as Map<String, dynamic>)).toList(),
        photos: (json['orderPhotos'] as List<dynamic>? ?? []).map((e) => OrderPhoto.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
