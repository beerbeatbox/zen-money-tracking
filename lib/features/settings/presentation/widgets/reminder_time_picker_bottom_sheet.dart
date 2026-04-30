import 'package:baht/core/extensions/widget_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showReminderTimePickerBottomSheet(BuildContext context) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ReminderTimePickerBottomSheet(),
  );
}

class _ReminderTimePickerBottomSheet extends StatefulWidget {
  @override
  State<_ReminderTimePickerBottomSheet> createState() =>
      _ReminderTimePickerBottomSheetState();
}

class _ReminderTimePickerBottomSheetState
    extends State<_ReminderTimePickerBottomSheet> {
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  bool _cancelPressed = false;
  bool _addPressed = false;

  static const _releaseDelay = Duration(milliseconds: 90);

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _selectedHour = now.hour;
    _selectedMinute = now.minute;
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

  void _setCancelPressed(bool value) {
    if (_cancelPressed == value) return;
    setState(() => _cancelPressed = value);
  }

  void _setAddPressed(bool value) {
    if (_addPressed == value) return;
    setState(() => _addPressed = value);
  }

  Future<void> _releaseCancelWithPause() async {
    await Future.delayed(_releaseDelay);
    if (!mounted) return;
    _setCancelPressed(false);
  }

  Future<void> _releaseAddWithPause() async {
    await Future.delayed(_releaseDelay);
    if (!mounted) return;
    _setAddPressed(false);
  }

  void _handleOk() {
    final result = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
    Navigator.of(context).pop(result);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    const sheetHeight = 320.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: sheetHeight,
        width: double.infinity,
        child: Container(
          height: sheetHeight,
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Text(
                  'SELECT TIME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: CupertinoPicker(
                              scrollController: _hourController,
                              itemExtent: 32,
                              useMagnifier: false,
                              looping: true,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedHour = index % 24;
                                });
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
                          const Text(
                            ':',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: CupertinoPicker(
                              scrollController: _minuteController,
                              itemExtent: 32,
                              useMagnifier: false,
                              looping: true,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMinute = index % 60;
                                });
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ).onTap(
                        onTapDown: (_) => _setCancelPressed(true),
                        onTapUp: (_) => _releaseCancelWithPause(),
                        onTapCancel: () => _releaseCancelWithPause(),
                        onTap: _handleCancel,
                        behavior: HitTestBehavior.opaque,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black),
                        ),
                        child: const Center(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ).onTap(
                        onTapDown: (_) => _setAddPressed(true),
                        onTapUp: (_) => _releaseAddWithPause(),
                        onTapCancel: () => _releaseAddWithPause(),
                        onTap: _handleOk,
                        behavior: HitTestBehavior.opaque,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
