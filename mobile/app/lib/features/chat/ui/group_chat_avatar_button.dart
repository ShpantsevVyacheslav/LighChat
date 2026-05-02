import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Круглый выбор фото группы (JPEG для загрузки в Storage), стиль как у остальных полей экрана.
class GroupChatAvatarButton extends StatefulWidget {
  const GroupChatAvatarButton({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.diameter = 96,
    this.placeholderIcon = Icons.add_a_photo_rounded,
    this.showCaptionRow = true,
    this.existingPhotoUrl,
  });

  final bool enabled;
  final ValueChanged<Uint8List?> onChanged;

  /// Диаметр круга (например 112 на экране «Создать группу»).
  final double diameter;

  /// Иконка, если фото ещё не выбрано.
  final IconData placeholderIcon;

  /// Подписи «Добавить фото» / «Сменить» под кругом.
  final bool showCaptionRow;

  /// URL существующего фото группы (например на экране редактирования).
  final String? existingPhotoUrl;

  @override
  State<GroupChatAvatarButton> createState() => _GroupChatAvatarButtonState();
}

class _GroupChatAvatarButtonState extends State<GroupChatAvatarButton> {
  // Максимальная сторона исходника, который передаётся в native ImageCropper.
  // Тот же лимит, что в `chat_image_editor_screen.dart` — защищает iOS‑плагин
  // от OOM/SIGABRT на фотографиях из галереи (12+ МП).
  static const int _kCropperMaxSide = 3000;

  Uint8List? _jpeg;
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    String? scratchPath;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      // Downscale исходника в isolate до безопасного размера ДО вызова
      // нативного ImageCropper. Это основная защита от нативного краша на iOS.
      final srcBytes = await File(file.path).readAsBytes();
      final downscaledBytes = await compute<_AvatarDownscaleArgs, Uint8List>(
        _downscaleForCropperIsolate,
        _AvatarDownscaleArgs(bytes: srcBytes, maxSide: _kCropperMaxSide),
      );

      final tmpDir = await getTemporaryDirectory();
      scratchPath =
          '${tmpDir.path}/group_avatar_src_${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(scratchPath).writeAsBytes(downscaledBytes, flush: true);

      final cropped = await ImageCropper().cropImage(
        sourcePath: scratchPath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          IOSUiSettings(title: AppLocalizations.of(context)!.group_avatar_photo_title),
          AndroidUiSettings(toolbarTitle: AppLocalizations.of(context)!.group_avatar_photo_title),
        ],
      );
      if (cropped == null) return;

      final croppedBytes = await File(cropped.path).readAsBytes();
      final finalBytes = await compute<Uint8List, Uint8List>(
        _finalizeAvatarIsolate,
        croppedBytes,
      );

      if (!mounted) return;
      setState(() => _jpeg = finalBytes);
      widget.onChanged(finalBytes);
    } catch (e, st) {
      debugPrint('GroupChatAvatarButton._pick failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Не удалось обработать фото: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (scratchPath != null) {
        try {
          final f = File(scratchPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    setState(() => _jpeg = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    final d = widget.diameter;
    final iconSize = (d * 0.36).clamp(32.0, 48.0);

    final circle = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (!widget.enabled || _busy) ? null : _pick,
        onLongPress: (widget.enabled && !_busy && _jpeg != null && !widget.showCaptionRow)
            ? _clear
            : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: dark ? 0.09 : 0.22),
          ),
          child: _busy
              ? Center(
                  child: SizedBox(
                    width: d * 0.29,
                    height: d * 0.29,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _jpeg != null
              ? ClipOval(
                  child: Image.memory(
                    _jpeg!,
                    width: d,
                    height: d,
                    fit: BoxFit.cover,
                  ),
                )
              : (widget.existingPhotoUrl != null && widget.existingPhotoUrl!.trim().isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    widget.existingPhotoUrl!,
                    width: d,
                    height: d,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      widget.placeholderIcon,
                      size: iconSize,
                      color: scheme.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                )
              : Icon(
                  widget.placeholderIcon,
                  size: iconSize,
                  color: scheme.onSurface.withValues(alpha: 0.42),
                ),
        ),
      ),
    );

    if (!widget.showCaptionRow) {
      return Center(child: circle);
    }

    return Column(
      children: [
        Center(child: circle),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: (!widget.enabled || _busy) ? null : _pick,
              child: Text(_jpeg == null ? AppLocalizations.of(context)!.group_avatar_add_photo : AppLocalizations.of(context)!.group_avatar_change_short),
            ),
            if (_jpeg != null)
              TextButton(
                onPressed: (!widget.enabled || _busy) ? null : _clear,
                child: Text(
                  AppLocalizations.of(context)!.group_avatar_remove,
                  style: TextStyle(color: scheme.error),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// --- Isolate helpers (top-level, required by `compute`). ---

class _AvatarDownscaleArgs {
  const _AvatarDownscaleArgs({required this.bytes, required this.maxSide});

  final Uint8List bytes;
  final int maxSide;
}

/// Декодирует [args.bytes] и, если большая сторона превышает [args.maxSide],
/// уменьшает картинку пропорционально и перекодирует в JPEG. Возвращает
/// исходные байты, если декодирование не удалось или уменьшение не требуется.
Uint8List _downscaleForCropperIsolate(_AvatarDownscaleArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;
  final largest = decoded.width > decoded.height ? decoded.width : decoded.height;
  if (largest <= args.maxSide) return args.bytes;
  final scale = args.maxSide / largest;
  final newW = (decoded.width * scale).round().clamp(1, args.maxSide);
  final newH = (decoded.height * scale).round().clamp(1, args.maxSide);
  final resized = img.copyResize(
    decoded,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 86));
}

/// Пост‑обработка после native кропа: центральный квадратный кроп (на случай,
/// если плагин отдал неидеально‑квадратное фото), ресайз до 1024×1024 и
/// JPEG‑кодирование (quality 88). Выполняется в isolate, чтобы не блокировать
/// UI и не создавать memory‑pressure на main.
Uint8List _finalizeAvatarIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final size = decoded.width < decoded.height ? decoded.width : decoded.height;
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - size) ~/ 2,
    y: (decoded.height - size) ~/ 2,
    width: size,
    height: size,
  );
  final resized = img.copyResize(
    square,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
}
