import 'package:flutter/services.dart';

/// Bridge к Apple Intelligence — Foundation Models framework (iOS 18.1+/26+).
///
/// На Android и старых iOS методы возвращают `false` / `null` без ошибок —
/// UI должен upgrade-fail gracefully на эвристику.
class AppleIntelligence {
  AppleIntelligence._();
  static final AppleIntelligence instance = AppleIntelligence._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/apple_intelligence');

  bool? _availableCache;

  /// Доступен ли on-device LLM прямо сейчас (фреймворк + модель + опт-ин юзера).
  /// Кешируем на время сессии — состояние редко меняется.
  Future<bool> isAvailable() async {
    final cached = _availableCache;
    if (cached != null) return cached;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      _availableCache = v == true;
    } on MissingPluginException {
      _availableCache = false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
  }

  /// Резюмирует текст одним-двумя предложениями на том же языке.
  /// Возвращает `null`, если LLM недоступен или вернул пусто — caller
  /// должен использовать heuristic-fallback.
  Future<String?> summarize(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final s = await _channel.invokeMethod<String>('summarizeText', {
        'text': trimmed,
      });
      final out = s?.trim();
      if (out == null || out.isEmpty) return null;
      return out;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
