import 'dart:async';

import 'package:flutter/services.dart';

/// Определение языка строки на устройстве.
///
/// iOS: через `NLLanguageRecognizer` (Apple Natural Language framework).
/// Android: эвристика по Unicode-блокам (Cyrillic→ru, Latin→en и т.д.) —
/// достаточная для решения «другой ли это язык по сравнению с UI» и
/// дальнейшего перевода через ML Kit с фиксированным `from`.
///
/// Канал тот же, что у транскрибатора (`lighchat/voice_transcribe`), новый
/// метод `detectLanguage`. Возвращает короткий ISO-код языка
/// (`'ru'`, `'en'` и т.п.) и confidence `0…1`.
class LocalTextLanguageDetector {
  LocalTextLanguageDetector._();
  static final LocalTextLanguageDetector instance =
      LocalTextLanguageDetector._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/voice_transcribe');

  /// In-memory кэш «hash(text) → результат», чтобы не дёргать нативный код
  /// на каждый rebuild списка сообщений. Хеш + длина — компромисс между
  /// уникальностью и весом ключа.
  final Map<String, LanguageDetectionResult> _cache =
      <String, LanguageDetectionResult>{};

  Future<LanguageDetectionResult> detect(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LanguageDetectionResult(language: '', confidence: 0);
    }
    final key = '${trimmed.length}|${trimmed.hashCode}';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'detectLanguage',
        <String, dynamic>{'text': trimmed},
      );
      final lang = (raw?['language'] ?? '').toString().toLowerCase();
      final conf = (raw?['confidence'] is num)
          ? (raw!['confidence'] as num).toDouble()
          : 0.0;
      final result = LanguageDetectionResult(
        language: lang,
        confidence: conf,
      );
      _cache[key] = result;
      return result;
    } on MissingPluginException {
      return const LanguageDetectionResult(language: '', confidence: 0);
    } on PlatformException {
      return const LanguageDetectionResult(language: '', confidence: 0);
    }
  }
}

class LanguageDetectionResult {
  const LanguageDetectionResult({
    required this.language,
    required this.confidence,
  });
  final String language;
  final double confidence;

  bool get isReliable => language.isNotEmpty && confidence >= 0.6;
}
