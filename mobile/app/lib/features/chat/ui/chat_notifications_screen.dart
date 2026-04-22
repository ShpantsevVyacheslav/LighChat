import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';

const double _kHeaderTitleSize = 16;
const double _kCardTitleSize = 18;
const double _kBodyTextSize = 14;
const double _kMutedTextSize = 13;

class ChatNotificationsScreen extends ConsumerWidget {
  const ChatNotificationsScreen({super.key});

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

              final raw = userDoc['notificationSettings'];
              final rawMap = raw is Map
                  ? raw.map((k, v) => MapEntry(k.toString(), v))
                  : const <String, Object?>{};
              final settings = _NotificationSettingsState.fromRaw(rawMap);
              final repo = ref.read(chatSettingsRepositoryProvider);

              Future<void> savePatch({
                bool? soundEnabled,
                bool? showPreview,
                bool? muteAll,
                bool? quietHoursEnabled,
                String? quietHoursStart,
                String? quietHoursEnd,
                bool reset = false,
              }) async {
                if (repo == null) return;
                final tz = _resolveTimeZone(settings.quietHoursTimeZone);
                final next = reset
                    ? _NotificationSettingsState.defaults(tz: tz)
                    : settings.copyWith(
                        soundEnabled: soundEnabled,
                        showPreview: showPreview,
                        muteAll: muteAll,
                        quietHoursEnabled: quietHoursEnabled,
                        quietHoursStart: quietHoursStart,
                        quietHoursEnd: quietHoursEnd,
                        quietHoursTimeZone: tz,
                      );
                try {
                  await repo.patchUserDoc(user.uid, <String, Object?>{
                    'notificationSettings': next.toFirestoreMap(),
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

              Future<void> pickTime(bool start) async {
                if (settings.muteAll || !settings.quietHoursEnabled) return;
                final initial = _parseTimeOfDay(
                  start ? settings.quietHoursStart : settings.quietHoursEnd,
                  fallback: start
                      ? const TimeOfDay(hour: 23, minute: 0)
                      : const TimeOfDay(hour: 7, minute: 0),
                );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
                if (picked == null) return;
                final hm =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                await savePatch(
                  quietHoursStart: start ? hm : null,
                  quietHoursEnd: start ? null : hm,
                );
              }

              return _NotificationsView(
                settings: settings,
                onMuteAllChanged: (v) => savePatch(muteAll: v),
                onSoundChanged: (v) => savePatch(soundEnabled: v),
                onPreviewChanged: (v) => savePatch(showPreview: v),
                onQuietHoursChanged: (v) => savePatch(quietHoursEnabled: v),
                onPickQuietHoursStart: () => pickTime(true),
                onPickQuietHoursEnd: () => pickTime(false),
                onReset: () => savePatch(reset: true),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка загрузки уведомлений: $e'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({
    required this.settings,
    required this.onMuteAllChanged,
    required this.onSoundChanged,
    required this.onPreviewChanged,
    required this.onQuietHoursChanged,
    required this.onPickQuietHoursStart,
    required this.onPickQuietHoursEnd,
    required this.onReset,
  });

  final _NotificationSettingsState settings;
  final ValueChanged<bool> onMuteAllChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onPreviewChanged;
  final ValueChanged<bool> onQuietHoursChanged;
  final VoidCallback onPickQuietHoursStart;
  final VoidCallback onPickQuietHoursEnd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final titleColor = dark
        ? Colors.white.withValues(alpha: 0.95)
        : scheme.onSurface.withValues(alpha: 0.94);
    final subtitleColor = dark
        ? Colors.white.withValues(alpha: 0.56)
        : scheme.onSurface.withValues(alpha: 0.62);

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
              const SizedBox(width: 14),
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF4DA2FF),
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                'Уведомления',
                style: TextStyle(
                  fontSize: _kHeaderTitleSize,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Управление звуками и показом уведомлений.',
                  style: TextStyle(fontSize: _kBodyTextSize, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: dark ? 0.35 : 0.55,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Push на устройство: после входа приложение запросит разрешение; '
                      'при отказе включите уведомления для LighChat в настройках системы.',
                      style: TextStyle(
                        fontSize: _kMutedTextSize,
                        color: subtitleColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _SettingsCard(
                  title: 'Основные',
                  children: [
                    _SwitchRow(
                      title: 'Отключить все',
                      subtitle: 'Полностью выключить уведомления.',
                      value: settings.muteAll,
                      onChanged: onMuteAllChanged,
                    ),
                    _cardDivider(),
                    _SwitchRow(
                      title: 'Звук',
                      subtitle: 'Воспроизводить звук при новом сообщении.',
                      value: settings.soundEnabled,
                      onChanged: onSoundChanged,
                      disabled: settings.muteAll,
                    ),
                    _cardDivider(),
                    _SwitchRow(
                      title: 'Предпросмотр',
                      subtitle: 'Показывать текст сообщения в уведомлении.',
                      value: settings.showPreview,
                      onChanged: onPreviewChanged,
                      disabled: settings.muteAll,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Тихие часы',
                  subtitle:
                      'Уведомления не будут беспокоить в указанный период.',
                  children: [
                    _SwitchRow(
                      title: 'Включить тихие часы',
                      value: settings.quietHoursEnabled,
                      onChanged: onQuietHoursChanged,
                      disabled: settings.muteAll,
                    ),
                    if (settings.quietHoursEnabled && !settings.muteAll) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeButton(
                              label: null,
                              value: settings.quietHoursStart,
                              onTap: onPickQuietHoursStart,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 22, 10, 0),
                            child: Text(
                              '—',
                              style: TextStyle(
                                fontSize: _kCardTitleSize,
                                color: (dark ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: dark ? 0.72 : 0.64),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _TimeButton(
                              label: null,
                              value: settings.quietHoursEnd,
                              onTap: onPickQuietHoursEnd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 66,
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
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(
                      Icons.sync_rounded,
                      size: 28 * 0.75,
                      color: Color(0xCCFFFFFF),
                    ),
                    label: Text(
                      'Сбросить настройки',
                      style: TextStyle(
                        fontSize: _kBodyTextSize,
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

  Widget _cardDivider() => Builder(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final dark = scheme.brightness == Brightness.dark;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 1,
        color: (dark ? Colors.white : scheme.onSurface).withValues(
          alpha: dark ? 0.12 : 0.12,
        ),
      );
    },
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: (dark ? const Color(0xFF0D121A) : scheme.surfaceContainerLow)
            .withValues(alpha: dark ? 0.78 : 0.92),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.14 : 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: _kCardTitleSize,
                fontWeight: FontWeight.w700,
                color: fg.withValues(alpha: dark ? 0.95 : 0.94),
              ),
            ),
          ),
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: _kMutedTextSize,
                  color: fg.withValues(alpha: dark ? 0.52 : 0.60),
                ),
              ),
            ),
          ],
          Container(height: 1, color: fg.withValues(alpha: dark ? 0.14 : 0.10)),
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
    this.disabled = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    fontWeight: FontWeight.w500,
                    color: disabled
                        ? fg.withValues(alpha: dark ? 0.42 : 0.42)
                        : fg.withValues(alpha: dark ? 0.95 : 0.94),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: _kMutedTextSize,
                      color: disabled
                          ? fg.withValues(alpha: dark ? 0.32 : 0.38)
                          : fg.withValues(alpha: dark ? 0.56 : 0.62),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: disabled ? null : onChanged,
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

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String? label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final showLabel = (label ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabel) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: _kMutedTextSize,
                color: fg.withValues(alpha: dark ? 0.78 : 0.7),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: 66,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              side: BorderSide(color: fg.withValues(alpha: dark ? 0.18 : 0.14)),
              backgroundColor:
                  (dark ? Colors.white : scheme.surfaceContainerHighest)
                      .withValues(alpha: dark ? 0.04 : 0.86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: _kBodyTextSize,
                      color: fg.withValues(alpha: dark ? 0.9 : 0.86),
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  size: 30 * 0.65,
                  color: fg.withValues(alpha: dark ? 0.66 : 0.56),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationSettingsState {
  const _NotificationSettingsState({
    required this.soundEnabled,
    required this.showPreview,
    required this.muteAll,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.quietHoursTimeZone,
  });

  final bool soundEnabled;
  final bool showPreview;
  final bool muteAll;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String quietHoursTimeZone;

  factory _NotificationSettingsState.defaults({required String tz}) {
    return _NotificationSettingsState(
      soundEnabled: true,
      showPreview: true,
      muteAll: false,
      quietHoursEnabled: false,
      quietHoursStart: '23:00',
      quietHoursEnd: '07:00',
      quietHoursTimeZone: tz,
    );
  }

  factory _NotificationSettingsState.fromRaw(Map<String, Object?> raw) {
    final tz = _resolveTimeZone(raw['quietHoursTimeZone'] as String?);
    String normalizeHm(Object? v, String fallback) {
      if (v is! String) return fallback;
      final s = v.trim();
      final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
      return m == null ? fallback : s;
    }

    return _NotificationSettingsState(
      soundEnabled: raw['soundEnabled'] != false,
      showPreview: raw['showPreview'] != false,
      muteAll: raw['muteAll'] == true,
      quietHoursEnabled: raw['quietHoursEnabled'] == true,
      quietHoursStart: normalizeHm(raw['quietHoursStart'], '23:00'),
      quietHoursEnd: normalizeHm(raw['quietHoursEnd'], '07:00'),
      quietHoursTimeZone: tz,
    );
  }

  _NotificationSettingsState copyWith({
    bool? soundEnabled,
    bool? showPreview,
    bool? muteAll,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? quietHoursTimeZone,
  }) {
    return _NotificationSettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showPreview: showPreview ?? this.showPreview,
      muteAll: muteAll ?? this.muteAll,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursTimeZone: quietHoursTimeZone ?? this.quietHoursTimeZone,
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'soundEnabled': soundEnabled,
    'showPreview': showPreview,
    'muteAll': muteAll,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'quietHoursTimeZone': quietHoursTimeZone,
  };
}

TimeOfDay _parseTimeOfDay(String hm, {required TimeOfDay fallback}) {
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(hm.trim());
  if (m == null) return fallback;
  final h = int.tryParse(m.group(1)!);
  final min = int.tryParse(m.group(2)!);
  if (h == null || min == null) return fallback;
  return TimeOfDay(hour: h, minute: min);
}

String _resolveTimeZone(String? raw) {
  final v = (raw ?? '').trim();
  if (v.contains('/')) return v;
  final off = DateTime.now().timeZoneOffset;
  if (off.inMinutes == 0) return 'UTC';
  if (off.inMinutes % 60 == 0) {
    final h = off.inHours;
    final sign = h > 0 ? '-' : '+';
    return 'Etc/GMT$sign${h.abs()}';
  }
  return 'UTC';
}
