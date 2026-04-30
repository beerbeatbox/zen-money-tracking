import 'package:baht/core/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

typedef OpenQuickLogKeyboard =
    Future<void> Function({required bool initialIsExpense});

class DashboardQuickAddHandler {
  bool _didHandleQuickAdd = false;

  void handle({
    required BuildContext context,
    required OpenQuickLogKeyboard openQuickLogKeyboard,
  }) {
    final state = GoRouterState.of(context);
    final quickAdd = state.uri.queryParameters['quickAdd'] == '1';

    if (!quickAdd) {
      // Allow widget taps to trigger Quick Add again after we clear the query.
      _didHandleQuickAdd = false;
      return;
    }

    if (_didHandleQuickAdd) return;
    _didHandleQuickAdd = true;

    // Temporary disabled: auto-open keyboard on widget tap
    // final type = (state.uri.queryParameters['type'] ?? '').trim().toLowerCase();
    // final initialIsExpense = type == 'income' ? false : true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      // Temporarily disabled: auto-open keyboard on widget tap
      // await openQuickLogKeyboard(initialIsExpense: initialIsExpense);
      if (!context.mounted) return;
      // Clear query params so we don't auto-open again on rebuild.
      context.go(AppRouter.dashboard.path);
    });
  }
}
