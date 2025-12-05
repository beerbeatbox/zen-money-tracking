import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/onboarding_repository.dart';
import '../../domain/entities/feature_flags.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  Future<FeatureFlags> build() async {
    return _fetchFeatureFlags();
  }

  Future<FeatureFlags> _fetchFeatureFlags() async {
    final repository = ref.read(onboardingRepositoryProvider);
    return repository.getFeatureFlags();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFeatureFlags());
  }
}
