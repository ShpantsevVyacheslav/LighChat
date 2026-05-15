import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// выберет по системной локали. [voiceIdentifier] — конкретный голос
  /// (см. [listVoices]); если null, используется сохранённый пользовательский
  /// выбор для этого языка, либо авто-best (premium > enhanced > default).
  Future<bool> speak({
    required String text,
    String? languageTag,
    String? voiceIdentifier,
  }) async {
    try {
      final explicit = voiceIdentifier ??
          (languageTag == null
              ? null
              : await getPreferredVoiceIdentifier(languageTag));
      final ok = await _channel.invokeMethod<bool>('speak', <String, dynamic>{
        'text': text,
        'languageTag': languageTag,
        if (explicit != null && explicit.isNotEmpty)
          'voiceIdentifier': explicit,
      });
      return ok == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Список всех установленных голосов на устройстве. Если задан
  /// [languageTag] — отфильтровано по языку (по точному совпадению или
  /// по короткому коду `ru` → `ru-*`). Каждый элемент — [TtsVoice] с
  /// `identifier`, `name`, `language`, `quality`, `isNoveltyOrEloquence`.
  ///
  /// На Android пока вернёт пустой список (native-side не реализован).
  Future<List<TtsVoice>> listVoices({String? languageTag}) async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'listVoices',
        <String, dynamic>{'languageTag': languageTag},
      );
      if (raw == null) return const <TtsVoice>[];
      return raw
          .whereType<Map>()
          .map((m) => TtsVoice(
                identifier: (m['identifier'] as String?) ?? '',
                name: (m['name'] as String?) ?? '',
                language: (m['language'] as String?) ?? '',
                quality: (m['quality'] as String?) ?? 'default',
                isNoveltyOrEloquence:
                    (m['isNoveltyOrEloquence'] as bool?) ?? false,
              ))
          .where((v) => v.identifier.isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      return const <TtsVoice>[];
    } on PlatformException {
      return const <TtsVoice>[];
    }
  }

  /// Возвращает пользовательский preferred-голос для данного языка, или
  /// `null` если ничего не выбрано (тогда движок применит auto-best).
  /// Ключ keyed по короткому коду языка (`ru`, `en`...) — голос обычно
  /// специфичен для языка, юзер хочет «русский такой-то / английский
  /// такой-то» а не «один на всё».
  Future<String?> getPreferredVoiceIdentifier(String languageTag) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKeyFor(languageTag);
      final v = prefs.getString(key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// Сохранить пользовательский выбор голоса для данного языка.
  /// Передать `null` чтобы сбросить на auto-best.
  Future<void> setPreferredVoiceIdentifier(
    String languageTag,
    String? voiceIdentifier,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKeyFor(languageTag);
      if (voiceIdentifier == null || voiceIdentifier.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, voiceIdentifier);
      }
    } catch (_) {}
  }

  String _prefsKeyFor(String languageTag) {
    final lang =
        languageTag.split('-').first.split('_').first.toLowerCase();
    return 'chat.tts_voice.$lang';
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

class TtsVoice {
  const TtsVoice({
    required this.identifier,
    required this.name,
    required this.language,
    required this.quality,
    required this.isNoveltyOrEloquence,
  });

  final String identifier;
  final String name;
  final String language;

  /// `'premium' | 'enhanced' | 'default'`
  final String quality;

  /// `true` для не-серьёзных iOS-голосов (Albert/Bahh/Whisper/Trinoids) —
  /// в основном UI скрываем, доступны через «Show all».
  final bool isNoveltyOrEloquence;
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
