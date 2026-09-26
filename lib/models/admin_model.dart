class Admin {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  Admin({required this.id, required this.name, required this.email, this.phone, required this.role});

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
      );
}
