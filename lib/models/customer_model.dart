class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;

  Customer({required this.id, required this.name, this.email, this.phone, this.address});

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '-',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}
