import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Перед отправкой ужимает «стикер» (вырезанный subject из iOS Photos)
/// до приемлемого Telegram-style размера. Apple Lift Subject в iOS 17+
/// возвращает PNG в исходном разрешении камеры (3024×3292, 4032×3024 и
/// больше) с альфой по силуэту — такой файл может весить 7–15 MiB и
/// долго грузится. Стикер для пользователя визуально не теряет ничего
/// от ресайза до 1024px по большей стороне.
///
/// Контракт:
///   * Если декод не удался — возвращаем `file` как есть. Send pipeline
///     попробует залить оригинал.
///   * Если максимальная сторона ≤ [maxSide] — возвращаем `file` без
///     re-encode (байтовая идентичность).
///   * Иначе — copyResize → encodePng (с альфой) → запись во временный
///     файл `chat_sticker_<ts>.png`. Возвращаем новый XFile.
///
/// Тяжёлый decode/encode выполняется в isolate через [compute] — на
/// 13 MiB PNG это занимает ~300–800 ms и без isolate подморозило бы UI
/// на момент drop‑drop -> send.

const int kStickerSendMaxSidePx = 1024;

/// Аргумент, передаваемый в isolate. Records копируются между
/// isolate'ами через standard message protocol (top-level records OK).
class _ResizeStickerInput {
  const _ResizeStickerInput({required this.bytes, required this.maxSide});
  final Uint8List bytes;
  final int maxSide;
}

class _ResizeStickerResult {
  const _ResizeStickerResult({required this.bytes, required this.changed});
  final Uint8List bytes;
  final bool changed;
}

/// Top-level — обязательно для `compute()` (не может быть closure).
_ResizeStickerResult? _resizeStickerPngBytes(_ResizeStickerInput input) {
  final decoded = img.decodeImage(input.bytes);
  if (decoded == null) return null;
  final w = decoded.width;
  final h = decoded.height;
  final maxSide = w > h ? w : h;
  if (maxSide <= input.maxSide) {
    return _ResizeStickerResult(bytes: input.bytes, changed: false);
  }
  final scale = input.maxSide / maxSide;
  final nw = (w * scale).round();
  final nh = (h * scale).round();
  // average — лучшее качество для downscale, особенно по краям альфы
  // (linear смазал бы силуэт).
  final resized = img.copyResize(
    decoded,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.average,
  );
  // Сохраняем альфа-канал — encodePng это делает по умолчанию.
  return _ResizeStickerResult(bytes: img.encodePng(resized), changed: true);
}

Future<XFile> downscaleStickerForSend(
  XFile file, {
  int maxSide = kStickerSendMaxSidePx,
}) async {
  try {
    final path = file.path;
    if (path.isEmpty) return file;
    final raw = await File(path).readAsBytes();
    final originalBytes = raw.length;
    final r = await compute(
      _resizeStickerPngBytes,
      _ResizeStickerInput(bytes: raw, maxSide: maxSide),
    );
    if (r == null) {
      debugPrint('[sticker-downscale] decode failed → using original');
      return file;
    }
    if (!r.changed) {
      debugPrint(
        '[sticker-downscale] no resize needed (≤ ${maxSide}px) → using original ($originalBytes B)',
      );
      return file;
    }
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final outName = 'chat_sticker_$stamp.png';
    final out = File('${dir.path}/$outName');
    await out.writeAsBytes(r.bytes, flush: true);
    debugPrint(
      '[sticker-downscale] resized: $originalBytes B → ${r.bytes.length} B '
      '(maxSide=${maxSide}px) → ${out.path}',
    );
    return XFile(out.path, name: outName, mimeType: 'image/png');
  } catch (e, st) {
    debugPrint('[sticker-downscale] failed: $e\n$st → using original');
    return file;
  }
}
