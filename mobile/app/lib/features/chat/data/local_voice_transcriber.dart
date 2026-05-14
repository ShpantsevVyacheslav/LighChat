import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Локальная on-device транскрибация голосовых сообщений.
///
/// Реализуется нативно через MethodChannel `lighchat/voice_transcribe`:
/// - iOS: SFSpeechRecognizer (Speech Framework)
/// - Android: SpeechRecognizer.createOnDeviceSpeechRecognizer (API 31+)
///
/// Сетевые вызовы OpenAI / Cloud Function больше не используются —
/// поэтому работает в РФ без VPN и в E2EE-чатах.
class LocalVoiceTranscriber {
  LocalVoiceTranscriber._();
  static final LocalVoiceTranscriber instance = LocalVoiceTranscriber._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/voice_transcribe');

  /// In-memory cache «messageId → результат» на время жизни процесса.
  /// Для E2EE-сообщений это единственный источник transcript-а
  /// (на сервер plaintext не уходит).
  final Map<String, VoiceTranscriptionResult> _cache =
      <String, VoiceTranscriptionResult>{};

  List<String>? _supportedCache;

  /// Список BCP-47 локалей, доступных на этом устройстве.
  Future<List<String>> supportedLocales() async {
    final cached = _supportedCache;
    if (cached != null) return cached;
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('supportedLocales');
      final list = (raw ?? const <dynamic>[])
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      _supportedCache = list;
      return list;
    } on MissingPluginException {
      _supportedCache = const <String>[];
      return const <String>[];
    } on PlatformException {
      _supportedCache = const <String>[];
      return const <String>[];
    }
  }

  /// Получить кэшированный результат, если есть.
  VoiceTranscriptionResult? cachedFor(String messageId) => _cache[messageId];

  /// Транскрибировать удалённый или локальный файл (`widget.attachment.url`).
  ///
  /// [audioUrl] может быть `http(s)://...` или `file://...`. Метод сам
  /// скачает HTTP-ресурс во временный файл, передаст путь в нативный
  /// рекогнайзер и удалит временный файл после.
  ///
  /// [languageHint] — короткий код локали пользователя из l10n
  /// (например `'ru'`, `'es'`). Маппится в BCP-47.
  ///
  /// [autoDetect] — на iOS включает двухпроходный авто-детект языка через
  /// `NLLanguageRecognizer`. Покрывает кейс «UI на en, голосовое на ru».
  /// На Android параметр игнорируется (нет нативного аналога без ML Kit).
  Future<VoiceTranscriptionResult> transcribeAttachment({
    required String messageId,
    required String audioUrl,
    required String languageHint,
    bool autoDetect = true,
  }) async {
    final cached = _cache[messageId];
    if (cached != null && cached.text.isNotEmpty) return cached;

    final localPath = await _resolveToLocalFile(audioUrl);
    final languageTag = await _pickLanguageTag(languageHint);
    final fallbackLocales = autoDetect
        ? await _fallbackLocales(primary: languageTag)
        : const <String>[];
    File? tempFile;
    if (localPath.tempPath != null) tempFile = File(localPath.tempPath!);
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'transcribeFile',
        <String, dynamic>{
          'filePath': localPath.filePath,
          'languageTag': languageTag,
          'autoDetect': autoDetect,
          'fallbackLocales': fallbackLocales,
        },
      );
      final text = (raw?['text'] ?? '').toString().trim();
      final detected =
          (raw?['detectedLanguage'] ?? '').toString().trim().toLowerCase();
      final result = VoiceTranscriptionResult(
        text: text,
        detectedLanguage: detected.isEmpty ? null : detected,
      );
      _cache[messageId] = result;
      return result;
    } on PlatformException catch (e) {
      throw VoiceTranscriptionException(
        code: e.code,
        message: e.message ?? e.code,
      );
    } on MissingPluginException {
      throw const VoiceTranscriptionException(
        code: 'unavailable',
        message: 'Native transcriber is not registered on this platform.',
      );
    } finally {
      if (tempFile != null) {
        unawaited(tempFile.delete().catchError((_) => tempFile!));
      }
    }
  }

  Future<_ResolvedLocal> _resolveToLocalFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const VoiceTranscriptionException(
        code: 'invalid_url',
        message: 'Empty or malformed audio URL',
      );
    }
    if (uri.scheme == 'file') {
      return _ResolvedLocal(filePath: uri.toFilePath(), tempPath: null);
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final dir = await getTemporaryDirectory();
      final fileName = 'stt_${DateTime.now().microsecondsSinceEpoch}.m4a';
      final file = File('${dir.path}/$fileName');
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw VoiceTranscriptionException(
          code: 'download_failed',
          message: 'HTTP ${resp.statusCode}',
        );
      }
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return _ResolvedLocal(filePath: file.path, tempPath: file.path);
    }
    if (uri.scheme.isEmpty && url.startsWith('/')) {
      return _ResolvedLocal(filePath: url, tempPath: null);
    }
    throw VoiceTranscriptionException(
      code: 'unsupported_scheme',
      message: 'Unsupported audio URL scheme: ${uri.scheme}',
    );
  }

  /// Список локалей-кандидатов для повторного прогона, если основной язык
  /// вернул пустой результат. Это покрывает кейс «UI на en, а голосовое
  /// записали на русском» — английский рекогнайзер Apple возвращает
  /// пустоту, и NLLanguageRecognizer уже не может ничего детектировать.
  ///
  /// На iOS Swift-сторона по очереди пытается распознать с этими локалями
  /// и берёт первый непустой результат, далее уточняя через
  /// `NLLanguageRecognizer`.
  Future<List<String>> _fallbackLocales({required String primary}) async {
    final supported = await supportedLocales();
    final primaryLang = primary.split('-').first.toLowerCase();
    final candidates = <String>[];
    void addIf(String tag) {
      final lang = tag.split('-').first.toLowerCase();
      if (lang == primaryLang) return;
      if (candidates.contains(tag)) return;
      if (supported.isNotEmpty &&
          !supported.any((s) => s.toLowerCase() == tag.toLowerCase())) {
        return;
      }
      candidates.add(tag);
    }

    // Эвристика «двух главных языков аудитории» — русско-английская пара.
    if (primaryLang == 'en') {
      addIf('ru-RU');
    } else if (primaryLang == 'ru') {
      addIf('en-US');
    } else {
      addIf('en-US');
      addIf('ru-RU');
    }
    return candidates;
  }

  /// Карта коротких кодов l10n → BCP-47, с проверкой по supportedLocales().
  Future<String> _pickLanguageTag(String hint) async {
    final supported = await supportedLocales();
    final lower = hint.toLowerCase().trim();
    final candidates = <String>[
      ..._localeCandidates(lower),
      'en-US',
    ];
    if (supported.isEmpty) return candidates.first;
    for (final c in candidates) {
      if (supported.any((s) => s.toLowerCase() == c.toLowerCase())) return c;
    }
    for (final c in candidates) {
      final prefix = c.split('-').first.toLowerCase();
      final match = supported.firstWhere(
        (s) => s.toLowerCase().startsWith('$prefix-'),
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }
    return supported.first;
  }

  static List<String> _localeCandidates(String hint) {
    if (hint.contains('-') || hint.contains('_')) {
      final norm = hint.replaceAll('_', '-');
      return <String>[norm];
    }
    switch (hint) {
      case 'ru':
        return <String>['ru-RU'];
      case 'en':
        return <String>['en-US', 'en-GB'];
      case 'es':
        return <String>['es-ES', 'es-MX', 'es-US'];
      case 'pt':
        return <String>['pt-BR', 'pt-PT'];
      case 'tr':
        return <String>['tr-TR'];
      case 'id':
        return <String>['id-ID'];
      case 'kk':
        return <String>['kk-KZ'];
      case 'uz':
        return <String>['uz-UZ'];
      default:
        return <String>[hint];
    }
  }
}

class _ResolvedLocal {
  const _ResolvedLocal({required this.filePath, required this.tempPath});
  final String filePath;
  final String? tempPath;
}

class VoiceTranscriptionException implements Exception {
  const VoiceTranscriptionException({required this.code, required this.message});
  final String code;
  final String message;

  @override
  String toString() => 'VoiceTranscriptionException($code): $message';
}

/// Результат транскрипции голосового сообщения.
///
/// [detectedLanguage] — короткий ISO-код (`'ru'`, `'en'` и т.п.) языка,
/// на котором финально распозналось. `null`, если язык не определён
/// (например, результат пустой или старый кэш без этого поля).
class VoiceTranscriptionResult {
  const VoiceTranscriptionResult({
    required this.text,
    required this.detectedLanguage,
  });
  final String text;
  final String? detectedLanguage;
}
