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

/// Сентимент-анализ строки на устройстве.
///
/// iOS: `NLTagger` + `.sentimentScore` (`-1…+1`). Android: эвристика по
/// словарям маркеров на основных языках + знаки усиления.
class LocalTextSentimentDetector {
  LocalTextSentimentDetector._();
  static final LocalTextSentimentDetector instance =
      LocalTextSentimentDetector._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/voice_transcribe');

  final Map<String, double> _cache = <String, double>{};

  /// Возвращает `score` в `-1.0…+1.0`. `0` — нейтрально / не определено.
  Future<double> score(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final key = '${trimmed.length}|${trimmed.hashCode}';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'detectSentiment',
        <String, dynamic>{'text': trimmed},
      );
      final s = (raw?['score'] is num)
          ? (raw!['score'] as num).toDouble()
          : 0.0;
      _cache[key] = s;
      return s;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }
}

/// Какой эмодзи показать рядом с сообщением. `null` — слишком слабый сигнал,
/// ничего не показываем.
String? sentimentEmojiFor(double score) {
  if (score >= 0.45) return '😊';
  if (score >= 0.25) return '🙂';
  if (score <= -0.45) return '😞';
  if (score <= -0.25) return '😕';
  return null;
}
