import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';

class ChatFolderBar extends StatelessWidget {
  const ChatFolderBar({
    super.key,
    required this.folders,
    required this.activeFolderId,
    required this.onSelectFolder,
    required this.unreadByFolderId,
    this.onNewPressed,
    this.onLongPressFolder,
  });

  final List<ChatFolder> folders;
  final String activeFolderId;
  final void Function(String folderId) onSelectFolder;
  final Map<String, int> unreadByFolderId;
  final VoidCallback? onNewPressed;
  final void Function(ChatFolder folder)? onLongPressFolder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + (onNewPressed != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (onNewPressed != null && i == folders.length) {
            return _NewChip(onTap: onNewPressed!);
          }
          final f = folders[i];
          final active = f.id == activeFolderId;
          final unread = unreadByFolderId[f.id] ?? 0;
          return _FolderChip(
            folder: f,
            folderId: f.id,
            label: f.name,
            active: active,
            unread: unread,
            onTap: () => onSelectFolder(f.id),
            onLongPress: onLongPressFolder == null
                ? null
                : () => onLongPressFolder!(f),
          );
        },
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.folder,
    required this.folderId,
    required this.label,
    required this.active,
    required this.unread,
    required this.onTap,
    this.onLongPress,
  });

  final ChatFolder folder;
  final String folderId;
  final String label;
  final bool active;
  final int unread;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final shownLabel = folderId == 'favorites' ? AppLocalizations.of(context)!.chat_folder_favorites : label;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? const Color(0xFF2A79FF)
              : Colors.white.withValues(alpha: dark ? 0.08 : 0.62),
          border: Border.all(
            color: active
                ? const Color(0xFF3B8DFF)
                : (dark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shownLabel,
              style: TextStyle(
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : scheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFF2A79FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: dark ? 0.06 : 0.62),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: scheme.onSurface),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.chat_folder_new,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
