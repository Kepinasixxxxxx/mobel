class CustomOrderDetail {
  final String? designReference;
  final String? designDescription;
  final String? jenisJenjang;
  final String? consultationNote;

  CustomOrderDetail({this.designReference, this.designDescription, this.jenisJenjang, this.consultationNote});

  factory CustomOrderDetail.fromJson(Map<String, dynamic> json) => CustomOrderDetail(
        designReference: json['designReference'] as String?,
        designDescription: json['designDescription'] as String?,
        jenisJenjang: json['jenisJenjang'] as String?,
        consultationNote: json['consultationNote'] as String?,
      );
}
