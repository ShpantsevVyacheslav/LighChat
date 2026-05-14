import 'dart:async';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// On-device перевод через Google ML Kit Translation.
///
/// Модели качаются один раз (`~30 МБ` на пару) с `mlkit.gstatic.com` и
/// далее работают офлайн — поэтому работает в РФ без VPN и не требует
/// API-ключа. Используется для перевода транскриптов голосовых сообщений
/// и (в будущем) текстовых сообщений.
class LocalMessageTranslator {
  LocalMessageTranslator._();
  static final LocalMessageTranslator instance = LocalMessageTranslator._();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  /// Кэш активных `OnDeviceTranslator` инстансов по ключу `from→to`,
  /// чтобы не пересоздавать переводчик на каждый чих.
  final Map<String, OnDeviceTranslator> _instances =
      <String, OnDeviceTranslator>{};

  /// Кэш результатов перевода по композитному ключу — экономит CPU/батарею
  /// при повторных открытиях одной и той же транскрипции.
  final Map<String, String> _resultCache = <String, String>{};

  /// Проверяет, поддерживает ли ML Kit указанный язык.
  ///
  /// На входе ожидается короткий ISO-код (`'ru'`, `'en'`, `'kk'` и т.п.).
  /// Возвращает `false` для языков вне списка ML Kit (например `kk`, `uz`).
  bool supportsLanguage(String shortCode) =>
      _toMlKitLanguage(shortCode) != null;

  /// Доступен ли перевод между этими двумя языками.
  bool supportsPair({required String from, required String to}) =>
      supportsLanguage(from) && supportsLanguage(to) && from != to;

  /// Скачана ли модель целевого языка. Модель исходного скачивается
  /// автоматически вместе с целевой при первом запуске перевода.
  Future<bool> isModelDownloaded(String shortCode) async {
    final lang = _toMlKitLanguage(shortCode);
    if (lang == null) return false;
    return _modelManager.isModelDownloaded(lang.bcpCode);
  }

  /// Скачивает модель указанного языка, если её нет на устройстве.
  /// Безопасно вызывать многократно — ML Kit сам проверит статус.
  ///
  /// Возвращает `true` после успешного скачивания / если уже была.
  /// [requireWifi] — экономия трафика, по умолчанию `true`.
  Future<bool> ensureModel(
    String shortCode, {
    bool requireWifi = false,
  }) async {
    final lang = _toMlKitLanguage(shortCode);
    if (lang == null) return false;
    if (await _modelManager.isModelDownloaded(lang.bcpCode)) return true;
    return _modelManager.downloadModel(lang.bcpCode, isWifiRequired: requireWifi);
  }

  /// Перевод текста.
  ///
  /// [from] / [to] — короткие ISO-коды. Если хоть один не поддерживается
  /// — бросаем [UnsupportedTranslationException]. Если модель не скачана —
  /// автоматически качаем её перед переводом.
  Future<String> translate({
    required String cacheKey,
    required String text,
    required String from,
    required String to,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    if (from == to) return trimmed;

    final cached = _resultCache[cacheKey];
    if (cached != null) return cached;

    final src = _toMlKitLanguage(from);
    final dst = _toMlKitLanguage(to);
    if (src == null || dst == null) {
      throw UnsupportedTranslationException(from: from, to: to);
    }

    // Гарантируем загрузку обеих моделей.
    if (!await _modelManager.isModelDownloaded(src.bcpCode)) {
      await _modelManager.downloadModel(src.bcpCode, isWifiRequired: false);
    }
    if (!await _modelManager.isModelDownloaded(dst.bcpCode)) {
      await _modelManager.downloadModel(dst.bcpCode, isWifiRequired: false);
    }

    final key = '${src.bcpCode}->${dst.bcpCode}';
    final translator = _instances.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: src, targetLanguage: dst),
    );
    final translated = await translator.translateText(trimmed);
    _resultCache[cacheKey] = translated;
    return translated;
  }

  /// Очищаем кэш переводов и закрываем все живые инстансы.
  /// Имеет смысл вызывать на выходе из приложения, но не критично —
  /// инстансы лёгкие.
  Future<void> dispose() async {
    for (final t in _instances.values) {
      await t.close();
    }
    _instances.clear();
    _resultCache.clear();
  }

  /// Маппинг наших коротких кодов в enum ML Kit.
  /// `kk` и `uz` отсутствуют в ML Kit — возвращаем `null`, UI должен это
  /// учесть (показать «перевод недоступен» или скрыть кнопку).
  TranslateLanguage? _toMlKitLanguage(String shortCode) {
    final code = shortCode.toLowerCase().split('-').first.split('_').first;
    switch (code) {
      case 'en':
        return TranslateLanguage.english;
      case 'ru':
        return TranslateLanguage.russian;
      case 'es':
        return TranslateLanguage.spanish;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'de':
        return TranslateLanguage.german;
      case 'fr':
        return TranslateLanguage.french;
      case 'it':
        return TranslateLanguage.italian;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'uk':
        return TranslateLanguage.ukrainian;
      case 'be':
        return TranslateLanguage.belarusian;
      case 'pl':
        return TranslateLanguage.polish;
      case 'cs':
        return TranslateLanguage.czech;
      case 'nl':
        return TranslateLanguage.dutch;
      case 'sv':
        return TranslateLanguage.swedish;
      case 'no':
      case 'nb':
        return TranslateLanguage.norwegian;
      case 'fi':
        return TranslateLanguage.finnish;
      case 'da':
        return TranslateLanguage.danish;
      case 'el':
        return TranslateLanguage.greek;
      case 'he':
        return TranslateLanguage.hebrew;
      case 'th':
        return TranslateLanguage.thai;
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'ko':
        return TranslateLanguage.korean;
      case 'ro':
        return TranslateLanguage.romanian;
      case 'hu':
        return TranslateLanguage.hungarian;
      case 'bg':
        return TranslateLanguage.bulgarian;
      case 'ca':
        return TranslateLanguage.catalan;
      case 'hr':
        return TranslateLanguage.croatian;
      case 'sk':
        return TranslateLanguage.slovak;
      case 'sl':
        return TranslateLanguage.slovenian;
      case 'lv':
        return TranslateLanguage.latvian;
      case 'lt':
        return TranslateLanguage.lithuanian;
      case 'et':
        return TranslateLanguage.estonian;
      // Не поддерживается ML Kit: kk, uz, ну и эзотерика.
      default:
        return null;
    }
  }
}

class UnsupportedTranslationException implements Exception {
  const UnsupportedTranslationException({required this.from, required this.to});
  final String from;
  final String to;

  @override
  String toString() => 'Translation not available for $from → $to';
}
