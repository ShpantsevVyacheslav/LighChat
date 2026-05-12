import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/admin/data/user_role_provider.dart';
import 'chat_folders_rail.dart' show activeFoldersRailIdProvider;

/// Узкая (64dp) вертикальная панель слева — повторяет web-layout LighChat:
///
/// ```
/// ┌──────┐
/// │ logo │ ← клик: collapse/expand master pane
/// ├──────┤
/// │ ⭐   │ ← Избранное
/// │ 📥   │ ← Все
/// │ ✉    │ ← Новые
/// │ 👤   │ ← Личные
/// │ 👥   │ ← Группы
/// │  +   │ ← Новая папка
/// │      │
/// │  …   │ ← spacer
/// │      │
/// ├──────┤
/// │ 💬   │ ← Чаты
/// │ 📇   │ ← Контакты
/// │ 📞   │ ← Звонки
/// │ 🎥   │ ← Видеоконф.
/// ├──────┤
/// │ 👨   │ ← Аватар → профиль
/// └──────┘
/// ```
///
/// Tabs в нижней части (как в web). Folders группированы в верхней
/// под logo. Active state подсвечивает только selected folder ИЛИ active tab.
class WorkspaceUnifiedRail extends ConsumerWidget {
  const WorkspaceUnifiedRail({
    super.key,
    required this.activeRoute,
    required this.onLogoTap,
  });

  /// Текущий URL — для подсветки активного таба (`/workspace/chats`,
  /// `/workspace/contacts`, etc.).
  final String activeRoute;

  /// Клик по логотипу — обычно toggle collapse master pane.
  final VoidCallback onLogoTap;

  static const double railWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    final user = ref.watch(authUserProvider).asData?.value;
    final role = ref.watch(userRoleProvider).asData?.value ?? AppUserRole.user;
    final activeFolder = ref.watch(activeFoldersRailIdProvider);

    return Container(
      width: railWidth,
      color: c.surfaceContainer,
      child: Column(
        children: [
          // Лого вверху — clickable, collapse master pane.
          const SizedBox(height: 6),
          _LogoButton(onTap: onLogoTap),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1),

          // Folders (Избранное / Все / Новые / Личные / Группы + Новая)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _FolderIconButton(
                    icon: Icons.star_rounded,
                    tooltip: 'Избранное',
                    active: activeFolder == 'favorites',
                    onTap: () => _selectFolder(ref, 'favorites'),
                  ),
                  _FolderIconButton(
                    icon: Icons.all_inbox_rounded,
                    tooltip: 'Все',
                    active: activeFolder == 'all',
                    onTap: () => _selectFolder(ref, 'all'),
                  ),
                  _FolderIconButton(
                    icon: Icons.mark_email_unread_rounded,
                    tooltip: 'Новые',
                    active: activeFolder == 'unread',
                    onTap: () => _selectFolder(ref, 'unread'),
                  ),
                  _FolderIconButton(
                    icon: Icons.person_rounded,
                    tooltip: 'Личные',
                    active: activeFolder == 'personal',
                    onTap: () => _selectFolder(ref, 'personal'),
                  ),
                  _FolderIconButton(
                    icon: Icons.groups_rounded,
                    tooltip: 'Группы',
                    active: activeFolder == 'groups',
                    onTap: () => _selectFolder(ref, 'groups'),
                  ),
                  _FolderIconButton(
                    icon: Icons.create_new_folder_outlined,
                    tooltip: 'Новая папка',
                    active: false,
                    onTap: () {
                      // TODO: открыть create-folder dialog
                    },
                  ),
                ],
              ),
            ),
          ),

          // Tabs (как в веб — снизу).
          const Divider(height: 1, thickness: 1),
          _TabIconButton(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            tooltip: 'Чаты',
            active: _isActive('/workspace') || _isActive('/chats'),
            onTap: () => context.go('/workspace'),
          ),
          _TabIconButton(
            icon: Icons.contacts_outlined,
            activeIcon: Icons.contacts,
            tooltip: 'Контакты',
            active: _isActive('/contacts'),
            onTap: () => context.go('/contacts'),
          ),
          _TabIconButton(
            icon: Icons.call_outlined,
            activeIcon: Icons.call,
            tooltip: 'Звонки',
            active: _isActive('/calls'),
            onTap: () => context.go('/calls'),
          ),
          _TabIconButton(
            icon: Icons.videocam_outlined,
            activeIcon: Icons.videocam,
            tooltip: 'Видеоконференции',
            active: _isActive('/meetings'),
            onTap: () => context.go('/meetings'),
          ),
          if (role.canAccessAdmin)
            _TabIconButton(
              icon: Icons.admin_panel_settings_outlined,
              activeIcon: Icons.admin_panel_settings,
              tooltip: 'Админ',
              active: _isActive('/admin'),
              onTap: () => context.push('/admin'),
            ),
          _TabIconButton(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            tooltip: 'Настройки',
            active: _isActive('/settings'),
            onTap: () => context.push('/settings'),
          ),

          // Avatar — самый низ.
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => context.push('/account'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: (user?.photoURL?.isNotEmpty == true)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL?.isEmpty ?? true)
                    ? Text(
                        (user?.displayName ?? user?.email ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectFolder(WidgetRef ref, String folderId) {
    ref.read(activeFoldersRailIdProvider.notifier).state = folderId;
  }

  bool _isActive(String prefix) {
    return activeRoute == prefix || activeRoute.startsWith('$prefix/');
  }
}

class _LogoButton extends StatelessWidget {
  const _LogoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Свернуть/развернуть список чатов',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset(
            'assets/lighchat_mark.svg',
            width: 32,
            height: 32,
            // SVG может отсутствовать — flutter_svg вернёт ошибку silently.
            // На рантайме лучше попробовать через AssetImage:
            placeholderBuilder: (_) => Image.asset(
              'assets/lighchat_mark.png',
              width: 32,
              height: 32,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.chat_bubble_outline, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderIconButton extends StatelessWidget {
  const _FolderIconButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: WorkspaceUnifiedRail.railWidth,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: active
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: c.primary, width: 3),
                  ),
                  color: c.primary.withValues(alpha: 0.08),
                )
              : null,
          child: Icon(
            icon,
            color: active ? c.primary : c.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: WorkspaceUnifiedRail.railWidth,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: active
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: c.primary, width: 3),
                  ),
                  color: c.primary.withValues(alpha: 0.08),
                )
              : null,
          child: Icon(
            active ? activeIcon : icon,
            color: active ? c.primary : c.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );
  }
}
