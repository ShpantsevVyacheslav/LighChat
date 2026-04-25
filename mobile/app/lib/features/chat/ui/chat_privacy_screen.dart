import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';

const double _kHeaderTitleSize = 16;
const double _kCardTitleSize = 18;
const double _kBodyTextSize = 14;
const double _kMutedTextSize = 13;

class ChatPrivacyScreen extends ConsumerWidget {
  const ChatPrivacyScreen({super.key});

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

              final raw = userDoc['privacySettings'];
              final rawMap = raw is Map
                  ? raw.map((k, v) => MapEntry(k.toString(), v))
                  : const <String, Object?>{};
              final settings = _PrivacySettingsState.fromRaw(rawMap);
              final repo = ref.read(chatSettingsRepositoryProvider);

              Future<void> savePatch({
                bool? showOnlineStatus,
                bool? showLastSeen,
                bool? showReadReceipts,
                bool? e2eeForNewDirectChats,
                bool? showEmailToOthers,
                bool? showPhoneToOthers,
                bool? showBioToOthers,
                bool? showDateOfBirthToOthers,
                bool? showInGlobalUserSearch,
                String? groupInvitePolicy,
                bool reset = false,
              }) async {
                if (repo == null) return;
                final next = reset
                    ? _PrivacySettingsState.defaults()
                    : settings.copyWith(
                        showOnlineStatus: showOnlineStatus,
                        showLastSeen: showLastSeen,
                        showReadReceipts: showReadReceipts,
                        e2eeForNewDirectChats: e2eeForNewDirectChats,
                        showEmailToOthers: showEmailToOthers,
                        showPhoneToOthers: showPhoneToOthers,
                        showBioToOthers: showBioToOthers,
                        showDateOfBirthToOthers: showDateOfBirthToOthers,
                        showInGlobalUserSearch: showInGlobalUserSearch,
                        groupInvitePolicy: groupInvitePolicy,
                      );
                try {
                  await repo.patchUserDoc(user.uid, <String, Object?>{
                    'privacySettings': next.toFirestoreMap(),
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

              return _PrivacyView(
                settings: settings,
                onE2eeChanged: (v) => savePatch(e2eeForNewDirectChats: v),
                onShowOnlineChanged: (v) => savePatch(showOnlineStatus: v),
                onShowLastSeenChanged: (v) => savePatch(showLastSeen: v),
                onShowReadReceiptsChanged: (v) =>
                    savePatch(showReadReceipts: v),
                onGroupPolicyChange: (v) => savePatch(groupInvitePolicy: v),
                onGlobalSearchChanged: (v) =>
                    savePatch(showInGlobalUserSearch: v),
                onShowEmailChanged: (v) => savePatch(showEmailToOthers: v),
                onShowPhoneChanged: (v) => savePatch(showPhoneToOthers: v),
                onShowDobChanged: (v) => savePatch(showDateOfBirthToOthers: v),
                onShowBioChanged: (v) => savePatch(showBioToOthers: v),
                onReset: () => savePatch(reset: true),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка загрузки конфиденциальности: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyView extends StatelessWidget {
  const _PrivacyView({
    required this.settings,
    required this.onE2eeChanged,
    required this.onShowOnlineChanged,
    required this.onShowLastSeenChanged,
    required this.onShowReadReceiptsChanged,
    required this.onGroupPolicyChange,
    required this.onGlobalSearchChanged,
    required this.onShowEmailChanged,
    required this.onShowPhoneChanged,
    required this.onShowDobChanged,
    required this.onShowBioChanged,
    required this.onReset,
  });

  final _PrivacySettingsState settings;
  final ValueChanged<bool> onE2eeChanged;
  final ValueChanged<bool> onShowOnlineChanged;
  final ValueChanged<bool> onShowLastSeenChanged;
  final ValueChanged<bool> onShowReadReceiptsChanged;
  final ValueChanged<String> onGroupPolicyChange;
  final ValueChanged<bool> onGlobalSearchChanged;
  final ValueChanged<bool> onShowEmailChanged;
  final ValueChanged<bool> onShowPhoneChanged;
  final ValueChanged<bool> onShowDobChanged;
  final ValueChanged<bool> onShowBioChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final titleColor = dark
        ? Colors.white.withValues(alpha: 0.95)
        : scheme.onSurface.withValues(alpha: 0.94);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Material(
                color: (dark ? Colors.white : scheme.surface).withValues(
                  alpha: dark ? 0.08 : 0.74,
                ),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/account');
                    }
                  },
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
              const SizedBox(width: 12),
              Text(
                'Конфиденциальность',
                style: TextStyle(
                  fontSize: _kHeaderTitleSize,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _SettingsCard(
                  title: 'Сквозное шифрование',
                  leadingIcon: Icons.lock_outline_rounded,
                  children: [
                    _SwitchRow(
                      title: 'Включить шифрование (E2E) для всех чатов',
                      value: settings.e2eeForNewDirectChats,
                      onChanged: onE2eeChanged,
                    ),
                    // Переход на экран управления устройствами (Phase 5).
                    // Держим как отдельный элемент, не switch — там список и actions.
                    _NavRow(
                      title: 'Мои устройства',
                      subtitle:
                          'Список устройств с опубликованным ключом. Переименовать или отозвать.',
                      onTap: () => context.push('/settings/devices'),
                    ),
                    // Phase 6: recovery — backup ключа паролем + QR-pairing.
                    // Оба пути нужны, если пользователь потеряет все устройства.
                    _NavRow(
                      title: 'Резервное копирование и передача ключа',
                      subtitle:
                          'Создать backup паролем или передать ключ другому устройству по QR.',
                      onTap: () => context.push('/settings/e2ee-recovery'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Видимость',
                  children: [
                    _SwitchRow(
                      title: 'Статус онлайн',
                      subtitle: 'Другие пользователи видят, что вы в сети.',
                      value: settings.showOnlineStatus,
                      onChanged: onShowOnlineChanged,
                    ),
                    _SwitchRow(
                      title: 'Последний визит',
                      subtitle: 'Показывать время последнего посещения.',
                      value: settings.showLastSeen,
                      onChanged: onShowLastSeenChanged,
                    ),
                    _SwitchRow(
                      title: 'Индикатор прочтения',
                      subtitle:
                          'Показывать отправителям, что вы прочитали сообщение.',
                      value: settings.showReadReceipts,
                      onChanged: onShowReadReceiptsChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Приглашения в группы',
                  subtitle: 'Кто может добавлять вас в групповой чат.',
                  leadingIcon: Icons.group_add_outlined,
                  children: [
                    _SwitchRow(
                      title: 'Все пользователи',
                      value: settings.groupInvitePolicy == 'everyone',
                      onChanged: (on) {
                        if (on) onGroupPolicyChange('everyone');
                      },
                    ),
                    _SwitchRow(
                      title: 'Только контакты',
                      value: settings.groupInvitePolicy == 'contacts',
                      onChanged: (on) {
                        if (on) onGroupPolicyChange('contacts');
                      },
                    ),
                    _SwitchRow(
                      title: 'Никто',
                      value: settings.groupInvitePolicy == 'none',
                      onChanged: (on) {
                        if (on) onGroupPolicyChange('none');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Поиск собеседников',
                  subtitle:
                      'Кто может найти вас по имени среди всех пользователей приложения.',
                  children: [
                    _SwitchRow(
                      title: 'Глобальный поиск',
                      subtitle:
                          'Если выключено, вы не отображаетесь в списке «Все пользователи» при создании чата. В блоке «Контакты» вы по-прежнему видны тем, кто добавил вас в контакты.',
                      value: settings.showInGlobalUserSearch,
                      onChanged: onGlobalSearchChanged,
                      icon: Icons.search_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Профиль для других',
                  subtitle:
                      'Что показывать в карточке контакта и в профиле из беседы.',
                  children: [
                    _SwitchRow(
                      title: 'Email',
                      subtitle: 'Адрес почты в профиле собеседника.',
                      value: settings.showEmailToOthers,
                      onChanged: onShowEmailChanged,
                      icon: Icons.mail_outline_rounded,
                    ),
                    _SwitchRow(
                      title: 'Номер телефона',
                      subtitle: 'В профиле и в списке контактов у других.',
                      value: settings.showPhoneToOthers,
                      onChanged: onShowPhoneChanged,
                      icon: Icons.phone_android_outlined,
                    ),
                    _SwitchRow(
                      title: 'Дата рождения',
                      subtitle: 'Поле «День рождения» в профиле.',
                      value: settings.showDateOfBirthToOthers,
                      onChanged: onShowDobChanged,
                      icon: Icons.cake_outlined,
                    ),
                    _SwitchRow(
                      title: 'О себе',
                      subtitle: 'Текст биографии в профиле.',
                      value: settings.showBioToOthers,
                      onChanged: onShowBioChanged,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          (dark ? Colors.white : scheme.surfaceContainerHighest)
                              .withValues(alpha: dark ? 0.04 : 0.86),
                      side: BorderSide(
                        color: (dark ? Colors.white : scheme.onSurface)
                            .withValues(alpha: dark ? 0.16 : 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: Color(0xCCFFFFFF),
                    ),
                    label: Text(
                      'Сбросить настройки',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: (dark ? Colors.white : scheme.onSurface)
                            .withValues(alpha: dark ? 0.7 : 0.7),
                      ),
                    ),
                  ),
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
    this.subtitle,
    this.leadingIcon,
  });

  final String title;
  final String? subtitle;
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
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: _kMutedTextSize,
                color: dark
                    ? Colors.white.withValues(alpha: 0.70)
                    : scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
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
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _kBodyTextSize,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.95)
                        : scheme.onSurface.withValues(alpha: 0.94),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: _kMutedTextSize,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.68)
                          : scheme.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ],
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

/// Строка-ссылка в карточке настроек (переход на дочерний экран).
///
/// Используется внутри `_SettingsCard` рядом со `_SwitchRow` — визуально
/// совместимая высота и отступы. Вызывается в карточке "Сквозное шифрование"
/// как entry-point для экрана "Мои устройства" (Phase 5).
class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _kBodyTextSize,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.95)
                          : scheme.onSurface.withValues(alpha: 0.94),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: _kMutedTextSize,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.68)
                            : scheme.onSurface.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: dark
                  ? Colors.white.withValues(alpha: 0.55)
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySettingsState {
  const _PrivacySettingsState({
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.showReadReceipts,
    required this.e2eeForNewDirectChats,
    required this.showEmailToOthers,
    required this.showPhoneToOthers,
    required this.showBioToOthers,
    required this.showDateOfBirthToOthers,
    required this.showInGlobalUserSearch,
    required this.groupInvitePolicy,
  });

  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool showReadReceipts;
  final bool e2eeForNewDirectChats;
  final bool showEmailToOthers;
  final bool showPhoneToOthers;
  final bool showBioToOthers;
  final bool showDateOfBirthToOthers;
  final bool showInGlobalUserSearch;
  final String groupInvitePolicy;

  factory _PrivacySettingsState.defaults() {
    return const _PrivacySettingsState(
      showOnlineStatus: true,
      showLastSeen: true,
      showReadReceipts: true,
      e2eeForNewDirectChats: false,
      showEmailToOthers: true,
      showPhoneToOthers: true,
      showBioToOthers: true,
      showDateOfBirthToOthers: true,
      showInGlobalUserSearch: true,
      groupInvitePolicy: 'everyone',
    );
  }

  factory _PrivacySettingsState.fromRaw(Map<String, Object?> raw) {
    String normalizePolicy(Object? v) {
      if (v is String && (v == 'everyone' || v == 'contacts' || v == 'none')) {
        return v;
      }
      return 'everyone';
    }

    return _PrivacySettingsState(
      showOnlineStatus: raw['showOnlineStatus'] != false,
      showLastSeen: raw['showLastSeen'] != false,
      showReadReceipts: raw['showReadReceipts'] != false,
      e2eeForNewDirectChats: raw['e2eeForNewDirectChats'] == true,
      showEmailToOthers: raw['showEmailToOthers'] != false,
      showPhoneToOthers: raw['showPhoneToOthers'] != false,
      showBioToOthers: raw['showBioToOthers'] != false,
      showDateOfBirthToOthers: raw['showDateOfBirthToOthers'] != false,
      showInGlobalUserSearch: raw['showInGlobalUserSearch'] != false,
      groupInvitePolicy: normalizePolicy(raw['groupInvitePolicy']),
    );
  }

  _PrivacySettingsState copyWith({
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? showReadReceipts,
    bool? e2eeForNewDirectChats,
    bool? showEmailToOthers,
    bool? showPhoneToOthers,
    bool? showBioToOthers,
    bool? showDateOfBirthToOthers,
    bool? showInGlobalUserSearch,
    String? groupInvitePolicy,
  }) {
    return _PrivacySettingsState(
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      e2eeForNewDirectChats:
          e2eeForNewDirectChats ?? this.e2eeForNewDirectChats,
      showEmailToOthers: showEmailToOthers ?? this.showEmailToOthers,
      showPhoneToOthers: showPhoneToOthers ?? this.showPhoneToOthers,
      showBioToOthers: showBioToOthers ?? this.showBioToOthers,
      showDateOfBirthToOthers:
          showDateOfBirthToOthers ?? this.showDateOfBirthToOthers,
      showInGlobalUserSearch:
          showInGlobalUserSearch ?? this.showInGlobalUserSearch,
      groupInvitePolicy: groupInvitePolicy ?? this.groupInvitePolicy,
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'showOnlineStatus': showOnlineStatus,
    'showLastSeen': showLastSeen,
    'showReadReceipts': showReadReceipts,
    'e2eeForNewDirectChats': e2eeForNewDirectChats,
    'showEmailToOthers': showEmailToOthers,
    'showPhoneToOthers': showPhoneToOthers,
    'showBioToOthers': showBioToOthers,
    'showDateOfBirthToOthers': showDateOfBirthToOthers,
    'showInGlobalUserSearch': showInGlobalUserSearch,
    'groupInvitePolicy': groupInvitePolicy,
  };
}
