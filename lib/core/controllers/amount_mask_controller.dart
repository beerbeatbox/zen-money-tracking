import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'amount_mask_controller.g.dart';

@riverpod
class AmountMaskController extends _$AmountMaskController {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}
