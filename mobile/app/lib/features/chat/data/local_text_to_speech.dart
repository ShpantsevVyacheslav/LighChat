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
}
