typedef ScheduledPaymentValidationResult = ({double? amount, String? error});

ScheduledPaymentValidationResult parseAndValidateScheduledPayment({
  required String rawValue,
  required bool isExpense,
  required DateTime scheduledDateTime,
  bool requireFutureDate = true,
}) {
  final parsed = double.tryParse(rawValue);
  if (parsed == null) {
    return (amount: null, error: 'Please enter a valid number.');
  }
  if (parsed <= 0) {
    return (
      amount: null,
      error: 'Add an amount above zero to schedule a payment.',
    );
  }
  if (requireFutureDate && !scheduledDateTime.isAfter(DateTime.now())) {
    return (amount: null, error: 'Pick a future date to schedule this payment.');
  }
  if (!isExpense) {
    return (
      amount: null,
      error: 'Scheduled payments are expenses. Switch to Expense to continue.',
    );
  }

  return (amount: parsed, error: null);
}


