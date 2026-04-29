import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/secret_chat_callables.dart';
import 'secret_chat_ttl_sheet.dart';
import 'chat_shell_backdrop.dart';
import 'notification_settings_ui.dart';

/// Просмотр неизменяемых настроек секретного чата и удаление для себя (Cloud Function).
class SecretChatSettingsScreen extends ConsumerStatefulWidget {
  const SecretChatSettingsScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<SecretChatSettingsScreen> createState() =>
      _SecretChatSettingsScreenState();
}

class _SecretChatSettingsScreenState extends ConsumerState<SecretChatSettingsScreen> {
  final _callables = SecretChatCallables();
  bool _busy = false;
  late DateTime _now;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _ttlLabel(AppLocalizations l10n, int sec) =>
      SecretChatTtlSheet.presetLabel(l10n, sec);

  DateTime? _parseIso(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t)?.toLocal();
  }

  String _formatLocalDateTime(BuildContext context, DateTime dt) {
    final m = MaterialLocalizations.of(context);
    final date = m.formatFullDate(dt);
    final time = m.formatTimeOfDay(TimeOfDay.fromDateTime(dt));
    return '$date, $time';
  }

  String _formatDurationCompact(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return '00:00:00';
    final totalHours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(totalHours)}:${two(minutes)}:${two(seconds)}';
  }

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.secret_chat_settings_delete_confirm_title),
        content: Text(l10n.secret_chat_settings_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _callables.deleteSecretChat(conversationId: widget.conversationId);
      if (!mounted) return;
      context.go('/chats');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final convAsync = ref.watch(conversationsProvider((
      key: conversationIdsCacheKey([widget.conversationId]),
    )));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            child: convAsync.when(
              data: (list) {
                final conv = list.isNotEmpty ? list.first.data : null;
                final cfg = conv?.secretChat;
                if (cfg == null || cfg.enabled != true) {
                  return Center(child: Text(l10n.secret_chat_settings_not_secret));
                }

                final r = cfg.restrictions;
                final media = cfg.mediaViewPolicy;
                final expiresLocal = _parseIso(cfg.expiresAt);
                final expiresText = expiresLocal == null
                    ? cfg.expiresAt
                    : _formatLocalDateTime(context, expiresLocal);
                final timeLeft = expiresLocal == null
                    ? null
                    : _formatDurationCompact(expiresLocal.difference(_now));

                String mediaSummaryLines() {
                  if (media == null) return l10n.secret_chat_media_views_unlimited;
                  final parts = <String>[];
                  void line(String label, int? v) {
                    parts.add(
                      '$label: ${v == null ? l10n.secret_chat_media_views_unlimited : l10n.secret_chat_media_views_count(v)}',
                    );
                  }

                  line(l10n.secret_chat_media_type_image, media.image);
                  line(l10n.secret_chat_media_type_video, media.video);
                  line(l10n.secret_chat_media_type_voice, media.voice);
                  line(l10n.secret_chat_media_type_file, media.file);
                  line(l10n.secret_chat_media_type_location, media.location);
                  return parts.join('\n');
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    NotificationSettingsPageHeader(
                      title: l10n.secret_chat_settings_title,
                      leadingIcon: Icons.lock_clock_rounded,
                      iconColor: const Color(0xFF4DA2FF),
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingsMutedBanner(
                      text: l10n.secret_chat_settings_read_only_hint,
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingsCard(
                      title: l10n.secret_chat_settings_ttl,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Text(
                            _ttlLabel(l10n, cfg.ttlPresetSec),
                            style: const TextStyle(
                              fontSize: kNotificationSettingsBodyTextSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (timeLeft != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Text(
                              l10n.secret_chat_settings_time_left(timeLeft),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Text(
                            l10n.secret_chat_settings_expires_at(expiresText),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingsCard(
                      title: l10n.secret_chat_settings_subtitle,
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(l10n.secret_chat_settings_no_forward),
                          trailing: Text(r.noForward ? '✓' : '—'),
                        ),
                        ListTile(
                          dense: true,
                          title: Text(l10n.secret_chat_settings_no_copy),
                          trailing: Text(r.noCopy ? '✓' : '—'),
                        ),
                        ListTile(
                          dense: true,
                          title: Text(l10n.secret_chat_settings_no_save),
                          trailing: Text(r.noSave ? '✓' : '—'),
                        ),
                        ListTile(
                          dense: true,
                          title: Text(l10n.secret_chat_settings_screenshot_protection),
                          trailing: Text(r.screenshotProtection ? '✓' : '—'),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingsCard(
                      title: l10n.secret_chat_compose_require_unlock_pin,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Text(
                            cfg.lockPolicy.required ? '✓' : '—',
                            style: const TextStyle(
                              fontSize: kNotificationSettingsBodyTextSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingsCard(
                      title: l10n.secret_chat_settings_media_views,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Text(
                            mediaSummaryLines(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB5AF),
                        foregroundColor: const Color(0xFF4A1D1B),
                      ),
                      onPressed: _busy ? null : () => unawaited(_confirmDelete(l10n)),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      label: Text(l10n.secret_chat_settings_delete),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.secret_chat_settings_load_failed(e.toString())),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
