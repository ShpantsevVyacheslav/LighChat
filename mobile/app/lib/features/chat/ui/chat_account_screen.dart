import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../data/app_theme_preference.dart';
import '../data/user_profile.dart';
import '../../auth/ui/auth_glass.dart';
import 'chat_avatar.dart';

class ChatAccountScreen extends ConsumerWidget {
  const ChatAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/auth');
                });
                return const Center(child: CircularProgressIndicator());
              }

              final userDocAsync = ref.watch(
                userChatSettingsDocProvider(user.uid),
              );
              final userDoc =
                  userDocAsync.asData?.value ?? const <String, dynamic>{};
              final appThemePref = appThemePreferenceFromRaw(
                userDoc['appTheme'],
              );
              final appThemeLabel = appThemePreferenceLabel(appThemePref);

              final profilesRepo = ref.watch(userProfilesRepositoryProvider);
              final profileStream = profilesRepo?.watchUsersByIds(<String>[
                user.uid,
              ]);

              return StreamBuilder<Map<String, UserProfile>>(
                stream: profileStream,
                builder: (context, snap) {
                  final profile = snap.data?[user.uid];
                  final rawName = profile?.name ?? '';
                  final rawUsername = profile?.username ?? '';
                  final name = rawName.trim().isNotEmpty
                      ? rawName.trim()
                      : 'Профиль';
                  final username = rawUsername.trim().isNotEmpty
                      ? rawUsername.trim().replaceFirst(RegExp(r'^@'), '')
                      : 'user';
                  final avatarUrl = profile?.avatarThumb ?? profile?.avatar;

                  return _AccountView(
                    name: name,
                    username: username,
                    avatarUrl: avatarUrl,
                    themeLabel: appThemeLabel,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/chats');
                      }
                    },
                    onProfileTap: () => context.push('/profile'),
                    onChatSettingsTap: () => context.push('/settings/chats'),
                    onNotificationsTap: () =>
                        context.push('/settings/notifications'),
                    onPrivacyTap: () => context.push('/settings/privacy'),
                    onThemeTap: () async {
                      final repo = ref.read(chatSettingsRepositoryProvider);
                      if (repo == null) return;
                      final next = nextAppThemePreference(appThemePref);
                      final nextRaw = appThemePreferenceToRaw(next);
                      final label = appThemePreferenceLabel(next);
                      try {
                        await repo.patchUserDoc(user.uid, <String, Object?>{
                          'appTheme': nextRaw,
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Тема: $label')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Не удалось сохранить тему: $e'),
                          ),
                        );
                      }
                    },
                    onSoon: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Скоро')));
                    },
                    onSignOutTap: () async {
                      final repo = ref.read(authRepositoryProvider);
                      try {
                        if (repo != null) {
                          await repo.signOut();
                        }
                        if (context.mounted) context.go('/auth');
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Не удалось выйти: $e')),
                        );
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка профиля: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.themeLabel,
    required this.onBack,
    required this.onProfileTap,
    required this.onChatSettingsTap,
    required this.onNotificationsTap,
    required this.onPrivacyTap,
    required this.onThemeTap,
    required this.onSoon,
    required this.onSignOutTap,
  });

  final String name;
  final String username;
  final String? avatarUrl;
  final String themeLabel;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;
  final VoidCallback onChatSettingsTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onThemeTap;
  final VoidCallback onSoon;
  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final titleColor = dark
        ? Colors.white.withValues(alpha: 0.95)
        : scheme.onSurface.withValues(alpha: 0.96);
    final secondaryColor = dark
        ? Colors.white.withValues(alpha: 0.5)
        : scheme.onSurface.withValues(alpha: 0.54);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Material(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : scheme.surface.withValues(alpha: 0.72),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 30,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ChatAvatar(title: name, radius: 44, avatarUrl: avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Профиль',
                        onTap: onProfileTap,
                      ),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Настройки чатов',
                        onTap: onChatSettingsTap,
                      ),
                      _MenuItem(
                        icon: Icons.history_rounded,
                        title: 'Администрирование',
                        onTap: onSoon,
                      ),
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомления',
                        onTap: onNotificationsTap,
                      ),
                      _MenuItem(
                        icon: Icons.access_time_rounded,
                        title: 'Конфиденциальность',
                        onTap: onPrivacyTap,
                      ),
                      _MenuItem(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Тема',
                        trailing: '· $themeLabel',
                        onTap: onThemeTap,
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: (dark ? Colors.white : scheme.onSurface)
                            .withValues(alpha: dark ? 0.12 : 0.14),
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Выйти',
                        warning: true,
                        onTap: onSignOutTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.warning = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool warning;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final regularColor = dark
        ? Colors.white.withValues(alpha: 0.92)
        : scheme.onSurface.withValues(alpha: 0.92);
    final iconColor = dark
        ? Colors.white.withValues(alpha: 0.72)
        : scheme.onSurface.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: warning ? const Color(0xFFFF6E6E) : iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: warning ? const Color(0xFFFF7A7A) : regularColor,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.45)
                          : scheme.onSurface.withValues(alpha: 0.58),
                    ),
                  )
                else if (!warning)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.28)
                        : scheme.onSurface.withValues(alpha: 0.34),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
