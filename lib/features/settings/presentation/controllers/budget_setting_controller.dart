import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:baht/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baht/features/settings/domain/usecases/settings_service.dart';

part 'budget_setting_controller.g.dart';

@immutable
class BudgetSetting {
  const BudgetSetting({
    required this.source,
    this.customAmount,
  });

  final BudgetSource source;
  final double? customAmount;
}

@Riverpod(keepAlive: true)
class BudgetSettingController extends _$BudgetSettingController {
  @override
  FutureOr<BudgetSetting> build() async {
    final service = ref.watch(settingsServiceProvider);
    final source = await service.getBudgetSource();
    final customAmount = await service.getCustomBudgetAmount();
    return BudgetSetting(source: source, customAmount: customAmount);
  }

  Future<void> setBudgetSource(BudgetSource source) async {
    final current = state.value;
    final customAmount = current?.customAmount;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setBudgetSource(source);
      // Invalidate dashboard to recalculate with new source
      ref.invalidate(dashboardControllerProvider);
      return BudgetSetting(source: source, customAmount: customAmount);
    });
  }

  Future<void> setCustomBudgetAmount(double? amount) async {
    final current = state.value;
    final source = current?.source ?? BudgetSource.autoConservative;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setCustomBudgetAmount(amount);
      // Invalidate dashboard to recalculate with new amount
      ref.invalidate(dashboardControllerProvider);
      return BudgetSetting(source: source, customAmount: amount);
    });
  }
}
