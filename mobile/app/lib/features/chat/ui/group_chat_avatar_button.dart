import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Круглый выбор фото группы (JPEG для загрузки в Storage), стиль как у остальных полей экрана.
class GroupChatAvatarButton extends StatefulWidget {
  const GroupChatAvatarButton({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<Uint8List?> onChanged;

  @override
  State<GroupChatAvatarButton> createState() => _GroupChatAvatarButtonState();
}

class _GroupChatAvatarButtonState extends State<GroupChatAvatarButton> {
  Uint8List? _jpeg;
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (file == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          IOSUiSettings(title: 'Фото группы'),
          AndroidUiSettings(toolbarTitle: 'Фото группы'),
        ],
      );
      if (cropped == null) return;

      final bytes = await cropped.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

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
      final jpeg = Uint8List.fromList(img.encodeJpg(resized, quality: 88));
      setState(() => _jpeg = jpeg);
      widget.onChanged(jpeg);
    } finally {
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

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (!widget.enabled || _busy) ? null : _pick,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
                ),
              ),
              child: _busy
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _jpeg != null
                  ? ClipOval(
                      child: Image.memory(
                        _jpeg!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.add_a_photo_rounded,
                      size: 36,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: (!widget.enabled || _busy) ? null : _pick,
              child: Text(_jpeg == null ? 'Добавить фото' : 'Сменить'),
            ),
            if (_jpeg != null)
              TextButton(
                onPressed: (!widget.enabled || _busy) ? null : _clear,
                child: Text(
                  'Убрать',
                  style: TextStyle(color: scheme.error),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
