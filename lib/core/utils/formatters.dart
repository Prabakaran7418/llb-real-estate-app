import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return '₹${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '₹${lakhs.toStringAsFixed(lakhs.truncateToDouble() == lakhs ? 0 : 2)} Lakhs';
    }
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  static String formatSqFt(double sqft) {
    final format = NumberFormat('#,##0');
    return '${format.format(sqft)} Sq.Ft';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
