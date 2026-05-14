import 'dart:async';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

  /// Персистентный SQLite-кэш переводов: при рестарте приложения переводы
  /// уже не нужно пересчитывать. Лениво открывается при первом обращении.
  Future<Database>? _dbFuture;

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
  ///
  /// [onPhase] — необязательный колбэк для UI: вызывается с фазой работы
  /// (`downloading` / `translating`). ML Kit не даёт реальный progress
  /// в процентах, но фаза «качаем модель» даёт пользователю понять, почему
  /// первое нажатие занимает ~10–15 сек.
  Future<String> translate({
    required String cacheKey,
    required String text,
    required String from,
    required String to,
    void Function(TranslationPhase phase)? onPhase,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    if (from == to) return trimmed;

    final cached = _resultCache[cacheKey];
    if (cached != null) return cached;

    // Персистентный кэш — переживает рестарт приложения, чтобы не качать
    // модель и не пересчитывать перевод при повторном открытии чата.
    final persisted = await _readPersistedTranslation(cacheKey);
    if (persisted != null) {
      _resultCache[cacheKey] = persisted;
      return persisted;
    }

    final src = _toMlKitLanguage(from);
    final dst = _toMlKitLanguage(to);
    if (src == null || dst == null) {
      throw UnsupportedTranslationException(from: from, to: to);
    }

    // Гарантируем загрузку обеих моделей. ML Kit сам не отдаёт прогресс
    // скачивания, но мы хотя бы сигналим UI о фазе «качаем», чтобы пользователь
    // понимал, что 5–15 сек ожидания — это разовая загрузка ~30 МБ.
    final needSrc = !await _modelManager.isModelDownloaded(src.bcpCode);
    final needDst = !await _modelManager.isModelDownloaded(dst.bcpCode);
    if (needSrc || needDst) {
      onPhase?.call(TranslationPhase.downloading);
      if (needSrc) {
        await _modelManager.downloadModel(src.bcpCode, isWifiRequired: false);
      }
      if (needDst) {
        await _modelManager.downloadModel(dst.bcpCode, isWifiRequired: false);
      }
    }

    onPhase?.call(TranslationPhase.translating);
    final key = '${src.bcpCode}->${dst.bcpCode}';
    final translator = _instances.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: src, targetLanguage: dst),
    );
    final translated = await translator.translateText(trimmed);
    _resultCache[cacheKey] = translated;
    unawaited(_writePersistedTranslation(
      cacheKey: cacheKey,
      from: from,
      to: to,
      text: translated,
    ));
    return translated;
  }

  // ---------------------- SQLite persistence ----------------------

  Future<Database> _db() {
    return _dbFuture ??= () async {
      final dir = await getApplicationSupportDirectory();
      final path = p.join(dir.path, 'lighchat_translations.db');
      return openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE translations (
              cache_key TEXT PRIMARY KEY,
              from_lang TEXT NOT NULL,
              to_lang TEXT NOT NULL,
              translated_text TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_translations_created_at ON translations(created_at)',
          );
        },
      );
    }();
  }

  Future<String?> _readPersistedTranslation(String cacheKey) async {
    try {
      final db = await _db();
      final rows = await db.query(
        'translations',
        columns: const ['translated_text'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final text = rows.first['translated_text'];
      return text is String ? text : null;
    } catch (_) {
      return null; // не валим перевод из-за проблем с кэшем
    }
  }

  Future<void> _writePersistedTranslation({
    required String cacheKey,
    required String from,
    required String to,
    required String text,
  }) async {
    try {
      final db = await _db();
      await db.insert(
        'translations',
        <String, Object?>{
          'cache_key': cacheKey,
          'from_lang': from,
          'to_lang': to,
          'translated_text': text,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // silently ignore — это всего лишь кэш
    }
  }

  /// Удалить все кэшированные переводы, чьи `cache_key` содержат указанную
  /// подстроку. Используется при «Retry» транскрипции голосового — если
  /// исходный текст пересчитался, старые переводы нерелевантны.
  ///
  /// [contains] — подстрока для поиска (обычно `messageId`). Безопасно
  /// вызывать, ошибки игнорируются.
  Future<void> invalidateContaining(String contains) async {
    _resultCache.removeWhere((key, _) => key.contains(contains));
    try {
      final db = await _db();
      await db.delete(
        'translations',
        where: 'cache_key LIKE ?',
        whereArgs: ['%$contains%'],
      );
    } catch (_) {
      // ignore
    }
  }

  /// Чистка устаревших записей (старше [olderThan]). Безопасно вызывать
  /// из housekeeping-тасков; не обязательно для штатной работы.
  Future<void> pruneOlderThan(Duration olderThan) async {
    try {
      final db = await _db();
      final cutoff =
          DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
      await db.delete(
        'translations',
        where: 'created_at < ?',
        whereArgs: [cutoff],
      );
    } catch (_) {
      // ignore
    }
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

/// Фаза работы переводчика — для информирования UI.
enum TranslationPhase {
  /// Скачивается языковая модель ML Kit (~30 МБ, одноразово).
  downloading,

  /// Модель есть, идёт само распознавание/перевод.
  translating,
}
