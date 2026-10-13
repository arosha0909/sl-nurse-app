/// Lightweight formatters (avoids pulling in `intl` for two helpers).
abstract final class Fmt {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// 148500 → "148,500"
  static String thousands(num value) {
    final digits = value.round().abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  static String lkr(num value) => 'LKR ${thousands(value)}';

  /// 3.0 → "3", 2.5 → "2.5"
  static String hours(double h) =>
      h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

  static String dayMonthYear(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';
  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
  static String month(int m) => _months[m - 1];

  /// 13:05 → "01:05 PM"
  static String time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Human distance from [now] to [t]: "in 45 min", "in 2 h 10 min", "5 min ago".
  static String relative(DateTime t, DateTime now) {
    final diff = t.difference(now);
    final mins = diff.inMinutes.abs();
    final text = mins < 60
        ? '$mins min'
        : '${mins ~/ 60} h${mins % 60 == 0 ? '' : ' ${mins % 60} min'}';
    return diff.isNegative ? '$text ago' : 'in $text';
  }
}
