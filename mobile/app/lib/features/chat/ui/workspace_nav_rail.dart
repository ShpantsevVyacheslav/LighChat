import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/admin/data/user_role_provider.dart';

/// Вертикальный навигационный rail для desktop master-detail layout
/// (`WorkspaceShellScreen`). Заменяет горизонтальный `ChatBottomNav`,
/// который скрывается через `ChatListPane.hideBottomNav: true`.
///
/// Ширина: 72dp (компактная rail-полоска без подписей под иконками,
/// как в Slack/Telegram-desktop). Активный таб подсвечивается,
/// аватарка пользователя — внизу.
class WorkspaceNavRail extends ConsumerWidget {
  const WorkspaceNavRail({super.key, this.activeRoute});

  /// Текущий активный путь — для подсветки соответствующей иконки.
  /// Если null, ничего не выделяется (например, в admin-секциях).
  final String? activeRoute;

  static const double railWidth = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    final user = ref.watch(authUserProvider).asData?.value;
    final role = ref.watch(userRoleProvider).asData?.value ?? AppUserRole.user;

    return Container(
      width: railWidth,
      color: c.surfaceContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Верхняя группа: основные tabs
          Column(
            children: [
              const SizedBox(height: 12),
              _RailButton(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                tooltip: 'Чаты',
                active: _isActive('/workspace') || _isActive('/chats'),
                onTap: () => context.go('/workspace'),
              ),
              _RailButton(
                icon: Icons.contacts_outlined,
                activeIcon: Icons.contacts,
                tooltip: 'Контакты',
                active: _isActive('/contacts'),
                onTap: () => context.go('/contacts'),
              ),
              _RailButton(
                icon: Icons.call_outlined,
                activeIcon: Icons.call,
                tooltip: 'Звонки',
                active: _isActive('/calls'),
                onTap: () => context.go('/calls'),
              ),
              _RailButton(
                icon: Icons.videocam_outlined,
                activeIcon: Icons.videocam,
                tooltip: 'Видеоконференции',
                active: _isActive('/meetings'),
                onTap: () => context.go('/meetings'),
              ),
              if (role.canAccessAdmin)
                _RailButton(
                  icon: Icons.admin_panel_settings_outlined,
                  activeIcon: Icons.admin_panel_settings,
                  tooltip: 'Админ-панель',
                  active: _isActive('/admin'),
                  onTap: () => context.push('/admin'),
                ),
            ],
          ),
          // Нижняя группа: настройки + профиль
          Column(
            children: [
              _RailButton(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                tooltip: 'Настройки',
                active: _isActive('/settings'),
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/account'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
        ],
      ),
    );
  }

  bool _isActive(String prefix) {
    final r = activeRoute;
    if (r == null) return false;
    return r == prefix || r.startsWith('$prefix/');
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
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
          width: WorkspaceNavRail.railWidth,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
