import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Результат чтения буфера для вставки в композер (текст и/или файлы).
class ComposerClipboardPastePayload {
  const ComposerClipboardPastePayload({
    this.text,
    this.files = const <XFile>[],
  });

  final String? text;
  final List<XFile> files;
}

extension _DataReaderX on DataReader {
  Future<T?> readClipboardValue<T extends Object>(ValueFormat<T> format) {
    final c = Completer<T?>();
    final progress = getValue<T>(
      format,
      (value) => c.complete(value),
      onError: c.completeError,
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }

  Future<Uint8List?> readClipboardFileBytes(FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = getFile(format, (file) async {
      try {
        final bytes = await file.readAll();
        c.complete(bytes);
      } catch (e) {
        c.completeError(e);
      }
    }, onError: c.completeError);
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }
}

Future<XFile?> writeClipboardTempFile({
  required Uint8List bytes,
  required FileFormat format,
  required int sequence,
}) async {
  if (bytes.isEmpty) return null;
  final meta = clipboardFileMeta(format);
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final name = 'clipboard_${stamp}_$sequence.${meta.extension}';
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, name: name, mimeType: meta.mimeType);
}

({String extension, String mimeType}) clipboardFileMeta(FileFormat format) {
  if (format == Formats.pdf) {
    return (extension: 'pdf', mimeType: 'application/pdf');
  }
  if (format == Formats.zip) {
    return (extension: 'zip', mimeType: 'application/zip');
  }
  if (format == Formats.plainTextFile) {
    return (extension: 'txt', mimeType: 'text/plain');
  }
  if (format == Formats.mp3) return (extension: 'mp3', mimeType: 'audio/mpeg');
  if (format == Formats.wav) return (extension: 'wav', mimeType: 'audio/wav');
  if (format == Formats.aac) return (extension: 'aac', mimeType: 'audio/aac');
  if (format == Formats.json) {
    return (extension: 'json', mimeType: 'application/json');
  }
  if (format == Formats.png) return (extension: 'png', mimeType: 'image/png');
  if (format == Formats.jpeg) {
    return (extension: 'jpg', mimeType: 'image/jpeg');
  }
  if (format == Formats.heic) {
    return (extension: 'heic', mimeType: 'image/heic');
  }
  if (format == Formats.heif) {
    return (extension: 'heif', mimeType: 'image/heif');
  }
  if (format == Formats.webp) {
    return (extension: 'webp', mimeType: 'image/webp');
  }
  if (format == Formats.gif) return (extension: 'gif', mimeType: 'image/gif');
  if (format == Formats.tiff) {
    return (extension: 'tiff', mimeType: 'image/tiff');
  }
  if (format == Formats.bmp) return (extension: 'bmp', mimeType: 'image/bmp');
  if (format == Formats.mp4) return (extension: 'mp4', mimeType: 'video/mp4');
  if (format == Formats.mov) {
    return (extension: 'mov', mimeType: 'video/quicktime');
  }
  if (format == Formats.m4v) return (extension: 'm4v', mimeType: 'video/mp4');
  if (format == Formats.webm) {
    return (extension: 'webm', mimeType: 'video/webm');
  }
  if (format == Formats.avi) {
    return (extension: 'avi', mimeType: 'video/x-msvideo');
  }
  if (format == Formats.mpeg) {
    return (extension: 'mpeg', mimeType: 'video/mpeg');
  }
  if (format == Formats.wmv) {
    return (extension: 'wmv', mimeType: 'video/x-ms-wmv');
  }
  if (format == Formats.flv) {
    return (extension: 'flv', mimeType: 'video/x-flv');
  }
  if (format == Formats.mkv) {
    return (extension: 'mkv', mimeType: 'video/x-matroska');
  }
  if (format == Formats.ts) return (extension: 'ts', mimeType: 'video/mp2t');
  if (format == Formats.ogg) return (extension: 'ogg', mimeType: 'video/ogg');
  return (extension: 'bin', mimeType: 'application/octet-stream');
}

/// Переупорядочивает форматы, отдавая приоритет тем, что сохраняют альфа‑канал
/// (PNG/WebP/GIF/HEIC) перед JPEG.
///
/// Зачем: iOS при копировании стикеров/memoji кладёт в буфер сразу несколько
/// UTType‑репрезентаций одного и того же ресурса (обычно `public.png` с альфой
/// и `public.jpeg` как fallback). Если читать первый попавшийся `FileFormat`,
/// можно получить JPEG и потерять прозрачность. Эта сортировка гарантирует,
/// что стикер вставится в чат как PNG с сохранённой прозрачностью.
List<FileFormat> _sortFormatsStickerFirst(List<FileFormat> formats) {
  int rank(FileFormat f) {
    if (f == Formats.png) return 0;
    if (f == Formats.webp) return 1;
    if (f == Formats.gif) return 2;
    if (f == Formats.heic) return 3;
    if (f == Formats.heif) return 3;
    if (f == Formats.tiff) return 4;
    if (f == Formats.bmp) return 4;
    if (f == Formats.jpeg) return 20;
    return 10;
  }

  final copy = List<FileFormat>.of(formats);
  copy.sort((a, b) => rank(a).compareTo(rank(b)));
  return copy;
}

