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

  /// Детальный статус — для отображения причины «почему недоступен».
  /// Значения: `available`, `appleIntelligenceNotEnabled`, `modelNotReady`,
  /// `deviceNotEligible`, `unsupportedOs`, `sdkMissing`, `unknown`.
  Future<String> availabilityStatus() async {
    try {
      final s = await _channel.invokeMethod<String>('availabilityStatus');
      return s ?? 'unknown';
    } on MissingPluginException {
      return 'sdkMissing';
    } on PlatformException {
      return 'unknown';
    }
  }

  /// Резюмирует текст одним-двумя предложениями на том же языке.
  /// Возвращает `null`, если LLM недоступен или вернул пусто.
  Future<String?> summarize(String text) async {
    return _stringCall('summarizeText', {'text': text});
  }

  /// Переписывает [text] в одном из стилей. Возвращает `null` при ошибке /
  /// недоступности — caller должен показать «не получилось» в UI.
  ///
  /// [style] — один из:
  ///  - `friendly` (по умолчанию) — теплее и дружелюбнее
  ///  - `formal` — формальнее и вежливее
  ///  - `shorter` — короче
  ///  - `longer` — развёрнутее с естественными деталями
  ///  - `proofread` — исправить орфографию/грамматику без изменения тона
  Future<String?> rewrite(String text, {String style = 'friendly'}) async {
    return _stringCall(
      'rewriteText',
      {'text': text, 'style': style},
    );
  }

  /// Digest по списку последних сообщений чата. [messages] — отформатировано
  /// клиентом как `Sender: text\n` (3–10 строк, ≤ ~50 слов в каждой), чтобы
  /// модели было удобно. Возвращает 3-5 буллетов в plain-тексте.
  Future<String?> summarizeMessages(String messages) async {
    return _stringCall('summarizeMessages', {'messages': messages});
  }

  Future<String?> _stringCall(
    String method,
    Map<String, dynamic> args,
  ) async {
    final raw = args['text'] as String? ?? args['messages'] as String? ?? '';
    if (raw.trim().isEmpty) return null;
    try {
      final s = await _channel.invokeMethod<String>(method, args);
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
