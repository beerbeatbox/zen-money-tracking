import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/feature_flags.dart';
import '../models/feature_flags_response.dart';

part 'onboarding_repository.g.dart';

abstract class OnboardingRepository {
  Future<FeatureFlags> getFeatureFlags();
}

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return OnboardingRepositoryImpl(dio);
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  final Dio _dio;

  OnboardingRepositoryImpl(this._dio);

  @override
  Future<FeatureFlags> getFeatureFlags() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // TODO: Replace with actual API call when backend is ready
    // final response = await _dio.get('/api/v1/onboarding/feature-flags');
    // final data = FeatureFlagsResponse.fromJson(response.data);
    // return data.toEntity();

    // Fake data for development
    final fakeResponse = {
      'show_ai_badge': true,
      'enable_language_selector': true,
      'primary_button_text': 'Start Tracking',
      'supported_languages': ['en', 'th', 'zh'],
    };

    final response = FeatureFlagsResponse.fromJson(fakeResponse);
    return response.toEntity();
  }
}
