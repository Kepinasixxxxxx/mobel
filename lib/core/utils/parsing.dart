double parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? parseDecimalOrNull(dynamic value) {
  if (value == null) return null;
  return parseDecimal(value);
}

DateTime? parseDateOrNull(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
