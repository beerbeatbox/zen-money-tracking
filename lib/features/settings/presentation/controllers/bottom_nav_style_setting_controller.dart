import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:anti/features/settings/domain/usecases/settings_service.dart';

part 'bottom_nav_style_setting_controller.g.dart';

@Riverpod(keepAlive: true)
class BottomNavStyleSettingController extends _$BottomNavStyleSettingController {
  @override
  FutureOr<BottomNavStyle> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getBottomNavStyle();
  }

  Future<void> setStyle(BottomNavStyle style) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setBottomNavStyle(style);
      return style;
    });
  }
}
