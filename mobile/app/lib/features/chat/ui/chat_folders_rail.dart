import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';

/// Вертикальная папочная панель для desktop master-detail layout.
///
/// Показывает встроенные папки (Избранное / Все / Новые / Личные / Группы)
/// + кастомные папки пользователя. Активная папка хранится в локальном
/// [StateProvider] [activeFoldersRailIdProvider], `ChatListPane` слушает
/// тот же provider (через TODO-интеграцию) или работает независимо.
///
/// Ширина: 88dp (узкая колонка с компактными chip-кнопками). На веб-версии
/// аналог — левый folders rail в `DashboardChatListColumn`.
class ChatFoldersRail extends ConsumerWidget {
  const ChatFoldersRail({super.key, this.onSelected});

  /// Колбэк выбора папки (если null — обновляется только локальный provider).
  final ValueChanged<String>? onSelected;

  static const double railWidth = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authUserProvider).asData?.value;
    final c = Theme.of(context).colorScheme;

    if (user == null) {
      return SizedBox(
        width: railWidth,
        child: ColoredBox(color: c.surfaceContainer),
      );
    }

    final indexAsync = ref.watch(userChatIndexProvider(user.uid));

    return Container(
      width: railWidth,
      color: c.surfaceContainer,
      child: indexAsync.when(
        data: (idx) {
          final folders = _builtIn(l10n) + (idx?.folders ?? const <ChatFolder>[]);
          final active = ref.watch(activeFoldersRailIdProvider);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: folders.length + 1, // +1 = «новая»
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              if (i == folders.length) {
                return _FolderTile(
                  icon: Icons.add_rounded,
                  label: l10n.chat_folder_new,
                  active: false,
                  onTap: () {
                    // TODO: открыть существующий create-folder dialog
                    // (он живёт внутри _ChatListBodyState — нужно вынести
                    // в reusable callable, чтобы переиспользовать здесь).
                  },
                );
              }
              final f = folders[i];
              return _FolderTile(
                icon: _iconFor(f.id),
                label: f.name,
                active: active == f.id,
                onTap: () {
                  ref.read(activeFoldersRailIdProvider.notifier).state = f.id;
                  if (onSelected != null) onSelected!(f.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  /// Зеркало `_buildFolders` из `chat_list_screen.dart`. Дубль логики —
  /// потому что rail работает независимо от `_ChatListBodyState` (его
  /// `_buildFolders` приватный). Текстовые лейблы берём из локализации.
  List<ChatFolder> _builtIn(AppLocalizations l10n) {
    return <ChatFolder>[
      ChatFolder(
        id: 'favorites',
        name: l10n.chat_folder_favorites,
        conversationIds: const <String>[],
      ),
      ChatFolder(
        id: 'all',
        name: l10n.chat_list_folder_default_all,
        conversationIds: const <String>[],
      ),
      ChatFolder(
        id: 'unread',
        name: l10n.chat_list_folder_default_new,
        conversationIds: const <String>[],
      ),
      ChatFolder(
        id: 'personal',
        name: l10n.chat_list_folder_default_direct,
        conversationIds: const <String>[],
      ),
      ChatFolder(
        id: 'groups',
        name: l10n.chat_list_folder_default_groups,
        conversationIds: const <String>[],
      ),
    ];
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'favorites':
        return Icons.star_rounded;
      case 'all':
        return Icons.all_inbox_rounded;
      case 'unread':
        return Icons.mark_email_unread_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'groups':
        return Icons.groups_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}

/// Активная папка folders-rail. Локальный notifier — пока не связан с
/// `_ChatListBodyState._activeFolderId` (тот приватный), но UI rail
/// независим: при клике подсвечивается, ChatListPane продолжает
/// показывать свою активную папку из встроенного `ChatFolderBar` сверху.
/// Соединение через single state — TODO.
class ActiveFoldersRailNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final NotifierProvider<ActiveFoldersRailNotifier, String>
    activeFoldersRailIdProvider =
    NotifierProvider<ActiveFoldersRailNotifier, String>(
        ActiveFoldersRailNotifier.new);

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                border: Border(
                  left: BorderSide(color: c.primary, width: 3),
                ),
              )
            : null,
        child: Column(
          children: [
            Icon(icon,
                color: active ? c.primary : c.onSurfaceVariant, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? c.primary : c.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
