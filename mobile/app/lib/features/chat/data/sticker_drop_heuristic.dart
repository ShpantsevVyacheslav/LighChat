import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Эвристика «это стикер, а не обычное фото» для drag&drop из других
/// приложений (особенно iOS Photos «Lift Subject» / Telegram-style паки).
///
/// Стикер — PNG/WebP с прозрачным фоном, маленькой стороной (≤ 1024px) и
/// разумным весом (≤ 4 MiB). Чтобы отделить стикер от обычного PNG-фото
/// с альфа-каналом (скриншоты UI и т.п.), дополнительно проверяем четыре
/// угла: у настоящего «вырезанного subject» они прозрачны, у скриншота —
/// заполнены.
///
/// Контракт: чисто синхронные проверки + один decode через `package:image`.
/// Любая ошибка (битый файл, неподдерживаемый формат) — `false`, чтобы
/// дроп тихо ушёл по обычному pending‑attachment пути.
///
/// Все шаги логируются через `debugPrint('[sticker-heuristic] …')` —
/// пригодится для диагностики «почему именно мой стикер не распознался».

// Лимиты подобраны по реальным дропам iOS Lift Subject: с iOS 17 Apple
// возвращает PNG в **оригинальном разрешении исходного фото** (3024×3292
// и больше для iPhone-камеры) с альфой по силуэту. Жёстко ограничивать
// сторону 1024px нельзя — иначе lift subject из обычного фото никогда
// не пройдёт. Оставляем мягкий потолок 4096px (защита от мегаобоев) и
// 16 MiB по размеру файла. Главные фильтры false-positive — PNG/WebP
// magic + alpha-channel + 4 прозрачных угла (см. _allCornersTransparent
// ниже): у скриншота UI углы непрозрачны, у вырезанного subject —
// всегда прозрачны.
const int kStickerMaxSidePx = 4096;
const int kStickerMaxBytes = 16 << 20; // 16 MiB
const int _kCornerAlphaCutoff = 16;
const int _kCornerProbeInset = 2;

void _log(String msg) {
  debugPrint('[sticker-heuristic] $msg');
}

String _magicTag(Uint8List b) {
  if (b.length < 12) return '<too-short:${b.length}>';
  String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${hex(0)} ${hex(1)} ${hex(2)} ${hex(3)} … ${hex(8)} ${hex(9)} ${hex(10)} ${hex(11)}';
}

bool _hasPngOrWebpMagic(Uint8List bytes) {
  if (bytes.length < 12) return false;
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  // WebP: 'RIFF' …… 'WEBP'
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return true;
  }
  return false;
}

/// Возвращает `true`, если все четыре угла изображения прозрачны
/// (alpha < [_kCornerAlphaCutoff]). Это сильно снижает false‑positive на
/// PNG‑скриншотах, где альфа = 255 во всех точках.
bool _allCornersTransparent(img.Image image) {
  final w = image.width;
  final h = image.height;
  if (w <= _kCornerProbeInset * 2 || h <= _kCornerProbeInset * 2) {
    _log('rejected: image too small for corner probe (${w}x$h)');
    return false;
  }
  final pts = <List<int>>[
    [_kCornerProbeInset, _kCornerProbeInset],
    [w - 1 - _kCornerProbeInset, _kCornerProbeInset],
    [_kCornerProbeInset, h - 1 - _kCornerProbeInset],
    [w - 1 - _kCornerProbeInset, h - 1 - _kCornerProbeInset],
  ];
  final alphas = <num>[];
  for (final p in pts) {
    final px = image.getPixel(p[0], p[1]);
    alphas.add(px.a);
  }
  final maxAlpha = alphas.reduce((a, b) => a > b ? a : b);
  if (maxAlpha > _kCornerAlphaCutoff) {
    _log(
      'rejected: corner not transparent — alphas=$alphas '
      '(cutoff=$_kCornerAlphaCutoff)',
    );
    return false;
  }
  _log('corners ok: alphas=$alphas');
  return true;
}

/// Проверяет, выглядит ли файл как стикер (PNG/WebP ≤ 512px, ≤ 1 MiB,
/// прозрачные углы). Возвращает `false` если файл нечитаем или не подходит
/// под эвристику; в обоих случаях каждое отклонение пишется в лог.
Future<bool> isLikelyStickerXFile(XFile file) async {
  final tag = file.name.isNotEmpty ? file.name : file.path;
  try {
    final path = file.path;
    if (path.isEmpty) {
      _log('"$tag" rejected: empty path');
      return false;
    }
    final f = File(path);
    if (!await f.exists()) {
      _log('"$tag" rejected: file not exists at $path');
      return false;
    }
    final size = await f.length();
    if (size <= 0) {
      _log('"$tag" rejected: empty file');
      return false;
    }
    if (size > kStickerMaxBytes) {
      _log(
        '"$tag" rejected: too large — $size bytes '
        '(limit=$kStickerMaxBytes)',
      );
      return false;
    }

    final bytes = await f.readAsBytes();
    if (!_hasPngOrWebpMagic(bytes)) {
      _log(
        '"$tag" rejected: not PNG/WebP — magic=${_magicTag(bytes)} '
        'mime=${file.mimeType ?? 'null'}',
      );
      return false;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _log('"$tag" rejected: image decoder returned null');
      return false;
    }
    _log(
      '"$tag" decoded: ${decoded.width}x${decoded.height} '
      'channels=${decoded.numChannels} size=$size',
    );
    if (decoded.width > kStickerMaxSidePx ||
        decoded.height > kStickerMaxSidePx) {
      _log(
        '"$tag" rejected: dimensions too large — '
        '${decoded.width}x${decoded.height} (limit=${kStickerMaxSidePx}px)',
      );
      return false;
    }
    if (decoded.numChannels < 4) {
      _log(
        '"$tag" rejected: no alpha channel '
        '(numChannels=${decoded.numChannels})',
      );
      return false;
    }
    final ok = _allCornersTransparent(decoded);
    _log('"$tag" verdict: ${ok ? 'STICKER' : 'not sticker'}');
    return ok;
  } catch (e, st) {
    _log('"$tag" rejected: exception $e\n$st');
    return false;
  }
}
