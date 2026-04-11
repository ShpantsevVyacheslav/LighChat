import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

class ChatFolderBar extends StatelessWidget {
  const ChatFolderBar({
    super.key,
    required this.folders,
    required this.activeFolderId,
    required this.onSelectFolder,
    required this.unreadByFolderId,
    this.onNewPressed,
  });

  final List<ChatFolder> folders;
  final String activeFolderId;
  final void Function(String folderId) onSelectFolder;
  final Map<String, int> unreadByFolderId;
  final VoidCallback? onNewPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + (onNewPressed != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (onNewPressed != null && i == folders.length) {
            return _NewChip(onTap: onNewPressed!, scheme: scheme);
          }
          final f = folders[i];
          final active = f.id == activeFolderId;
          final unread = unreadByFolderId[f.id] ?? 0;
          return _FolderChip(
            icon: _folderIcon(f.id),
            label: f.name,
            active: active,
            unread: unread,
            onTap: () => onSelectFolder(f.id),
            scheme: scheme,
          );
        },
      ),
    );
  }
}

IconData _folderIcon(String id) {
  switch (id) {
    case 'favorites':
      return Icons.star_rounded;
    case 'all':
      return Icons.folder_rounded;
    case 'unread':
      return Icons.chat_bubble_rounded;
    case 'personal':
      return Icons.person_rounded;
    case 'groups':
      return Icons.group_rounded;
    default:
      return Icons.folder_open_rounded;
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.unread,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int unread;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: (active ? scheme.primary : Colors.white).withValues(
            alpha: active ? 0.18 : (dark ? 0.08 : 0.35),
          ),
          border: Border.all(
            color: (active ? scheme.primary : Colors.white).withValues(
              alpha: active ? 0.35 : (dark ? 0.14 : 0.40),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.68),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
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
  const _NewChip({required this.onTap, required this.scheme});

  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: dark ? 0.06 : 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.14 : 0.40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Новая',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
