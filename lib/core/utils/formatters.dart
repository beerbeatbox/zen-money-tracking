String formatAmountWithComma(num amount, {int decimalDigits = 0}) {
  final fixed = amount.abs().toStringAsFixed(decimalDigits);
  final parts = fixed.split('.');
  final integerWithComma = _addThousandsSeparator(parts.first);
  final fraction =
      parts.length > 1 && parts[1].isNotEmpty ? '.${parts[1]}' : '';
  final result = '$integerWithComma$fraction';

  return amount < 0 ? '-$result' : result;
}

String formatCurrencySigned(double amount) {
  final formatted = formatAmountWithComma(amount.abs(), decimalDigits: 2);
  final prefix = amount < 0 ? '฿' : '฿';
  return '$prefix$formatted';
}

String formatNetBalance(double amount) {
  final formatted = formatAmountWithComma(amount.abs(), decimalDigits: 2);
  return amount < 0 ? '-฿$formatted' : '฿$formatted';
}

String _addThousandsSeparator(String value) {
  return value.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
