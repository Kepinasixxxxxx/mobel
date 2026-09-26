import 'package:flutter/material.dart';

enum OrderStatus { pending, dikonfirmasi, diproses, siapDiambil, selesai, dibatalkan }

enum OrderType { beli, sewa, custom }

enum RentalStatus { dipesan, diambil, dikembalikan, terlambat }

enum PaymentType { dp, pelunasan, refund }

enum PaymentStatus { menunggu, terverifikasi, ditolak }

OrderStatus orderStatusFromApi(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'dikonfirmasi':
      return OrderStatus.dikonfirmasi;
    case 'diproses':
      return OrderStatus.diproses;
    case 'siap_diambil':
      return OrderStatus.siapDiambil;
    case 'selesai':
      return OrderStatus.selesai;
    case 'dibatalkan':
      return OrderStatus.dibatalkan;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToApi(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.dikonfirmasi:
      return 'dikonfirmasi';
    case OrderStatus.diproses:
      return 'diproses';
    case OrderStatus.siapDiambil:
      return 'siap_diambil';
    case OrderStatus.selesai:
      return 'selesai';
    case OrderStatus.dibatalkan:
      return 'dibatalkan';
  }
}

OrderType orderTypeFromApi(String value) {
  switch (value) {
    case 'beli':
      return OrderType.beli;
    case 'sewa':
      return OrderType.sewa;
    case 'custom':
      return OrderType.custom;
    default:
      return OrderType.beli;
  }
}

String orderTypeToApi(OrderType type) {
  switch (type) {
    case OrderType.beli:
      return 'beli';
    case OrderType.sewa:
      return 'sewa';
    case OrderType.custom:
      return 'custom';
  }
}

RentalStatus rentalStatusFromApi(String value) {
  switch (value) {
    case 'dipesan':
      return RentalStatus.dipesan;
    case 'diambil':
      return RentalStatus.diambil;
    case 'dikembalikan':
      return RentalStatus.dikembalikan;
    case 'terlambat':
      return RentalStatus.terlambat;
    default:
      return RentalStatus.dipesan;
  }
}

String rentalStatusToApi(RentalStatus status) {
  switch (status) {
    case RentalStatus.dipesan:
      return 'dipesan';
    case RentalStatus.diambil:
      return 'diambil';
    case RentalStatus.dikembalikan:
      return 'dikembalikan';
    case RentalStatus.terlambat:
      return 'terlambat';
  }
}

PaymentStatus paymentStatusFromApi(String value) {
  switch (value) {
    case 'menunggu':
      return PaymentStatus.menunggu;
    case 'terverifikasi':
      return PaymentStatus.terverifikasi;
    case 'ditolak':
      return PaymentStatus.ditolak;
    default:
      return PaymentStatus.menunggu;
  }
}

String paymentStatusToApi(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.menunggu:
      return 'menunggu';
    case PaymentStatus.terverifikasi:
      return 'terverifikasi';
    case PaymentStatus.ditolak:
      return 'ditolak';
  }
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.dikonfirmasi:
        return 'Dikonfirmasi';
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.siapDiambil:
        return 'Siap Diambil';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.dikonfirmasi:
        return const Color(0xFF2563EB);
      case OrderStatus.diproses:
        return const Color(0xFF2563EB);
      case OrderStatus.siapDiambil:
        return const Color(0xFF16A34A);
      case OrderStatus.selesai:
        return const Color(0xFF16A34A);
      case OrderStatus.dibatalkan:
        return const Color(0xFFDC2626);
    }
  }

  Color get background {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatus.dikonfirmasi:
        return const Color(0xFFDBEAFE);
      case OrderStatus.diproses:
        return const Color(0xFFDBEAFE);
      case OrderStatus.siapDiambil:
        return const Color(0xFFD1FAE5);
      case OrderStatus.selesai:
        return const Color(0xFFD1FAE5);
      case OrderStatus.dibatalkan:
        return const Color(0xFFFEE2E2);
    }
  }
}

extension OrderTypeX on OrderType {
  String get label {
    switch (this) {
      case OrderType.beli:
        return 'Pembelian';
      case OrderType.sewa:
        return 'Penyewaan';
      case OrderType.custom:
        return 'Custom';
    }
  }
}

extension RentalStatusX on RentalStatus {
  String get label {
    switch (this) {
      case RentalStatus.dipesan:
        return 'Dipesan';
      case RentalStatus.diambil:
        return 'Sedang Digunakan';
      case RentalStatus.dikembalikan:
        return 'Dikembalikan';
      case RentalStatus.terlambat:
        return 'Terlambat';
    }
  }

  Color get color {
    switch (this) {
      case RentalStatus.dipesan:
        return const Color(0xFF2563EB);
      case RentalStatus.diambil:
        return const Color(0xFF16A34A);
      case RentalStatus.dikembalikan:
        return const Color(0xFF6B7280);
      case RentalStatus.terlambat:
        return const Color(0xFFDC2626);
    }
  }

  Color get background {
    switch (this) {
      case RentalStatus.dipesan:
        return const Color(0xFFDBEAFE);
      case RentalStatus.diambil:
        return const Color(0xFFD1FAE5);
      case RentalStatus.dikembalikan:
        return const Color(0xFFF3F4F8);
      case RentalStatus.terlambat:
        return const Color(0xFFFEE2E2);
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.menunggu:
        return 'Menunggu Verifikasi';
      case PaymentStatus.terverifikasi:
        return 'Terverifikasi';
      case PaymentStatus.ditolak:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.menunggu:
        return const Color(0xFFF59E0B);
      case PaymentStatus.terverifikasi:
        return const Color(0xFF16A34A);
      case PaymentStatus.ditolak:
        return const Color(0xFFDC2626);
    }
  }

  Color get background {
    switch (this) {
      case PaymentStatus.menunggu:
        return const Color(0xFFFEF3C7);
      case PaymentStatus.terverifikasi:
        return const Color(0xFFD1FAE5);
      case PaymentStatus.ditolak:
        return const Color(0xFFFEE2E2);
    }
  }
}
