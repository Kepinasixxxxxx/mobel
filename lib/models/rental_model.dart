import '../core/api/api_config.dart';
import '../core/utils/parsing.dart';
import 'order_status.dart';

class Rental {
  final String id;
  final DateTime pickupDate;
  final DateTime returnDate;
  final DateTime? actualReturnDate;
  final String? pickupTime;
  final String? returnTime;
  final String? itemConditionBefore;
  final String? itemConditionAfter;
  final String? damageNote;
  final double? penaltyAmount;
  final double? depositAmount;
  final double? refundAmount;
  final String? refundStatus;
  final String? refundBank;
  final String? refundAccount;
  final String? refundHolder;
  final String? refundProofImage;
  final String? agreementPhoto;
  final DateTime? handoverAt;
  final DateTime? refundedAt;
  final RentalStatus status;

  Rental({
    required this.id,
    required this.pickupDate,
    required this.returnDate,
    this.actualReturnDate,
    this.pickupTime,
    this.returnTime,
    this.itemConditionBefore,
    this.itemConditionAfter,
    this.damageNote,
    this.penaltyAmount,
    this.depositAmount,
    this.refundAmount,
    this.refundStatus,
    this.refundBank,
    this.refundAccount,
    this.refundHolder,
    this.refundProofImage,
    this.agreementPhoto,
    this.handoverAt,
    this.refundedAt,
    required this.status,
  });

  int get totalDays => returnDate.difference(pickupDate).inDays.clamp(1, 999);

  int get daysElapsed => DateTime.now().difference(pickupDate).inDays.clamp(0, totalDays);

  bool get awaitingRefund => refundStatus == 'menunggu';

  double get refundDue => ((depositAmount ?? 0) - (penaltyAmount ?? 0)).clamp(0, double.infinity);

  factory Rental.fromJson(Map<String, dynamic> json) => Rental(
        id: json['id'].toString(),
        pickupDate: DateTime.parse(json['pickupDate'] as String),
        returnDate: DateTime.parse(json['returnDate'] as String),
        actualReturnDate: parseDateOrNull(json['actualReturnDate']),
        pickupTime: json['pickupTime'] as String?,
        returnTime: json['returnTime'] as String?,
        itemConditionBefore: json['itemConditionBefore'] as String?,
        itemConditionAfter: json['itemConditionAfter'] as String?,
        damageNote: json['damageNote'] as String?,
        penaltyAmount: parseDecimalOrNull(json['penaltyAmount']),
        depositAmount: parseDecimalOrNull(json['depositAmount']),
        refundAmount: parseDecimalOrNull(json['refundAmount']),
        refundStatus: json['refundStatus'] as String?,
        refundBank: json['refundBank'] as String?,
        refundAccount: json['refundAccount'] as String?,
        refundHolder: json['refundHolder'] as String?,
        refundProofImage: resolveMediaUrl(json['refundProofImage'] as String?, ApiConfig.origin),
        agreementPhoto: resolveMediaUrl(json['agreementPhoto'] as String?, ApiConfig.origin),
        handoverAt: parseDateOrNull(json['handoverAt'])?.toLocal(),
        refundedAt: parseDateOrNull(json['refundedAt'])?.toLocal(),
        status: rentalStatusFromApi(json['status'] as String),
      );
}
