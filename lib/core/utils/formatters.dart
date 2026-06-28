import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  static String chatTime(DateTime date) => DateFormat('h:mm a').format(date);

  /// Platform currency is Naira.
  static String money(num value) =>
      '₦${NumberFormat('#,##0').format(value)}';
}
