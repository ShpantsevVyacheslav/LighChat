import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'message_video_attachment.dart';

bool _isVideoAttachment(ChatAttachment a) {
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('video/')) return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v') ||
      path.endsWith('.3gp');
}

bool _isImageAttachment(ChatAttachment a) {
  if (_isVideoAttachment(a)) return false;
  final t = (a.type ?? '').toLowerCase();
  if (t.startsWith('image/')) return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic');
}

class MessageAttachments extends StatelessWidget {
  const MessageAttachments({super.key, required this.attachments});

  final List<ChatAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where(_isImageAttachment).toList(growable: false);
    final videos = attachments.where(_isVideoAttachment).toList(growable: false);
    final files = attachments.where((a) => !_isImageAttachment(a) && !_isVideoAttachment(a)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty) _ImageGrid(images: images),
        if (videos.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 8),
          ...videos.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MessageVideoAttachment(attachment: v),
              )),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...files.map((f) => _FileRow(att: f)),
        ],
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});

  final List<ChatAttachment> images;

  @override
  Widget build(BuildContext context) {
    final count = images.length.clamp(1, 4);
    final cols = count == 1 ? 1 : 2;
    final radius = BorderRadius.circular(18);

    return ClipRRect(
      borderRadius: radius,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: images.length > 4 ? 4 : images.length,
        itemBuilder: (context, i) {
          final a = images[i];
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                a.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return DecoratedBox(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        size: 28,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return DecoratedBox(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22)),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress.expectedTotalBytes == null
                              ? null
                              : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (i == 3 && images.length > 4)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Text(
                    '+${images.length - 4}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.att});

  final ChatAttachment att;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: scheme.brightness == Brightness.dark ? 0.06 : 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_rounded, color: scheme.onSurface.withValues(alpha: 0.70)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                att.name.isNotEmpty ? att.name : att.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

