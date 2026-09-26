import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _rupiah = NumberFormat.decimalPattern('id_ID');
  static final _date = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _dayDate = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String rupiah(double value) => 'Rp ${_rupiah.format(value)}';

  static String rupiahCompact(double value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return rupiah(value);
  }

  static String date(DateTime date) => _date.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String dayDate(DateTime date) => _dayDate.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static int daysLeft(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    return targetDay.difference(today).inDays;
  }
}
