import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/secret_chat_callables.dart';
import 'secret_chat_ttl_sheet.dart';

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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _ttlLabel(AppLocalizations l10n, int sec) =>
      SecretChatTtlSheet.presetLabel(l10n, sec);

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
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.secret_chat_settings_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final convAsync = ref.watch(conversationsProvider((
      key: conversationIdsCacheKey([widget.conversationId]),
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.secret_chat_settings_title),
      ),
      body: convAsync.when(
        data: (list) {
          final conv = list.isNotEmpty ? list.first.data : null;
          final cfg = conv?.secretChat;
          if (cfg == null || cfg.enabled != true) {
            return Center(child: Text(l10n.secret_chat_settings_not_secret));
          }

          final r = cfg.restrictions;
          final media = cfg.mediaViewPolicy;

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.secret_chat_settings_read_only_hint,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.secret_chat_settings_ttl, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_ttlLabel(l10n, cfg.ttlPresetSec)),
                      const SizedBox(height: 6),
                      Text(
                        l10n.secret_chat_settings_expires_at(cfg.expiresAt),
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.secret_chat_settings_no_forward),
                      trailing: Text(r.noForward ? '✓' : '—'),
                    ),
                    ListTile(
                      title: Text(l10n.secret_chat_settings_no_copy),
                      trailing: Text(r.noCopy ? '✓' : '—'),
                    ),
                    ListTile(
                      title: Text(l10n.secret_chat_settings_no_save),
                      trailing: Text(r.noSave ? '✓' : '—'),
                    ),
                    ListTile(
                      title: Text(l10n.secret_chat_settings_screenshot_protection),
                      trailing: Text(r.screenshotProtection ? '✓' : '—'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.secret_chat_compose_require_unlock_pin,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(cfg.lockPolicy.required ? '✓' : '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.secret_chat_settings_media_views,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mediaSummaryLines(),
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
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
    );
  }
}
