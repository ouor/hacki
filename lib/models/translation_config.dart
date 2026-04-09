class TranslationConfig {
  const TranslationConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.modelName = '',
    this.translatePrompt = '',
  });

  final String baseUrl;
  final String apiKey;
  final String modelName;
  final String translatePrompt;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      modelName.trim().isNotEmpty &&
      translatePrompt.trim().isNotEmpty;

  TranslationConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? modelName,
    String? translatePrompt,
  }) {
    return TranslationConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      translatePrompt: translatePrompt ?? this.translatePrompt,
    );
  }
}
