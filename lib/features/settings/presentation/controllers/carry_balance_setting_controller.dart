import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/domain/usecases/settings_service.dart';

part 'carry_balance_setting_controller.g.dart';

@Riverpod(keepAlive: true)
class CarryBalanceSettingController extends _$CarryBalanceSettingController {
  @override
  FutureOr<bool> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getCarryBalanceEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setCarryBalanceEnabled(enabled);
      return enabled;
    });
  }
}


