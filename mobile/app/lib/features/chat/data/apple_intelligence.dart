import 'dart:async';

import 'package:flutter/services.dart';

import 'local_message_translator.dart';
import 'local_text_language_detector.dart';

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

  /// Языки, которые понимает Foundation Models (iOS 26 + Apple
  /// Intelligence). Список постепенно расширяется Apple; обновлять
  /// здесь при добавлении новых. Русский / казахский / узбекский ещё не
  /// поддерживаются — для них используем bridge-translate через ML Kit.
  static const Set<String> _supportedLanguages = {
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh', 'vi',
  };

  /// `true` если язык [shortCode] (ISO `ru`, `en`...) обрабатывается
  /// Foundation Models напрямую без перевода-bridge.
  bool isLanguageSupportedNatively(String shortCode) {
    final code = shortCode.toLowerCase().split('-').first.split('_').first;
    return _supportedLanguages.contains(code);
  }

  /// Bridge-pipeline: source → en → Apple Intelligence → en → source.
  /// Используется когда исходный язык не входит в _supportedLanguages,
  /// но ML Kit умеет переводить пару source↔en.
  ///
  /// `operation` принимает английский текст и должна вернуть английский
  /// результат от AI; мы сами переводим input и output.
  Future<String?> _viaTranslateBridge({
    required String text,
    required String sourceLang,
    required Future<String?> Function(String enText) operation,
  }) async {
    final translator = LocalMessageTranslator.instance;
    if (!translator.supportsPair(from: sourceLang, to: 'en')) return null;
    try {
      final enInput = await translator.translate(
        cacheKey: 'ai-bridge-in|${text.hashCode}|$sourceLang→en',
        text: text,
        from: sourceLang,
        to: 'en',
      );
      final enOutput = await operation(enInput);
      if (enOutput == null || enOutput.trim().isEmpty) return null;
      final localized = await translator.translate(
        cacheKey: 'ai-bridge-out|${enOutput.hashCode}|en→$sourceLang',
        text: enOutput,
        from: 'en',
        to: sourceLang,
      );
      final cleaned = localized.trim();
      return cleaned.isEmpty ? null : cleaned;
    } catch (_) {
      return null;
    }
  }

  /// Детектит язык, и если он не нативно-поддерживаемый — гонит через
  /// bridge. Иначе — прямой вызов.
  Future<String?> _maybeViaBridge({
    required String text,
    required Future<String?> Function(String t) directCall,
  }) async {
    final det = await LocalTextLanguageDetector.instance.detect(text);
    if (det.isReliable && !isLanguageSupportedNatively(det.language)) {
      return _viaTranslateBridge(
        text: text,
        sourceLang: det.language,
        operation: directCall,
      );
    }
    return directCall(text);
  }

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
  /// Если язык не поддерживается Apple Intelligence (например русский),
  /// автоматически идёт через bridge: ML Kit перевод RU→EN → AI → EN→RU.
  Future<String?> summarize(String text) async {
    return _maybeViaBridge(
      text: text,
      directCall: (t) => _stringCall('summarizeText', {'text': t}),
    );
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
    return _maybeViaBridge(
      text: text,
      directCall: (t) => _stringCall(
        'rewriteText',
        {'text': t, 'style': style},
      ),
    );
  }

  /// Digest по списку последних сообщений чата. [messages] — отформатировано
  /// клиентом как `Sender: text\n` (3–10 строк, ≤ ~50 слов в каждой), чтобы
  /// модели было удобно. Возвращает 3-5 буллетов в plain-тексте.
  Future<String?> summarizeMessages(String messages) async {
    return _stringCall('summarizeMessages', {'messages': messages});
  }

  /// Smart Compose: предлагает продолжение для частично набранного
  /// сообщения. Возвращает короткий suggestion (1-12 слов) или `null`
  /// если LLM недоступен / текст слишком короткий / модель не нашла что
  /// дописать.
  ///
  /// Если язык не поддерживается нативно — bridge через ML Kit. Чуть
  /// медленнее (3 шага вместо 1), но debounce composer-а сглаживает.
  Future<String?> suggestContinuation(String prefix) async {
    return _maybeViaBridge(
      text: prefix,
      directCall: (t) => _stringCall('suggestContinuation', {'prefix': t}),
    );
  }

  /// Стриминг резюме — токены приходят накопительным content (каждая
  /// эмиссия = полный текст до текущего момента). Поток закрывается на
  /// `done`/`error`. Отмена через cancelStream(streamId) если subscription
  /// канселится раньше.
  ///
  /// Если язык не поддерживается нативно — стриминг недоступен (нельзя
  /// частично переводить накопительный английский ответ обратно в русский
  /// без «прыжков»). Вместо этого делаем full-shot через bridge и
  /// эмитим финальный результат одним событием.
  Stream<String> streamSummarize(String text) async* {
    final det = await LocalTextLanguageDetector.instance.detect(text);
    if (det.isReliable && !isLanguageSupportedNatively(det.language)) {
      final result = await _viaTranslateBridge(
        text: text,
        sourceLang: det.language,
        operation: (t) => _stringCall('summarizeText', {'text': t}),
      );
      if (result != null) yield result;
      return;
    }
    yield* _startStream(method: 'streamSummarize', args: {'text': text});
  }

  /// Стриминг переписывания. Bridge-path для не-нативных языков (как
  /// в [streamSummarize]).
  Stream<String> streamRewrite(String text, {String style = 'friendly'}) async* {
    final det = await LocalTextLanguageDetector.instance.detect(text);
    if (det.isReliable && !isLanguageSupportedNatively(det.language)) {
      final result = await _viaTranslateBridge(
        text: text,
        sourceLang: det.language,
        operation: (t) => _stringCall('rewriteText', {'text': t, 'style': style}),
      );
      if (result != null) yield result;
      return;
    }
    yield* _startStream(
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
    final raw = args['text'] as String? ??
        args['messages'] as String? ??
        args['prefix'] as String? ??
        '';
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
