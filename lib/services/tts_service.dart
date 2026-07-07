import 'package:flutter_tts/flutter_tts.dart';

import '../models/appliance_result.dart';

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);

    await _trySetVietnameseVoice();

    _initialized = true;
  }

  Future<void> _trySetVietnameseVoice() async {
    try {
      final voices = await _tts.getVoices;

      if (voices is List) {
        Map<String, dynamic>? bestVoice;
        Map<String, dynamic>? fallbackVoice;

        for (final item in voices) {
          if (item is Map) {
            final voice = Map<String, dynamic>.from(item);
            final locale = '${voice['locale'] ?? ''}'.toLowerCase();
            final name = '${voice['name'] ?? ''}'.toLowerCase();

            if (locale.startsWith('vi')) {
              fallbackVoice ??= voice;

              if (name.contains('google')) {
                bestVoice = voice;
                break;
              }
            }
          }
        }

        final selected = bestVoice ?? fallbackVoice;

        if (selected != null) {
          await _tts.setLanguage('${selected['locale']}');
          await _tts.setVoice({
            'name': '${selected['name']}',
            'locale': '${selected['locale']}',
          });
          return;
        }
      }
    } catch (_) {}

    try {
      await _tts.setLanguage('vi-VN');
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
  }

  Future<void> speakResult(ApplianceResult result) async {
    await _init();
    await stop();
    await _tts.speak(result.toSpeechText());
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}