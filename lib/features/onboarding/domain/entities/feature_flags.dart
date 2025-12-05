class FeatureFlags {
  final bool showAIBadge;
  final bool enableLanguageSelector;
  final String primaryButtonText;
  final List<String> supportedLanguages;

  const FeatureFlags({
    required this.showAIBadge,
    required this.enableLanguageSelector,
    required this.primaryButtonText,
    required this.supportedLanguages,
  });
}

