import 'package:intl/intl.dart';

const _monthLabels = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

enum SystemDateFormat {
  weekdayDayMonthYear('EEE d MMM yyyy');

  const SystemDateFormat(this.pattern);
  final String pattern;
}

enum SystemTimeFormat {
  hm24('HH:mm');

  const SystemTimeFormat(this.pattern);
  final String pattern;
}

String formatDateLabel(DateTime date) {
  final month = _monthLabels[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month $day, $year';
}

String formatWithPattern(DateTime date, SystemDateFormat format) {
  return DateFormat(format.pattern).format(date);
}

String formatTimeWithPattern(DateTime date, SystemTimeFormat format) {
  return DateFormat(format.pattern).format(date);
}

String formatDateWithWeekday(DateTime date) {
  const monthsShort = [
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
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekday = weekdays[date.weekday - 1];
  final month = monthsShort[date.month - 1];
  return '$weekday ${date.day} $month ${date.year}';
}

String formatTimeHm(DateTime date) {
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}
