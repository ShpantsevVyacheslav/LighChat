import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/ringtone_presets.dart';
import '../../auth/ui/auth_glass.dart';
import 'notification_settings_ui.dart';
import '../../../l10n/app_localizations.dart';

class ChatNotificationsScreen extends ConsumerWidget {
  const ChatNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                Object? messageRingtoneId = _kSentinel,
                Object? callRingtoneId = _kSentinel,
                bool? meetingHandRaiseSoundEnabled,
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
                        messageRingtoneId: messageRingtoneId,
                        callRingtoneId: callRingtoneId,
                        meetingHandRaiseSoundEnabled:
                            meetingHandRaiseSoundEnabled,
                      );
                try {
                  await repo.patchUserDoc(user.uid, <String, Object?>{
                    'notificationSettings': next.toFirestoreMap(),
                  });
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.notifications_error_cannot_save(e.toString()),
                      ),
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

              Future<void> openRingtonePicker({required bool forCalls}) async {
                final picked = await showModalBottomSheet<String?>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (sheetCtx) => _RingtonePickerSheet(
                    forCalls: forCalls,
                    currentId: forCalls
                        ? settings.callRingtoneId
                        : settings.messageRingtoneId,
                  ),
                );
                if (picked == null) return; // отмена
                // sentinel '' означает «вернуть к умолчанию» (null в Firestore)
                final value = picked.isEmpty ? null : picked;
                if (forCalls) {
                  await savePatch(callRingtoneId: value);
                } else {
                  await savePatch(messageRingtoneId: value);
                }
              }

              return _NotificationsView(
                settings: settings,
                onMuteAllChanged: (v) => savePatch(muteAll: v),
                onSoundChanged: (v) => savePatch(soundEnabled: v),
                onPreviewChanged: (v) => savePatch(showPreview: v),
                onQuietHoursChanged: (v) => savePatch(quietHoursEnabled: v),
                onPickQuietHoursStart: () => pickTime(true),
                onPickQuietHoursEnd: () => pickTime(false),
                onPickMessageRingtone: () =>
                    openRingtonePicker(forCalls: false),
                onPickCallRingtone: () => openRingtonePicker(forCalls: true),
                onHandRaiseSoundChanged: (v) =>
                    savePatch(meetingHandRaiseSoundEnabled: v),
                onReset: () => savePatch(reset: true),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.notifications_error_load(e.toString())),
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
    required this.onPickMessageRingtone,
    required this.onPickCallRingtone,
    required this.onHandRaiseSoundChanged,
    required this.onReset,
  });

  final _NotificationSettingsState settings;
  final ValueChanged<bool> onMuteAllChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onPreviewChanged;
  final ValueChanged<bool> onQuietHoursChanged;
  final VoidCallback onPickQuietHoursStart;
  final VoidCallback onPickQuietHoursEnd;
  final VoidCallback onPickMessageRingtone;
  final VoidCallback onPickCallRingtone;
  final ValueChanged<bool> onHandRaiseSoundChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        NotificationSettingsPageHeader(title: l10n.notifications_title),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                const SizedBox(height: 10),
                NotificationSettingsCard(
                  title: l10n.notifications_section_main,
                  children: [
                    NotificationSettingsSwitchRow(
                      title: l10n.notifications_mute_all_title,
                      subtitle: l10n.notifications_mute_all_subtitle,
                      value: settings.muteAll,
                      onChanged: onMuteAllChanged,
                    ),
                    const SizedBox(height: 4),
                    NotificationSettingsSwitchRow(
                      title: l10n.notifications_sound_title,
                      subtitle: l10n.notifications_sound_subtitle,
                      value: settings.soundEnabled,
                      onChanged: onSoundChanged,
                      disabled: settings.muteAll,
                    ),
                    const SizedBox(height: 4),
                    NotificationSettingsSwitchRow(
                      title: l10n.notifications_preview_title,
                      subtitle: l10n.notifications_preview_subtitle,
                      value: settings.showPreview,
                      onChanged: onPreviewChanged,
                      disabled: settings.muteAll,
                    ),
                    const SizedBox(height: 4),
                    _RingtoneRow(
                      title: l10n.notifications_message_ringtone_label,
                      currentId: settings.messageRingtoneId,
                      fallbackId: kDefaultMessageRingtoneId,
                      onTap: onPickMessageRingtone,
                      disabled: settings.muteAll || !settings.soundEnabled,
                    ),
                    const SizedBox(height: 4),
                    _RingtoneRow(
                      title: l10n.notifications_call_ringtone_label,
                      currentId: settings.callRingtoneId,
                      fallbackId: null,
                      onTap: onPickCallRingtone,
                      disabled: settings.muteAll || !settings.soundEnabled,
                    ),
                    const SizedBox(height: 4),
                    NotificationSettingsSwitchRow(
                      title: l10n.notifications_meeting_hand_raise_title,
                      subtitle: l10n.notifications_meeting_hand_raise_subtitle,
                      value: settings.meetingHandRaiseSoundEnabled,
                      onChanged: onHandRaiseSoundChanged,
                      disabled: settings.muteAll,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(height: 14),
                NotificationSettingsCard(
                  title: l10n.notifications_section_quiet_hours,
                  subtitle: l10n.notifications_quiet_hours_subtitle,
                  children: [
                    NotificationSettingsSwitchRow(
                      title: l10n.notifications_quiet_hours_enable_title,
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
                                fontSize: kNotificationSettingsCardTitleSize,
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
                      const SizedBox(height: 10),
                    ],
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
                      l10n.notifications_reset_button,
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
                fontSize: kNotificationSettingsMutedTextSize,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: fg.withValues(alpha: dark ? 0.18 : 0.14)),
              backgroundColor:
                  (dark ? Colors.white : scheme.surfaceContainerHighest)
                      .withValues(alpha: dark ? 0.04 : 0.86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: kNotificationSettingsBodyTextSize,
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
    required this.messageRingtoneId,
    required this.callRingtoneId,
    required this.meetingHandRaiseSoundEnabled,
  });

  final bool soundEnabled;
  final bool showPreview;
  final bool muteAll;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String quietHoursTimeZone;
  final String? messageRingtoneId;
  final String? callRingtoneId;
  final bool meetingHandRaiseSoundEnabled;

  factory _NotificationSettingsState.defaults({required String tz}) {
    return _NotificationSettingsState(
      soundEnabled: true,
      showPreview: true,
      muteAll: false,
      quietHoursEnabled: false,
      quietHoursStart: '23:00',
      quietHoursEnd: '07:00',
      quietHoursTimeZone: tz,
      messageRingtoneId: null,
      callRingtoneId: null,
      meetingHandRaiseSoundEnabled: true,
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

    String? normalizeRingtone(Object? v) {
      if (v is! String) return null;
      final s = v.trim();
      return s.isEmpty ? null : s;
    }

    return _NotificationSettingsState(
      soundEnabled: raw['soundEnabled'] != false,
      showPreview: raw['showPreview'] != false,
      muteAll: raw['muteAll'] == true,
      quietHoursEnabled: raw['quietHoursEnabled'] == true,
      quietHoursStart: normalizeHm(raw['quietHoursStart'], '23:00'),
      quietHoursEnd: normalizeHm(raw['quietHoursEnd'], '07:00'),
      quietHoursTimeZone: tz,
      messageRingtoneId: normalizeRingtone(raw['messageRingtoneId']),
      callRingtoneId: normalizeRingtone(raw['callRingtoneId']),
      meetingHandRaiseSoundEnabled:
          raw['meetingHandRaiseSoundEnabled'] != false,
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
    Object? messageRingtoneId = _kSentinel,
    Object? callRingtoneId = _kSentinel,
    bool? meetingHandRaiseSoundEnabled,
  }) {
    return _NotificationSettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showPreview: showPreview ?? this.showPreview,
      muteAll: muteAll ?? this.muteAll,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursTimeZone: quietHoursTimeZone ?? this.quietHoursTimeZone,
      messageRingtoneId: identical(messageRingtoneId, _kSentinel)
          ? this.messageRingtoneId
          : messageRingtoneId as String?,
      callRingtoneId: identical(callRingtoneId, _kSentinel)
          ? this.callRingtoneId
          : callRingtoneId as String?,
      meetingHandRaiseSoundEnabled:
          meetingHandRaiseSoundEnabled ?? this.meetingHandRaiseSoundEnabled,
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
    'messageRingtoneId': messageRingtoneId,
    'callRingtoneId': callRingtoneId,
    'meetingHandRaiseSoundEnabled': meetingHandRaiseSoundEnabled,
  };
}

const Object _kSentinel = Object();

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

String _ringtoneLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'classic_chime':
      return l10n.ringtone_classic_chime;
    case 'gentle_bells':
      return l10n.ringtone_gentle_bells;
    case 'marimba_tap':
      return l10n.ringtone_marimba_tap;
    case 'soft_pulse':
      return l10n.ringtone_soft_pulse;
    case 'ascending_chord':
      return l10n.ringtone_ascending_chord;
    default:
      return id;
  }
}

class _RingtoneRow extends StatelessWidget {
  const _RingtoneRow({
    required this.title,
    required this.currentId,
    required this.fallbackId,
    required this.onTap,
    required this.disabled,
  });

  final String title;
  final String? currentId;
  final String? fallbackId;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final displayId = currentId ?? fallbackId;
    final displayName = displayId == null
        ? l10n.ringtone_default
        : _ringtoneLabel(l10n, displayId);
    final muted = disabled ? 0.5 : 1.0;
    return Opacity(
      opacity: muted,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: kNotificationSettingsBodyTextSize,
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: kNotificationSettingsMutedTextSize,
                        color: fg.withValues(alpha: dark ? 0.72 : 0.64),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: fg.withValues(alpha: dark ? 0.6 : 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingtonePickerSheet extends StatefulWidget {
  const _RingtonePickerSheet({
    required this.forCalls,
    required this.currentId,
  });

  final bool forCalls;
  final String? currentId;

  @override
  State<_RingtonePickerSheet> createState() => _RingtonePickerSheetState();
}

class _RingtonePickerSheetState extends State<_RingtonePickerSheet> {
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _previewingId;

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _preview(RingtonePreset preset) async {
    try {
      if (_previewingId != preset.id) {
        await _previewPlayer.setAsset(preset.assetPath);
        setState(() => _previewingId = preset.id);
      }
      await _previewPlayer.seek(Duration.zero);
      await _previewPlayer.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = widget.forCalls
        ? l10n.ringtone_picker_calls_title
        : l10n.ringtone_picker_messages_title;
    final selectedId = widget.currentId;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Дефолт-опция: "По умолчанию" — пустая строка как возвращаемое значение.
            _PickerTile(
              label: l10n.ringtone_default,
              selected: selectedId == null,
              onTap: () => Navigator.of(context).pop(''),
              previewing: false,
              onPreview: null,
            ),
            for (final p in kRingtonePresets)
              _PickerTile(
                label: _ringtoneLabel(l10n, p.id),
                selected: selectedId == p.id,
                onTap: () => Navigator.of(context).pop(p.id),
                previewing: _previewingId == p.id && _previewPlayer.playing,
                onPreview: () => _preview(p),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.previewing,
    required this.onPreview,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool previewing;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (onPreview != null)
              IconButton(
                onPressed: onPreview,
                tooltip: l10n.ringtone_preview_play,
                icon: Icon(
                  previewing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  size: 26,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
