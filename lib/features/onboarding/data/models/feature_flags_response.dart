import '../../domain/entities/feature_flags.dart';

class FeatureFlagsResponse {
  final bool showAIBadge;
  final bool enableLanguageSelector;
  final String primaryButtonText;
  final List<String> supportedLanguages;

  const FeatureFlagsResponse({
    required this.showAIBadge,
    required this.enableLanguageSelector,
    required this.primaryButtonText,
    required this.supportedLanguages,
  });

  factory FeatureFlagsResponse.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsResponse(
      showAIBadge: json['show_ai_badge'] as bool? ?? true,
      enableLanguageSelector: json['enable_language_selector'] as bool? ?? true,
      primaryButtonText:
          json['primary_button_text'] as String? ?? 'Get Started',
      supportedLanguages:
          (json['supported_languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['en'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_ai_badge': showAIBadge,
      'enable_language_selector': enableLanguageSelector,
      'primary_button_text': primaryButtonText,
      'supported_languages': supportedLanguages,
    };
  }

  FeatureFlags toEntity() {
    return FeatureFlags(
      showAIBadge: showAIBadge,
      enableLanguageSelector: enableLanguageSelector,
      primaryButtonText: primaryButtonText,
      supportedLanguages: supportedLanguages,
    );
  }
}
