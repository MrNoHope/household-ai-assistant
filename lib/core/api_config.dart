class ApiConfig {
  const ApiConfig._();

  static const dartDefineApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const localGeminiApiKey = '';

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static String get apiKey {
    final fromRunCommand = dartDefineApiKey.trim();
    if (fromRunCommand.isNotEmpty) return fromRunCommand;
    return localGeminiApiKey.trim();
  }

  static bool get hasKey => apiKey.trim().isNotEmpty;
}