import '../core/utils/parsing.dart';
import 'order_status.dart';

class Payment {
  final String id;
  final String orderId;
  final String paymentType;
  final double amount;
  final String? paymentMethod;
  final String? proofImage;
  final String? refundReason;
  final PaymentStatus status;
  final String? verifierName;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final String? orderNumber;
  final String? customerName;
  final double? orderTotalPrice;

  Payment({
    required this.id,
    required this.orderId,
    required this.paymentType,
    required this.amount,
    this.paymentMethod,
    this.proofImage,
    this.refundReason,
    required this.status,
    this.verifierName,
    this.verifiedAt,
    required this.createdAt,
    this.orderNumber,
    this.customerName,
    this.orderTotalPrice,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    final user = order?['user'] as Map<String, dynamic>?;
    final verifier = json['verifier'] as Map<String, dynamic>?;
    return Payment(
      id: json['id'].toString(),
      orderId: json['orderId'].toString(),
      paymentType: json['paymentType'] as String,
      amount: parseDecimal(json['amount']),
      paymentMethod: json['paymentMethod'] as String?,
      proofImage: json['proofImage'] as String?,
      refundReason: json['refundReason'] as String?,
      status: paymentStatusFromApi(json['status'] as String),
      verifierName: verifier?['name'] as String?,
      verifiedAt: parseDateOrNull(json['verifiedAt']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      orderNumber: order?['orderNumber'] as String?,
      customerName: user?['name'] as String?,
      orderTotalPrice: parseDecimalOrNull(order?['totalPrice']),
    );
  }
}
