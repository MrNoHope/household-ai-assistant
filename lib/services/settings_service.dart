import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.apiKey,
    required this.model,
    required this.demoMode,
  });

  final String apiKey;
  final String model;
  final bool demoMode;

  AppSettings copyWith({String? apiKey, String? model, bool? demoMode}) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      demoMode: demoMode ?? this.demoMode,
    );
  }
}

class SettingsService {
  static const _apiKey = 'gemini_api_key';
  static const _model = 'gemini_model';
  static const _demoMode = 'demo_mode';

  static const defaultModel = 'gemini-2.5-flash';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiKey: prefs.getString(_apiKey) ?? '',
      model: prefs.getString(_model) ?? defaultModel,
      demoMode: prefs.getBool(_demoMode) ?? false,
    );
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, settings.apiKey.trim());
    await prefs.setString(_model, settings.model.trim().isEmpty ? defaultModel : settings.model.trim());
    await prefs.setBool(_demoMode, settings.demoMode);
  }
}
