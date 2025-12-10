import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showLogTimePickerDialog(
  BuildContext context, {
  required DateTime initialDateTime,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _LogTimePickerDialog(initialDateTime: initialDateTime),
  );
}

class _LogTimePickerDialog extends StatefulWidget {
  const _LogTimePickerDialog({required this.initialDateTime});

  final DateTime initialDateTime;

  @override
  State<_LogTimePickerDialog> createState() => _LogTimePickerDialogState();
}

class _LogTimePickerDialogState extends State<_LogTimePickerDialog> {
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime;
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedHour = initial.hour;
    _selectedMinute = initial.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _handleOk() {
    final result = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    );
    Navigator.of(context).pop(result);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDate = DateTime(today.year - 2, today.month, today.day);
    final lastDate = DateTime(today.year + 2, today.month, today.day);
    final baseTheme = Theme.of(context);
    final datePickerTheme = baseTheme.datePickerTheme.copyWith(
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.black,
      ),
      dayOverlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: OutlinedSurface(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick log time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 330),
              child: Theme(
                data: baseTheme.copyWith(datePickerTheme: datePickerTheme),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.55,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 32,
                          useMagnifier: false,
                          looping: true,
                          onSelectedItemChanged: (index) {
                            _selectedHour = index % 24;
                          },
                          children: List.generate(
                            24,
                            (i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 32,
                          useMagnifier: false,
                          looping: true,
                          onSelectedItemChanged: (index) {
                            _selectedMinute = index % 60;
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
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
