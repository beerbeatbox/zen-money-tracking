import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

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

  void _handleToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
    });
    _hourController.animateToItem(
      _selectedHour,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
    _minuteController.animateToItem(
      _selectedMinute,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
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
                  'Pick log time',
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
                      HeroIcon(
                        HeroIcons.clock,
                        style: HeroIconStyle.outline,
                        color: Colors.black,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ).onTap(onTap: _handleToday),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 330),
              child: Theme(
                data: ThemeData(
                  useMaterial3: true,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  colorScheme: const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    primaryContainer: Colors.black,
                    onPrimaryContainer: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                    surfaceTint: Colors.transparent,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    dayForegroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.black;
                    }),
                    dayBackgroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black;
                      }
                      return Colors.transparent;
                    }),
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Colors.black),
                    labelLarge: TextStyle(color: Colors.black),
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: CalendarDatePicker(
                    key: ValueKey(_selectedDate.toIso8601String()),
                    initialCalendarMode: DatePickerMode.day,
                    initialDate: _selectedDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onDateChanged:
                        (date) => setState(() {
                          _selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                        }),
                  ),
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
