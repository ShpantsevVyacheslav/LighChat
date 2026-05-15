import 'package:flutter/services.dart';

/// Нативный TTS («прочитать вслух»).
///
/// iOS: `AVSpeechSynthesizer` (Speech framework) — оффлайн.
/// Android: `android.speech.tts.TextToSpeech` — оффлайн после загрузки
/// голосового пакета (системно).
///
/// Один Singleton — чтобы вызов «прочитать» автоматически останавливал
/// предыдущее чтение.
class LocalTextToSpeech {
  LocalTextToSpeech._();
  static final LocalTextToSpeech instance = LocalTextToSpeech._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/text_to_speech');

  /// Запустить чтение. Возвращает `true`, если нативный движок подтвердил
  /// старт. [languageTag] — короткий или BCP-47 код; если `null`, движок
  /// выберет по системной локали.
  Future<bool> speak({required String text, String? languageTag}) async {
    try {
      final ok = await _channel.invokeMethod<bool>('speak', <String, dynamic>{
        'text': text,
        'languageTag': languageTag,
      });
      return ok == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      /* ignore */
    } on PlatformException {
      /* ignore */
    }
  }

  Future<bool> get isSpeaking async {
    try {
      final v = await _channel.invokeMethod<bool>('isSpeaking');
      return v == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Информация о лучшем доступном голосе для языка. Используется чтобы
  /// показать пользователю tip «качайте Enhanced/Premium голос в Настройках»
  /// если установлен только Compact (звучит как робот).
  ///
  /// Поля:
  /// - `best`: `'premium' | 'enhanced' | 'default' | 'none'`
  /// - `hasEnhancedOrBetter`: `bool` — есть ли голос лучше Compact
  /// - `voiceName`: имя голоса (для UI)
  Future<TtsVoiceQuality> voiceQualityInfo({String? languageTag}) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'voiceQualityInfo',
        <String, dynamic>{'languageTag': languageTag},
      );
      if (raw == null) return const TtsVoiceQuality.none();
      return TtsVoiceQuality(
        best: (raw['best'] as String?) ?? 'none',
        hasEnhancedOrBetter: (raw['hasEnhancedOrBetter'] as bool?) ?? false,
        voiceName: raw['voiceName'] as String?,
        voiceLanguage: raw['voiceLanguage'] as String?,
      );
    } on MissingPluginException {
      return const TtsVoiceQuality.none();
    } on PlatformException {
      return const TtsVoiceQuality.none();
    }
  }
}

class TtsVoiceQuality {
  const TtsVoiceQuality({
    required this.best,
    required this.hasEnhancedOrBetter,
    this.voiceName,
    this.voiceLanguage,
  });

  const TtsVoiceQuality.none()
      : best = 'none',
        hasEnhancedOrBetter = false,
        voiceName = null,
        voiceLanguage = null;

  /// `'premium' | 'enhanced' | 'default' | 'none'`
  final String best;

  /// `true` если установлен Enhanced или Premium голос; `false` — только
  /// Compact или вообще ничего.
  final bool hasEnhancedOrBetter;

  /// Человекочитаемое имя выбранного голоса (например `Yuri (Enhanced)`).
  final String? voiceName;

  /// BCP-47 локаль голоса.
  final String? voiceLanguage;
}
