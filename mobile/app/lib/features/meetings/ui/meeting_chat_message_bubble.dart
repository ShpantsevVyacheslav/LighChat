import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../data/meeting_chat_message.dart';

/// Пузырёк сообщения чата митинга: текст, сетка изображений, файлы, long-press.
class MeetingChatMessageBubble extends StatelessWidget {
  const MeetingChatMessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    this.onEditText,
    this.onDelete,
  });

  final MeetingChatMessage message;
  final bool isSelf;
  final void Function(MeetingChatMessage msg)? onEditText;
  final VoidCallback? onDelete;

  String _timeLabel() {
    final d = message.createdAt?.toLocal();
    if (d == null) return '';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLongPress(BuildContext context) async {
    if (message.isDeleted) return;
    final l10n = AppLocalizations.of(context)!;
    final actions = <Widget>[];
    if (message.text != null && message.text!.isNotEmpty) {
      actions.add(
        ListTile(
          leading: const Icon(Icons.copy_rounded),
          title: Text(l10n.meeting_chat_copy),
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: message.text!));
          },
        ),
      );
    }
    if (isSelf && onEditText != null && message.text != null && message.text!.isNotEmpty) {
      actions.add(
        ListTile(
          leading: const Icon(Icons.edit_rounded),
          title: Text(l10n.meeting_chat_edit),
          onTap: () {
            Navigator.pop(context);
            onEditText!(message);
          },
        ),
      );
    }
    if (isSelf && onDelete != null) {
      actions.add(
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          title: Text(l10n.meeting_chat_delete, style: const TextStyle(color: Colors.redAccent)),
          onTap: () {
            Navigator.pop(context);
            onDelete!();
          },
        ),
      );
    }
    if (actions.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (message.isDeleted) {
      return Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Text(
                l10n.meeting_chat_deleted,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final images = message.attachments.where((a) => a.isImage).toList();
    final files = message.attachments.where((a) => !a.isImage).toList();
    final bg = isSelf ? const Color(0xFF2563EB) : const Color(0xFF1F2937);
    final fg = Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isSelf ? 14 : 4),
      bottomRight: Radius.circular(isSelf ? 4 : 14),
    );
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: GestureDetector(
          onLongPress: () => _onLongPress(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelf)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (images.isNotEmpty)
                    GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: images.length > 1 ? 2 : 1,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: images.length,
                        itemBuilder: (ctx, i) {
                          final a = images[i];
                          return GestureDetector(
                            onTap: () => _showFullImage(context, a.url),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CachedNetworkImage(
                                imageUrl: a.url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.black38,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  if (files.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      child: Column(
                        children: files
                            .map(
                              (a) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.insert_drive_file_rounded,
                                  color: fg.withValues(alpha: 0.9),
                                ),
                                title: Text(
                                  a.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: fg, fontSize: 13),
                                ),
                                onTap: () => _openUrl(a.url),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (message.text != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Text(
                        message.text!,
                        style: TextStyle(color: fg, fontSize: 14, height: 1.25),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeLabel(),
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.55),
                            fontSize: 10,
                          ),
                        ),
                        if (message.updatedAt != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            l10n.meeting_chat_edited_mark,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.55),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
