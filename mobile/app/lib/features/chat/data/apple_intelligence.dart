import 'dart:async';

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
  static const EventChannel _streamChannel =
      EventChannel('lighchat/apple_intelligence_stream');

  /// Broadcast-стрим всех событий от native (`delta` / `done` / `error`).
  /// `streamId` диспатчится в _StreamRouter ниже — слушатель подписывается
  /// через `streamSummarize` / `streamRewrite`.
  static final Stream<Map<dynamic, dynamic>> _broadcast =
      _streamChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();

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

  /// Стриминг резюме — токены приходят накопительным content (каждая
  /// эмиссия = полный текст до текущего момента). Поток закрывается на
  /// `done`/`error`. Отмена через cancelStream(streamId) если subscription
  /// канселится раньше.
  Stream<String> streamSummarize(String text) {
    return _startStream(method: 'streamSummarize', args: {'text': text});
  }

  /// Стриминг переписывания.
  Stream<String> streamRewrite(String text, {String style = 'friendly'}) {
    return _startStream(
      method: 'streamRewrite',
      args: {'text': text, 'style': style},
    );
  }

  Stream<String> _startStream({
    required String method,
    required Map<String, dynamic> args,
  }) {
    final id = 'ai_${DateTime.now().microsecondsSinceEpoch}';
    final controller = StreamController<String>();
    StreamSubscription<Map<dynamic, dynamic>>? sub;

    Future<void> cleanup({Object? error}) async {
      await sub?.cancel();
      try {
        await _channel.invokeMethod<void>('cancelStream', {'streamId': id});
      } catch (_) {}
      if (error != null) {
        if (!controller.isClosed) controller.addError(error);
      }
      if (!controller.isClosed) await controller.close();
    }

    controller.onCancel = () async {
      await cleanup();
    };

    sub = _broadcast.listen((raw) {
      if (raw['streamId'] != id) return;
      final event = raw['event'] as String?;
      if (event == 'delta') {
        final content = (raw['content'] as String?) ?? '';
        if (!controller.isClosed) controller.add(content);
      } else if (event == 'done') {
        cleanup();
      } else if (event == 'error') {
        final reason = raw['reason'] as String? ?? 'unknown';
        cleanup(error: StateError('AI stream error: $reason'));
      }
    });

    // Запускаем стрим на native.
    () async {
      try {
        final started = await _channel.invokeMethod<bool>(method, {
          'streamId': id,
          ...args,
        });
        if (started != true) {
          await cleanup(error: StateError('AI stream rejected'));
        }
      } on MissingPluginException {
        await cleanup(error: StateError('sdkMissing'));
      } on PlatformException catch (e) {
        await cleanup(error: e);
      }
    }();

    return controller.stream;
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
