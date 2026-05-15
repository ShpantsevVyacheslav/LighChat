import 'dart:async';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
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
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black.withValues(alpha: 0.62),
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
                    const SizedBox(height: 8),
                    _RingtoneRow(
                      title: l10n.notifications_message_ringtone_label,
                      currentId: settings.messageRingtoneId,
                      fallbackId: kDefaultMessageRingtoneId,
                      onTap: onPickMessageRingtone,
                      disabled: settings.muteAll || !settings.soundEnabled,
                    ),
                    _RingtoneRow(
                      title: l10n.notifications_call_ringtone_label,
                      currentId: settings.callRingtoneId,
                      fallbackId: null,
                      onTap: onPickCallRingtone,
                      disabled: settings.muteAll || !settings.soundEnabled,
                    ),
                    const SizedBox(height: 12),
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
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TimeButton(
                                label: null,
                                value: settings.quietHoursStart,
                                onTap: onPickQuietHoursStart,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '—',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      (dark ? Colors.white : scheme.onSurface)
                                          .withValues(alpha: dark ? 0.62 : 0.52),
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
                      ),
                      const SizedBox(height: 14),
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
          height: 48,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              side: BorderSide(color: fg.withValues(alpha: dark ? 0.16 : 0.12)),
              backgroundColor:
                  (dark ? Colors.white : scheme.surfaceContainerHighest)
                      .withValues(alpha: dark ? 0.04 : 0.86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
    case kStorageRingtoneId:
      return l10n.ringtone_storage_original;
    default:
      return id;
  }
}

/// Премиум-цвет акцента в пикере. Тот же оттенок что и у Switch.activeTrackColor
/// (см. notification_settings_ui.dart) — но в пикере используется как мягкий
/// глоу/свечение, а не плоская заливка.
const Color _kAccent = Color(0xFF4DA2FF);

/// Строка выбора рингтона внутри карточки настроек. Выравнена по тем же
/// горизонтальным паддингам что и [NotificationSettingsSwitchRow] — 20 px.
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
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Padding(
            // 20px горизонтальный паддинг = совпадает со switch-строками выше.
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                          color: fg.withValues(alpha: dark ? 0.95 : 0.94),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: kNotificationSettingsMutedTextSize,
                          color: fg.withValues(alpha: dark ? 0.56 : 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: fg.withValues(alpha: dark ? 0.5 : 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кастомный bottom-sheet выбора рингтона — премиум-look без Material radios:
/// glassmorphism, мягкий градиент-фон, индикатор-точка с глоу.
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

class _RingtonePickerSheetState extends State<_RingtonePickerSheet>
    with TickerProviderStateMixin {
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _previewingId;
  String? _storageUrlCache;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _previewPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed ||
          !state.playing) {
        if (_previewingId != null) {
          setState(() => _previewingId = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  RingtoneVariant get _variant =>
      widget.forCalls ? RingtoneVariant.calls : RingtoneVariant.messages;

  Future<void> _togglePreview(RingtonePreset preset) async {
    try {
      if (_previewingId == preset.id) {
        await _previewPlayer.pause();
        setState(() => _previewingId = null);
        return;
      }
      await _previewPlayer.stop();
      await _previewPlayer.setAsset(preset.assetPath(_variant));
      setState(() => _previewingId = preset.id);
      await _previewPlayer.seek(Duration.zero);
      await _previewPlayer.play();
    } catch (_) {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  Future<void> _toggleStoragePreview() async {
    try {
      if (_previewingId == kStorageRingtoneId) {
        await _previewPlayer.pause();
        setState(() => _previewingId = null);
        return;
      }
      await _previewPlayer.stop();
      final url = _storageUrlCache ??
          await FirebaseStorage.instance.ref('audio/ringtone.mp3').getDownloadURL();
      _storageUrlCache = url;
      await _previewPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
      setState(() => _previewingId = kStorageRingtoneId);
      await _previewPlayer.seek(Duration.zero);
      await _previewPlayer.play();
    } catch (_) {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final title = widget.forCalls
        ? l10n.ringtone_picker_calls_title
        : l10n.ringtone_picker_messages_title;
    final selectedId = widget.currentId;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 12 + mq.viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF161B26),
                  Color(0xFF0B0F18),
                ],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Drag handle.
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PremiumPickerTile(
                          label: l10n.ringtone_default,
                          selected: selectedId == null,
                          onTap: () => Navigator.of(context).pop(''),
                          onTogglePreview: null,
                          previewing: false,
                        ),
                        if (widget.forCalls)
                          _PremiumPickerTile(
                            label: l10n.ringtone_storage_original,
                            selected: selectedId == kStorageRingtoneId,
                            onTap: () =>
                                Navigator.of(context).pop(kStorageRingtoneId),
                            onTogglePreview: _toggleStoragePreview,
                            previewing: _previewingId == kStorageRingtoneId,
                          ),
                        for (final p in kRingtonePresets)
                          _PremiumPickerTile(
                            label: _ringtoneLabel(l10n, p.id),
                            selected: selectedId == p.id,
                            onTap: () => Navigator.of(context).pop(p.id),
                            onTogglePreview: () => _togglePreview(p),
                            previewing: _previewingId == p.id,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кастомная плитка пикера с анимированным акцент-индикатором и play-кнопкой.
class _PremiumPickerTile extends StatelessWidget {
  const _PremiumPickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onTogglePreview,
    required this.previewing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onTogglePreview;
  final bool previewing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kAccent.withValues(alpha: 0.18),
                    _kAccent.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? _kAccent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.06),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kAccent.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  _SelectionDot(selected: selected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: Colors.white.withValues(
                          alpha: selected ? 0.98 : 0.86,
                        ),
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (onTogglePreview != null)
                    _PreviewButton(
                      playing: previewing,
                      onPressed: onTogglePreview!,
                      semanticLabel: l10n.ringtone_preview_play,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? _kAccent.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.32),
                width: 1.6,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: -1,
                      ),
                    ]
                  : null,
            ),
          ),
          AnimatedScale(
            scale: selected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7BC1FF), _kAccent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.playing,
    required this.onPressed,
    required this.semanticLabel,
  });

  final bool playing;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: playing
                  ? _kAccent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: playing
                    ? _kAccent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: playing ? _kAccent : Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}
