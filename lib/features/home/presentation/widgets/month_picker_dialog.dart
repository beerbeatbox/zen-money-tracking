import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showMonthPickerDialog(
  BuildContext context, {
  required DateTime initialMonth,
  int? firstYear,
  int? lastYear,
}) {
  final now = DateTime.now();
  final resolvedFirstYear = firstYear ?? (now.year - 10);
  final resolvedLastYear = lastYear ?? (now.year + 10);

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder:
        (_) => _MonthPickerDialog(
          initialMonth: DateTime(initialMonth.year, initialMonth.month),
          firstYear: resolvedFirstYear,
          lastYear: resolvedLastYear,
        ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initialMonth,
    required this.firstYear,
    required this.lastYear,
  });

  final DateTime initialMonth;
  final int firstYear;
  final int lastYear;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  static const _months = <String>[
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

  late int _year;
  late int _month; // 1..12

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year.clamp(widget.firstYear, widget.lastYear);
    _month = widget.initialMonth.month;
  }

  void _handleCancel() => Navigator.of(context).pop();

  void _handleOk() => Navigator.of(context).pop(DateTime(_year, _month));

  void _handleThisMonth() {
    final now = DateTime.now();
    setState(() {
      _year = now.year.clamp(widget.firstYear, widget.lastYear);
      _month = now.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canGoPrevYear = _year > widget.firstYear;
    final canGoNextYear = _year < widget.lastYear;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Pick month',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.black,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'This month',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ).onTap(onTap: _handleThisMonth),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed:
                      canGoPrevYear
                          ? () => setState(() => _year = _year - 1)
                          : null,
                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                  tooltip: 'Previous year',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_year',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      canGoNextYear
                          ? () => setState(() => _year = _year + 1)
                          : null,
                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                  tooltip: 'Next year',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == _month;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        _months[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ).onTap(
                    onTap: () => setState(() => _month = month),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedActionButton(
                    label: 'Cancel',
                    onPressed: _handleCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedActionButton(
                    label: 'OK',
                    onPressed: _handleOk,
                    textColor: Colors.white,
                    borderColor: Colors.black,
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


