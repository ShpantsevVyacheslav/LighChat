import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import 'profile_subpage_header.dart';

const double _kCardTitleSize = 18;
const double _kBodyTextSize = 14;

class ChatAdvancedPrivacyScreen extends ConsumerWidget {
  const ChatAdvancedPrivacyScreen({super.key, required this.conversationId});

  final String conversationId;

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

              final repo = ref.read(chatSettingsRepositoryProvider);
              final userDocAsync = ref.watch(
                userChatSettingsDocProvider(user.uid),
              );
              final userDoc =
                  userDocAsync.asData?.value ?? const <String, dynamic>{};
              final raw = userDoc['privacySettings'];
              final rawMap = raw is Map
                  ? raw.map((k, v) => MapEntry(k.toString(), v))
                  : const <String, Object?>{};
              final st = _AdvancedPrivacyState.fromRaw(rawMap);

              Future<void> patch(Map<String, Object?> privacyPatch) async {
                if (repo == null) return;
                try {
                  await repo.patchUserDoc(user.uid, <String, Object?>{
                    'privacySettings': privacyPatch,
                  });
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Не удалось сохранить настройки: $e'),
                    ),
                  );
                }
              }

              return _AdvancedPrivacyView(
                state: st,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/chats/$conversationId');
                  }
                },
                onShowOnlineChanged: (v) => patch({'showOnlineStatus': v}),
                onShowLastSeenChanged: (v) => patch({'showLastSeen': v}),
                onShowReadReceiptsChanged: (v) =>
                    patch({'showReadReceipts': v}),
                onShowEmailChanged: (v) => patch({'showEmailToOthers': v}),
                onShowPhoneChanged: (v) => patch({'showPhoneToOthers': v}),
                onShowDobChanged: (v) => patch({'showDateOfBirthToOthers': v}),
                onShowBioChanged: (v) => patch({'showBioToOthers': v}),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка загрузки приватности: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvancedPrivacyView extends StatelessWidget {
  const _AdvancedPrivacyView({
    required this.state,
    required this.onBack,
    required this.onShowOnlineChanged,
    required this.onShowLastSeenChanged,
    required this.onShowReadReceiptsChanged,
    required this.onShowEmailChanged,
    required this.onShowPhoneChanged,
    required this.onShowDobChanged,
    required this.onShowBioChanged,
  });

  final _AdvancedPrivacyState state;
  final VoidCallback onBack;
  final ValueChanged<bool> onShowOnlineChanged;
  final ValueChanged<bool> onShowLastSeenChanged;
  final ValueChanged<bool> onShowReadReceiptsChanged;
  final ValueChanged<bool> onShowEmailChanged;
  final ValueChanged<bool> onShowPhoneChanged;
  final ValueChanged<bool> onShowDobChanged;
  final ValueChanged<bool> onShowBioChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ChatProfileSubpageHeader(title: 'Приватность чата', onBack: onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _SettingsCard(
                  title: 'Видимость',
                  leadingIcon: Icons.visibility_outlined,
                  children: [
                    _SwitchRow(
                      title: 'Статус онлайн',
                      value: state.showOnlineStatus,
                      onChanged: onShowOnlineChanged,
                      icon: Icons.wifi_tethering_rounded,
                    ),
                    _SwitchRow(
                      title: 'Последний визит',
                      value: state.showLastSeen,
                      onChanged: onShowLastSeenChanged,
                      icon: Icons.schedule_rounded,
                    ),
                    _SwitchRow(
                      title: 'Индикатор прочтения',
                      value: state.showReadReceipts,
                      onChanged: onShowReadReceiptsChanged,
                      icon: Icons.done_all_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Информация профиля',
                  leadingIcon: Icons.badge_outlined,
                  children: [
                    _SwitchRow(
                      title: 'Email',
                      value: state.showEmailToOthers,
                      onChanged: onShowEmailChanged,
                      icon: Icons.mail_outline_rounded,
                    ),
                    _SwitchRow(
                      title: 'Номер телефона',
                      value: state.showPhoneToOthers,
                      onChanged: onShowPhoneChanged,
                      icon: Icons.smartphone_rounded,
                    ),
                    _SwitchRow(
                      title: 'Дата рождения',
                      value: state.showDateOfBirthToOthers,
                      onChanged: onShowDobChanged,
                      icon: Icons.cake_rounded,
                    ),
                    _SwitchRow(
                      title: 'О себе',
                      value: state.showBioToOthers,
                      onChanged: onShowBioChanged,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
    this.leadingIcon,
  });

  final String title;
  final List<Widget> children;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: (dark ? const Color(0xFF08111B) : Colors.white).withValues(
          alpha: dark ? 0.86 : 0.84,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.44),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 18,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : scheme.onSurface.withValues(alpha: 0.62),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _kCardTitleSize,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 20,
                color: dark
                    ? Colors.white.withValues(alpha: 0.70)
                    : scheme.onSurface.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: _kBodyTextSize,
                fontWeight: FontWeight.w600,
                color: dark
                    ? Colors.white.withValues(alpha: 0.95)
                    : scheme.onSurface.withValues(alpha: 0.94),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2F86FF),
            inactiveThumbColor: (dark ? Colors.white : scheme.surface)
                .withValues(alpha: dark ? 0.9 : 1),
            inactiveTrackColor: (dark ? Colors.white : scheme.onSurface)
                .withValues(alpha: dark ? 0.2 : 0.2),
          ),
        ],
      ),
    );
  }
}

class _AdvancedPrivacyState {
  const _AdvancedPrivacyState({
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.showReadReceipts,
    required this.showEmailToOthers,
    required this.showPhoneToOthers,
    required this.showDateOfBirthToOthers,
    required this.showBioToOthers,
  });

  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool showReadReceipts;
  final bool showEmailToOthers;
  final bool showPhoneToOthers;
  final bool showDateOfBirthToOthers;
  final bool showBioToOthers;

  factory _AdvancedPrivacyState.fromRaw(Map<String, Object?> raw) {
    return _AdvancedPrivacyState(
      showOnlineStatus: raw['showOnlineStatus'] != false,
      showLastSeen: raw['showLastSeen'] != false,
      showReadReceipts: raw['showReadReceipts'] != false,
      showEmailToOthers: raw['showEmailToOthers'] != false,
      showPhoneToOthers: raw['showPhoneToOthers'] != false,
      showDateOfBirthToOthers: raw['showDateOfBirthToOthers'] != false,
      showBioToOthers: raw['showBioToOthers'] != false,
    );
  }
}
