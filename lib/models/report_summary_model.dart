import '../core/utils/parsing.dart';

class OrderTypeCount {
  final String orderType;
  final int count;

  OrderTypeCount({required this.orderType, required this.count});

  factory OrderTypeCount.fromJson(Map<String, dynamic> json) => OrderTypeCount(
        orderType: json['orderType'] as String,
        count: (json['_count'] as Map<String, dynamic>)['id'] as int? ?? 0,
      );
}

class ReportSummary {
  final int totalOrders;
  final int completedOrders;
  final int totalCustomers;
  final double totalRevenue;
  final List<OrderTypeCount> ordersByType;

  ReportSummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.totalCustomers,
    required this.totalRevenue,
    required this.ordersByType,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        totalOrders: json['totalOrders'] as int? ?? 0,
        completedOrders: json['completedOrders'] as int? ?? 0,
        totalCustomers: json['totalCustomers'] as int? ?? 0,
        totalRevenue: parseDecimal(json['totalRevenue']),
        ordersByType: (json['ordersByType'] as List<dynamic>? ?? []).map((e) => OrderTypeCount.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
