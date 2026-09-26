import '../core/utils/parsing.dart';
import 'order_status.dart';

class Rental {
  final String id;
  final DateTime pickupDate;
  final DateTime returnDate;
  final DateTime? actualReturnDate;
  final String? itemConditionBefore;
  final String? itemConditionAfter;
  final String? damageNote;
  final double? penaltyAmount;
  final RentalStatus status;

  Rental({
    required this.id,
    required this.pickupDate,
    required this.returnDate,
    this.actualReturnDate,
    this.itemConditionBefore,
    this.itemConditionAfter,
    this.damageNote,
    this.penaltyAmount,
    required this.status,
  });

  int get totalDays => returnDate.difference(pickupDate).inDays.clamp(1, 999);

  int get daysElapsed => DateTime.now().difference(pickupDate).inDays.clamp(0, totalDays);

  factory Rental.fromJson(Map<String, dynamic> json) => Rental(
        id: json['id'].toString(),
        pickupDate: DateTime.parse(json['pickupDate'] as String),
        returnDate: DateTime.parse(json['returnDate'] as String),
        actualReturnDate: parseDateOrNull(json['actualReturnDate']),
        itemConditionBefore: json['itemConditionBefore'] as String?,
        itemConditionAfter: json['itemConditionAfter'] as String?,
        damageNote: json['damageNote'] as String?,
        penaltyAmount: parseDecimalOrNull(json['penaltyAmount']),
        status: rentalStatusFromApi(json['status'] as String),
      );
}
