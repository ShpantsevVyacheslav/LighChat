import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/link_preview_metadata.dart';

final LinkPreviewMetadataCache _linkPreviewCache = LinkPreviewMetadataCache();

class MessageLinkPreviewCard extends StatelessWidget {
  const MessageLinkPreviewCard({
    super.key,
    required this.url,
    required this.isMine,
    this.maxWidth = 320,
  });

  final String url;
  final bool isMine;
  final double maxWidth;

  Future<void> _open() async {
    final u = Uri.tryParse(url.trim());
    if (u == null || !(u.isScheme('http') || u.isScheme('https'))) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final border = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.onSurface.withValues(alpha: dark ? 0.14 : 0.10);
    final bg = isMine
        ? Colors.white.withValues(alpha: 0.10)
        : (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.06 : 0.88,
          );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FutureBuilder<LinkPreviewMetadata?>(
        future: _linkPreviewCache.get(url),
        builder: (context, snap) {
          final data = snap.data;
          if (snap.connectionState != ConnectionState.done) {
            return _skeleton(border: border, bg: bg);
          }
          if (data == null) {
            return const SizedBox.shrink();
          }
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => unawaited(_open()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: bg,
                  border: Border.all(color: border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.imageUrl != null)
                      SizedBox(
                        height: 140,
                        child: Image.network(
                          data.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.siteName != null) ...[
                            Text(
                              data.siteName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: (isMine ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: (isMine ? Colors.white : scheme.onSurface)
                                  .withValues(alpha: 0.92),
                              height: 1.15,
                            ),
                          ),
                          if (data.description != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              data.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (isMine ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: 0.68),
                                height: 1.2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (isMine ? Colors.white : scheme.primary)
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _skeleton({required Color border, required Color bg}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

