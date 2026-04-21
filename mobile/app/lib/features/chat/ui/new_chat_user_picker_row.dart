import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import 'chat_avatar.dart';

/// Внешний вид строки: карточка (группа и т.п.) или плоский список (экран «Новый чат»).
enum NewChatUserPickerRowStyle {
  card,
  list,
}

/// Строка выбора пользователя в стиле [ChatListItem] (без времени и бейджа непрочитанного).
class NewChatUserPickerRow extends StatelessWidget {
  const NewChatUserPickerRow({
    super.key,
    required this.profile,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.selectionTrailing = false,
    this.style = NewChatUserPickerRowStyle.card,
  });

  final UserProfile profile;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final bool selectionTrailing;
  final NewChatUserPickerRowStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final avatarUrl = profile.avatarThumb ?? profile.avatar;
    final handle = (profile.username ?? '').trim();
    final subtitle = handle.isNotEmpty ? '@$handle' : '';
    final listStyle = style == NewChatUserPickerRowStyle.list;

    final row = Row(
      children: [
        ChatAvatar(title: profile.name, radius: 22, avatarUrl: avatarUrl),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: listStyle ? 16 : 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: listStyle ? 0.52 : 0.60),
                    fontWeight: listStyle ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (selectionTrailing) ...[
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.35),
            size: 22,
          ),
        ],
      ],
    );

    if (listStyle) {
      return Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: row,
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: dark ? 0.10 : 0.35),
            ),
            color: selected
                ? scheme.primary.withValues(alpha: dark ? 0.12 : 0.14)
                : Colors.white.withValues(alpha: dark ? 0.06 : 0.22),
          ),
          child: row,
        ),
      ),
    );
  }
}
