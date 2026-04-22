import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'avatar_crop_screen.dart';

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
    this.compact = false,
    this.value,
    this.initialImageUrl,
  });

  final bool enabled;
  final bool compact;
  final AvatarResult? value;
  final String? initialImageUrl;
  final ValueChanged<AvatarResult?> onChanged;

  @override
  State<AvatarPickerCropper> createState() => _AvatarPickerCropperState();
}

class _AvatarPickerCropperState extends State<AvatarPickerCropper> {
  AvatarResult? _value;
  String? _initialImageUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _initialImageUrl = widget.initialImageUrl?.trim();
  }

  @override
  void didUpdateWidget(covariant AvatarPickerCropper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
    if (widget.initialImageUrl != oldWidget.initialImageUrl &&
        (_value == null || widget.value == null)) {
      _initialImageUrl = widget.initialImageUrl?.trim();
    }
  }

  Widget _avatarPreview(ThemeData theme, {double? iconSize}) {
    final scheme = theme.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    if (_value != null) {
      return Image.memory(_value!.previewBytes, fit: BoxFit.cover);
    }
    final url = _initialImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person_outline_rounded,
          size: iconSize ?? 56,
          color: (dark ? Colors.white : scheme.onSurface).withValues(
            alpha: 0.6,
          ),
        ),
      );
    }
    return Icon(
      Icons.person_outline_rounded,
      size: iconSize ?? 56,
      color: (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.6),
    );
  }

  Future<void> _pick() async {
    final source = await _showSourcePicker(context);
    if (source == null || !mounted) return;
    await _pickFromSource(source);
  }

  Future<ImageSource?> _showSourcePicker(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF111322), Color(0xFF050611)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                (dark ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: 0.72),
                          ),
                          child: const Text('Отмена'),
                        ),
                        const Text(
                          'Выбрать аватар',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 60), // баланс для кнопки Отмена
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1.2,
                        ),
                        color: dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                      child: ClipOval(
                        child: _avatarPreview(Theme.of(context), iconSize: 56),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pop(ImageSource.camera),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Камера'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pop(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.26),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Галерея'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_value != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          if (mounted) {
                            setState(() => _value = null);
                            widget.onChanged(null);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                        ),
                        child: const Text('Удалить фото'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null || !mounted) return;

      // Открываем экран кропа.
      final result = await AvatarCropScreen.push(
        context,
        imageFile: File(file.path),
      );
      if (result == null || !mounted) return;

      setState(() => _value = result);
      widget.onChanged(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    if (widget.compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (!widget.enabled || _busy) ? null : _pick,
          borderRadius: BorderRadius.circular(70),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Без «белого квадрата» в светлой теме: лёгкая круглая подложка.
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              border: Border.all(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.18,
                ),
                width: 1.1,
              ),
            ),
            child: _value == null
                ? ClipOval(
                    child: _avatarPreview(Theme.of(context), iconSize: 64),
                  )
                : ClipOval(child: _avatarPreview(Theme.of(context))),
          ),
        ),
      );
    }
    return Row(
      children: [
        ClipOval(
          child: Container(
            width: 56,
            height: 56,
            color: scheme.surfaceContainerHighest,
            child: _avatarPreview(Theme.of(context), iconSize: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: (!widget.enabled || _busy) ? null : _pick,
            child: Text(
              _busy
                  ? 'Загрузка…'
                  : (_value == null ? 'Выбрать аватар' : 'Сменить аватар'),
            ),
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