String guessMimeByPath(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
  if (p.endsWith('.heic')) return 'image/heic';
  if (p.endsWith('.heif')) return 'image/heif';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.gif')) return 'image/gif';
  if (p.endsWith('.tiff') || p.endsWith('.tif')) return 'image/tiff';
  if (p.endsWith('.bmp')) return 'image/bmp';
  if (p.endsWith('.mp4')) return 'video/mp4';
  if (p.endsWith('.mov')) return 'video/quicktime';
  if (p.endsWith('.m4v')) return 'video/mp4';
  if (p.endsWith('.webm')) return 'video/webm';
  if (p.endsWith('.avi')) return 'video/x-msvideo';
  if (p.endsWith('.mpeg') || p.endsWith('.mpg')) return 'video/mpeg';
  if (p.endsWith('.wmv')) return 'video/x-ms-wmv';
  if (p.endsWith('.flv')) return 'video/x-flv';
  if (p.endsWith('.mkv')) return 'video/x-matroska';
  if (p.endsWith('.ts')) return 'video/mp2t';
  if (p.endsWith('.ogg')) return 'video/ogg';
  return 'application/octet-stream';
}

/// Извлекает текст и файлы из набора [DataReader] — общая логика для
/// clipboard‑вставки и drag&drop. iOS/Android клипборд и drop session
/// одинаково отдают payload через `DataReader` (super_clipboard); единая
/// функция гарантирует одинаковую обработку (sticker‑first сортировка
/// форматов, file:// URI, temp‑файлы из bytes).
Future<ComposerClipboardPastePayload> readComposerPayloadFromDataReaders(
  Iterable<DataReader> readers,
) async {
  final files = <XFile>[];
  final addedPaths = <String>{};
  String? pastedText;
  var tempFileSeq = 0;

  for (final item in readers) {
    var mediaAddedFromItem = false;

    // Сначала пробуем получить текст: если в источнике просто текст/URL,
    // iOS часто кладёт ещё `plainTextFile`, который мы не должны превращать
    // во "вложение clipboard_...".
    if ((pastedText ?? '').trim().isEmpty) {
      try {
        final text = await item.readClipboardValue(Formats.plainText);
        if (text != null && text.trim().isNotEmpty) {
          pastedText = text;
        }
      } catch (_) {}
    }

    try {
      final fileUri = await item.readClipboardValue(Formats.fileUri);
      if (fileUri != null && fileUri.scheme == 'file') {
        final path = fileUri.toFilePath();
        if (path.trim().isNotEmpty) {
          final f = File(path);
          if (await f.exists() && addedPaths.add(path)) {
            final name = fileUri.pathSegments.isEmpty
                ? 'clipboard_file'
                : fileUri.pathSegments.last;
            files.add(
              XFile(path, name: name, mimeType: guessMimeByPath(path)),
            );
            mediaAddedFromItem = true;
          }
        }
      }
    } catch (_) {}

    if (!mediaAddedFromItem) {
      final fileFormats = _sortFormatsStickerFirst(
        item
            .getFormats(Formats.standardFormats)
            .whereType<FileFormat>()
            .toList(),
      );
      for (final selectedFormat in fileFormats) {
        // Никогда не превращаем "text-as-file" в вложение.
        if (selectedFormat == Formats.plainTextFile) {
          continue;
        }
        try {
          final bytes = await item.readClipboardFileBytes(selectedFormat);
          if (bytes != null && bytes.isNotEmpty) {
            final temp = await writeClipboardTempFile(
              bytes: bytes,
              format: selectedFormat,
              sequence: tempFileSeq,
            );
            tempFileSeq += 1;
            if (temp != null && addedPaths.add(temp.path)) {
              files.add(temp);
              mediaAddedFromItem = true;
              break;
            }
          }
        } catch (_) {}
      }
    }
  }

  return ComposerClipboardPastePayload(text: pastedText, files: files);
}

/// Читает расширенный и простой буфер (паритет `ChatScreen._readClipboardPayload`).
Future<ComposerClipboardPastePayload> readComposerClipboardPayload() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    final fallback = await Clipboard.getData(Clipboard.kTextPlain);
    final text = fallback?.text ?? '';
    return ComposerClipboardPastePayload(
      text: text.trim().isEmpty ? null : text,
      files: const <XFile>[],
    );
  }

  final reader = await clipboard.read();
  final payload = await readComposerPayloadFromDataReaders(reader.items);

  if ((payload.text ?? '').trim().isNotEmpty) {
    return payload;
  }
  final fallback = await Clipboard.getData(Clipboard.kTextPlain);
  final text = fallback?.text ?? '';
  if (text.trim().isEmpty) return payload;
  return ComposerClipboardPastePayload(text: text, files: payload.files);
}
