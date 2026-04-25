import 'package:flutter/material.dart';

import 'chat_avatar.dart';

class ChatAccountMenuSheet extends StatelessWidget {
  const ChatAccountMenuSheet({
    super.key,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.themeLabel,
    required this.onProfileTap,
    required this.onChatSettingsTap,
    required this.onThemeTap,
    required this.onSignOutTap,
  });

  final String name;
  final String username;
  final String? avatarUrl;
  final String themeLabel;
  final VoidCallback onProfileTap;
  final VoidCallback onChatSettingsTap;
  final VoidCallback onThemeTap;
  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    Widget item({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool warning = false,
      String? trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: (dark ? const Color(0xFF152028) : Colors.white)
                    .withValues(alpha: dark ? 0.92 : 0.96),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.18 : 0.46),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: warning
                        ? scheme.error
                        : scheme.onSurface.withValues(alpha: 0.86),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: warning
                            ? scheme.error
                            : scheme.onSurface.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    )
                  else if (!warning)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.42),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void soon() {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Скоро')));
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: (dark ? const Color(0xFF0E1A22) : Colors.white).withValues(
              alpha: dark ? 0.95 : 0.97,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.20 : 0.48),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ChatAvatar(title: name, radius: 32, avatarUrl: avatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              item(
                icon: Icons.account_circle_outlined,
                title: 'Профиль',
                onTap: onProfileTap,
              ),
              item(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Настройки чатов',
                onTap: onChatSettingsTap,
              ),
              item(
                icon: Icons.notifications_none_rounded,
                title: 'Уведомления',
                onTap: soon,
              ),
              item(
                icon: Icons.shield_outlined,
                title: 'Конфиденциальность',
                onTap: soon,
              ),
              item(
                icon: Icons.palette_outlined,
                title: 'Тема',
                trailing: themeLabel,
                onTap: onThemeTap,
              ),
              item(
                icon: Icons.logout_rounded,
                title: 'Выйти',
                onTap: onSignOutTap,
                warning: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
