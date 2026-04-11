import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class AvatarResult {
  AvatarResult({
    required this.fullJpeg,
    required this.thumbPng,
    required this.previewBytes,
  });

  final Uint8List fullJpeg;
  final Uint8List thumbPng;
  final Uint8List previewBytes; // use thumb for preview
}

class AvatarPickerCropper extends StatefulWidget {
  const AvatarPickerCropper({
    super.key,
    required this.onChanged,
    required this.enabled,
  });

  final bool enabled;
  final ValueChanged<AvatarResult?> onChanged;

  @override
  State<AvatarPickerCropper> createState() => _AvatarPickerCropperState();
}

class _AvatarPickerCropperState extends State<AvatarPickerCropper> {
  AvatarResult? _value;
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
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          IOSUiSettings(title: 'Аватар'),
          AndroidUiSettings(toolbarTitle: 'Аватар'),
        ],
      );
      if (cropped == null) return;

      final bytes = await cropped.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      // Ensure square.
      final size = decoded.width < decoded.height ? decoded.width : decoded.height;
      final square = img.copyCrop(
        decoded,
        x: (decoded.width - size) ~/ 2,
        y: (decoded.height - size) ~/ 2,
        width: size,
        height: size,
      );

      // Full: 1024 jpeg.
      final full = img.copyResize(square, width: 1024, height: 1024, interpolation: img.Interpolation.average);
      final fullJpeg = Uint8List.fromList(img.encodeJpg(full, quality: 92));

      // Thumb: 512 circle png with alpha.
      final thumbBase = img.copyResize(square, width: 512, height: 512, interpolation: img.Interpolation.average);
      final thumbCircle = _circleMask(thumbBase);
      final thumbPng = Uint8List.fromList(img.encodePng(thumbCircle));

      final result = AvatarResult(fullJpeg: fullJpeg, thumbPng: thumbPng, previewBytes: thumbPng);
      setState(() => _value = result);
      widget.onChanged(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  img.Image _circleMask(img.Image square) {
    final out = img.Image(width: square.width, height: square.height, numChannels: 4);
    final cx = (square.width - 1) / 2.0;
    final cy = (square.height - 1) / 2.0;
    final r = square.width / 2.0;

    for (var y = 0; y < square.height; y++) {
      for (var x = 0; x < square.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= (r * r);
        if (!inside) {
          out.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          final p = square.getPixel(x, y);
          out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        ClipOval(
          child: Container(
            width: 56,
            height: 56,
            color: scheme.surfaceContainerHighest,
            child: _value == null ? const Icon(Icons.person) : Image.memory(_value!.previewBytes, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: (!widget.enabled || _busy) ? null : _pick,
            child: Text(_busy ? 'Загрузка…' : (_value == null ? 'Выбрать аватар' : 'Сменить аватар')),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: (!widget.enabled || _busy || _value == null)
              ? null
              : () {
                  setState(() => _value = null);
                  widget.onChanged(null);
                },
          icon: const Icon(Icons.close),
          tooltip: 'Убрать',
        ),
      ],
    );
  }
}

