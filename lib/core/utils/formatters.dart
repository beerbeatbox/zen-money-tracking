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

String formatDateLabel(DateTime date) {
  final month = _monthLabels[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month $day, $year';
}

String formatCurrencySigned(double amount) {
  final formatted = amount.abs().toStringAsFixed(2);
  final prefix = amount < 0 ? '-\$' : '+\$';
  return '$prefix$formatted';
}

String formatNetBalance(double amount) {
  final formatted = amount.abs().toStringAsFixed(2);
  return amount < 0 ? '-\$$formatted' : '\$$formatted';
}
