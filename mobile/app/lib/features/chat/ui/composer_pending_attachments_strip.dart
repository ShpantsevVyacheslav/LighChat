import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../data/composer_attachment_limits.dart';
import 'video_first_frame.dart';

bool _looksLikeImage(String path, String? mime) {
  final m = (mime ?? '').toLowerCase();
  if (m.startsWith('image/')) return true;
  final p = path.toLowerCase();
  return p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.png') ||
      p.endsWith('.gif') ||
      p.endsWith('.webp') ||
      p.endsWith('.heic');
}

bool _looksLikeVideo(String path, String? mime) {
  final m = (mime ?? '').toLowerCase();
  if (m.startsWith('video/')) return true;
  final p = path.toLowerCase();
  return p.endsWith('.mp4') ||
      p.endsWith('.mov') ||
      p.endsWith('.webm') ||
      p.endsWith('.m4v') ||
      p.endsWith('.3gp');
}

/// Превью выбранных вложений над строкой ввода (как веб).
class ComposerPendingAttachmentsStrip extends StatelessWidget {
  const ComposerPendingAttachmentsStrip({
    super.key,
    required this.files,
    required this.onRemoveAt,
    this.onEditAt,
    this.limitsState,
  });

  final List<XFile> files;
  final void Function(int index) onRemoveAt;
  final void Function(int index)? onEditAt;

  /// Снимок состояния лимитов из родителя. Если `isOverLimit == true` —
  /// под полосой превью рисуем inline-warning, чтобы пользователь увидел
  /// причину блокировки кнопки send (см. ChatComposer.sendBlockedByLimits).
  final ComposerLimitsState? limitsState;

  static const double thumb = 56;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    final overLimit = limitsState?.isOverLimit ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: thumb + 8,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final f = files[i];
                final isImage = _looksLikeImage(f.path, f.mimeType);
                final isVideo = !isImage && _looksLikeVideo(f.path, f.mimeType);
                final canEdit = (isImage || isVideo) && onEditAt != null;
                return _Thumb(
                  file: f,
                  showAsImage: isImage,
                  isVideo: isVideo,
                  onRemove: () => onRemoveAt(i),
                  onEdit: canEdit ? () => onEditAt!(i) : null,
                );
              },
            ),
          ),
          if (overLimit) _LimitWarningRow(state: limitsState!),
        ],
      ),
    );
  }
}

class _LimitWarningRow extends StatelessWidget {
  const _LimitWarningRow({required this.state});

  final ComposerLimitsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final String message;
    if (state.isOverFiles) {
      message = l10n.composer_limit_too_many_files(
        state.currentCount,
        state.limits.maxFiles,
        state.excessFiles,
      );
    } else {
      final cap = state.limits.maxTotalBytes ?? 0;
      final used = state.currentBytes ?? 0;
      message = l10n.composer_limit_total_size_exceeded(
        formatComposerBytesMb(used),
        formatComposerBytesMb(cap),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: scheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.file,
    required this.showAsImage,
    required this.isVideo,
    required this.onRemove,
    this.onEdit,
  });

  final XFile file;
  final bool showAsImage;
  final bool isVideo;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: ComposerPendingAttachmentsStrip.thumb,
            height: ComposerPendingAttachmentsStrip.thumb,
            child: showAsImage
                ? Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _fallback(scheme),
                  )
                : (isVideo
                    ? VideoFirstFrame(
                        file: File(file.path),
                        fit: BoxFit.cover,
                        placeholder: _fallback(scheme),
                      )
                    : _fallback(scheme)),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.65),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
        if (onEdit != null)
          Positioned(
            bottom: -4,
            right: -4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.insert_drive_file_rounded,
          color: scheme.onSurface.withValues(alpha: 0.7),
          size: 28,
        ),
      ),
    );
  }
}
