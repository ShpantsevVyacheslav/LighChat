import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Эвристика «это стикер, а не обычное фото» для drag&drop из других
/// приложений (особенно iOS Photos «Lift Subject» / Telegram-style паки).
///
/// Стикер — PNG/WebP с прозрачным фоном, маленькой стороной (≤ 512px) и
/// небольшим весом (≤ 1 MB). Чтобы отделить стикер от обычного PNG-фото
/// с альфа-каналом (скриншоты UI и т.п.), дополнительно проверяем четыре
/// угла: у настоящего «вырезанного subject» они прозрачны, у скриншота —
/// заполнены.
///
/// Контракт: чисто синхронные проверки + один decode через `package:image`.
/// Любая ошибка (битый файл, неподдерживаемый формат) — `false`, чтобы
/// дроп тихо ушёл по обычному pending‑attachment пути.

const int kStickerMaxSidePx = 512;
const int kStickerMaxBytes = 1 << 20; // 1 MiB
const int _kCornerAlphaCutoff = 16;
const int _kCornerProbeInset = 2;

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
  if (w <= _kCornerProbeInset * 2 || h <= _kCornerProbeInset * 2) return false;
  final pts = <List<int>>[
    [_kCornerProbeInset, _kCornerProbeInset],
    [w - 1 - _kCornerProbeInset, _kCornerProbeInset],
    [_kCornerProbeInset, h - 1 - _kCornerProbeInset],
    [w - 1 - _kCornerProbeInset, h - 1 - _kCornerProbeInset],
  ];
  for (final p in pts) {
    final px = image.getPixel(p[0], p[1]);
    if (px.a > _kCornerAlphaCutoff) return false;
  }
  return true;
}

/// Проверяет, выглядит ли файл как стикер (PNG/WebP ≤ 512px, ≤ 1 MiB,
/// прозрачные углы). Возвращает `null` если файл нечитаем.
///
/// Тяжёлый шаг — `img.decodeImage`. Для drop из iOS Photos одиночного
/// PNG это десятки миллисекунд; пакетный drop из 5+ изображений лучше
/// прогонять через `compute()`, но для текущего сценария (один файл за
/// раз) этого не нужно.
Future<bool> isLikelyStickerXFile(XFile file) async {
  try {
    final path = file.path;
    if (path.isEmpty) return false;
    final f = File(path);
    if (!await f.exists()) return false;
    final size = await f.length();
    if (size <= 0 || size > kStickerMaxBytes) return false;

    final bytes = await f.readAsBytes();
    if (!_hasPngOrWebpMagic(bytes)) return false;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return false;
    if (decoded.width > kStickerMaxSidePx ||
        decoded.height > kStickerMaxSidePx) {
      return false;
    }
    if (decoded.numChannels < 4) return false; // нет alpha‑канала
    return _allCornersTransparent(decoded);
  } catch (e, st) {
    // best‑effort: при любой ошибке падаем в обычный pending pipeline.
    if (kDebugMode) {
      debugPrint('isLikelyStickerXFile failed: $e\n$st');
    }
    return false;
  }
}
