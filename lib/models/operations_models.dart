import '../core/api/api_config.dart';
import '../core/utils/parsing.dart';

class SizeEntry {
  final String? id;
  final String studentName;
  final String? gender;
  final int? heightCm;
  final String size;
  final String? role;

  SizeEntry({this.id, required this.studentName, this.gender, this.heightCm, required this.size, this.role});

  factory SizeEntry.fromJson(Map<String, dynamic> json) => SizeEntry(
        id: json['id']?.toString(),
        studentName: json['studentName'] as String? ?? '-',
        gender: json['gender'] as String?,
        heightCm: json['heightCm'] as int?,
        size: json['size'] as String? ?? '-',
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'studentName': studentName,
        if (gender != null) 'gender': gender,
        if (heightCm != null) 'heightCm': heightCm,
        'size': size,
        if (role != null) 'role': role,
      };

  String get genderLabel => switch (gender?.toUpperCase()) { 'L' => 'Pria', 'P' => 'Wanita', _ => '-' };
}

class OrderPhoto {
  final String id;
  final String category;
  final String? title;
  final String imageUrl;
  final bool isPublic;
  final DateTime createdAt;

  OrderPhoto({required this.id, required this.category, this.title, required this.imageUrl, required this.isPublic, required this.createdAt});

  factory OrderPhoto.fromJson(Map<String, dynamic> json) => OrderPhoto(
        id: json['id'].toString(),
        category: json['category'] as String? ?? 'workshop',
        title: json['title'] as String?,
        imageUrl: resolveMediaUrl(json['imageUrl'] as String?, ApiConfig.origin) ?? '',
        isPublic: json['isPublic'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}

class Appointment {
  final String id;
  final String type;
  final String? orderId;
  final String? orderNumber;
  final String customerName;
  final DateTime startAt;
  final int durationMinutes;
  final String? room;
  final String? staffName;
  final String? note;

  Appointment({
    required this.id,
    required this.type,
    this.orderId,
    this.orderNumber,
    required this.customerName,
    required this.startAt,
    required this.durationMinutes,
    this.room,
    this.staffName,
    this.note,
  });

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));

  String get typeLabel => switch (type) { 'fitting' => 'Fitting', 'ambil' => 'Ambil Sewa', 'kembali' => 'Kembali Sewa', 'konsultasi' => 'Konsultasi', _ => type };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    return Appointment(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'fitting',
      orderId: json['orderId']?.toString(),
      orderNumber: order?['orderNumber'] as String?,
      customerName: json['customerName'] as String? ?? '-',
      startAt: DateTime.parse(json['startAt'] as String).toLocal(),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      room: json['room'] as String?,
      staffName: json['staffName'] as String?,
      note: json['note'] as String?,
    );
  }
}

class AdminSession {
  final String id;
  final String? deviceName;
  final DateTime createdAt;

  AdminSession({required this.id, this.deviceName, required this.createdAt});

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
        id: json['id'].toString(),
        deviceName: json['deviceName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}

class SecurityInfo {
  final bool hasPin;
  final DateTime? passwordChangedAt;
  final bool autoAcceptOrders;
  final List<AdminSession> sessions;

  SecurityInfo({required this.hasPin, this.passwordChangedAt, required this.autoAcceptOrders, required this.sessions});

  factory SecurityInfo.fromJson(Map<String, dynamic> json) => SecurityInfo(
        hasPin: json['hasPin'] as bool? ?? false,
        passwordChangedAt: parseDateOrNull(json['passwordChangedAt'])?.toLocal(),
        autoAcceptOrders: json['autoAcceptOrders'] as bool? ?? false,
        sessions: (json['sessions'] as List<dynamic>? ?? []).map((e) => AdminSession.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class CustomerSummary {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  CustomerSummary({required this.id, required this.name, this.email, this.phone});

  factory CustomerSummary.fromJson(Map<String, dynamic> json) => CustomerSummary(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '-',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );
}
