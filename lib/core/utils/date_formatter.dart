import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _fullDate = DateFormat('MMMM d, yyyy');
  static final _shortDate = DateFormat('MMM d, yyyy');
  static final _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final _timeOnly = DateFormat('h:mm a');
  static final _dayMonth = DateFormat('d MMM');
  static final _yearOnly = DateFormat('yyyy');

  /// Full date: "August 26, 2026"
  static String full(DateTime date) => _fullDate.format(date);

  /// Short date: "Aug 26, 2026"
  static String short(DateTime date) => _shortDate.format(date);

  /// Date and time: "Aug 26, 2026 • 4:30 PM"
  static String dateTime(DateTime date) => _dateTime.format(date);

  /// Time only: "4:30 PM"
  static String time(DateTime date) => _timeOnly.format(date);

  /// Day and month: "26 Aug"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// Year only: "2026"
  static String year(DateTime date) => _yearOnly.format(date);

  /// Relative time: "Just now", "5 minutes ago", "2 hours ago", "Yesterday", etc.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? "minute" : "minutes"} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? "hour" : "hours"} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? "day" : "days"} ago';
    }
    return short(date);
  }
}
