import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/secret_chat_settings_repository.dart';
import 'secret_chat_ttl_sheet.dart';

class SecretChatSettingsScreen extends ConsumerStatefulWidget {
  const SecretChatSettingsScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<SecretChatSettingsScreen> createState() => _SecretChatSettingsScreenState();
}

class _SecretChatSettingsScreenState extends ConsumerState<SecretChatSettingsScreen> {
  final _repo = SecretChatSettingsRepository();
  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _withBusy(Future<void> Function() op) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await op();
    } catch (e) {
      _toast(l10n.secret_chat_settings_save_failed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _ttlLabel(AppLocalizations l10n, int sec) {
    if (sec < 3600) return l10n.disappearing_ttl_minutes((sec / 60).round());
    if (sec < 86400) return l10n.disappearing_ttl_hours((sec / 3600).round());
    return l10n.disappearing_ttl_days((sec / 86400).round());
  }

  String _viewsLabel(AppLocalizations l10n, int? v) {
    if (v == null) return l10n.secret_chat_media_views_unlimited;
    return l10n.secret_chat_media_views_count(v);
  }

  Widget _viewsPicker({
    required AppLocalizations l10n,
    required String title,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final items = <int?>[null, 1, 2, 3, 5, 10];
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<int?>(
        value: items.contains(value) ? value : null,
        items: [
          for (final v in items)
            DropdownMenuItem<int?>(
              value: v,
              child: Text(_viewsLabel(l10n, v)),
            ),
        ],
        onChanged: _busy ? null : onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: convAsync.when(
        data: (list) {
          final conv = list.isNotEmpty ? list.first.data : null;
          final cfg = conv?.secretChat;
          if (cfg == null || cfg.enabled != true) {
            return Center(child: Text(l10n.secret_chat_settings_not_secret));
          }

          final restrictions = cfg.restrictions;
          final media = cfg.mediaViewPolicy ?? const SecretChatMediaViewPolicy();
          final grantTtl = cfg.lockPolicy.grantTtlSec;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Card(
                child: ListTile(
                  title: Text(l10n.secret_chat_settings_reset_strict),
                  subtitle: Text(l10n.secret_chat_settings_reset_strict_subtitle),
                  trailing: const Icon(Icons.restart_alt_rounded),
                  onTap: _busy
                      ? null
                      : () => unawaited(_withBusy(() => _repo.resetToStrictDefaults(
                            conversationId: widget.conversationId,
                          ))),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: Text(l10n.secret_chat_settings_ttl),
                  subtitle: Text(l10n.secret_chat_settings_expires_at(cfg.expiresAt)),
                  trailing: Text(_ttlLabel(l10n, cfg.ttlPresetSec)),
                  onTap: _busy
                      ? null
                      : () async {
                          final ttlSec = await showModalBottomSheet<int>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            barrierColor: Colors.black.withValues(alpha: 0.55),
                            showDragHandle: true,
                            builder: (_) => SecretChatTtlSheet(initialSec: cfg.ttlPresetSec),
                          );
                          if (ttlSec == null) return;
                          await _withBusy(() => _repo.updateTtlPreset(
                                conversationId: widget.conversationId,
                                ttlPresetSec: ttlSec,
                              ));
                        },
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.secret_chat_settings_unlock_grant_ttl),
                      subtitle: Text(l10n.secret_chat_settings_unlock_grant_ttl_subtitle),
                      trailing: DropdownButton<int>(
                        value: grantTtl,
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v == null) return;
                                unawaited(_withBusy(() => _repo.updateGrantTtlSec(
                                      conversationId: widget.conversationId,
                                      grantTtlSec: v,
                                    )));
                              },
                        items: const [
                          DropdownMenuItem(value: 300, child: Text('5m')),
                          DropdownMenuItem(value: 600, child: Text('10m')),
                          DropdownMenuItem(value: 900, child: Text('15m')),
                          DropdownMenuItem(value: 1800, child: Text('30m')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.secret_chat_settings_no_copy),
                      value: restrictions.noCopy,
                      onChanged: _busy
                          ? null
                          : (v) => unawaited(_withBusy(() => _repo.updateRestrictions(
                                conversationId: widget.conversationId,
                                restrictions: SecretChatRestrictions(
                                  noForward: restrictions.noForward,
                                  noCopy: v,
                                  noSave: restrictions.noSave,
                                  screenshotProtection: restrictions.screenshotProtection,
                                ),
                              ))),
                    ),
                    SwitchListTile(
                      title: Text(l10n.secret_chat_settings_no_forward),
                      value: restrictions.noForward,
                      onChanged: _busy
                          ? null
                          : (v) => unawaited(_withBusy(() => _repo.updateRestrictions(
                                conversationId: widget.conversationId,
                                restrictions: SecretChatRestrictions(
                                  noForward: v,
                                  noCopy: restrictions.noCopy,
                                  noSave: restrictions.noSave,
                                  screenshotProtection: restrictions.screenshotProtection,
                                ),
                              ))),
                    ),
                    SwitchListTile(
                      title: Text(l10n.secret_chat_settings_no_save),
                      value: restrictions.noSave,
                      onChanged: _busy
                          ? null
                          : (v) => unawaited(_withBusy(() => _repo.updateRestrictions(
                                conversationId: widget.conversationId,
                                restrictions: SecretChatRestrictions(
                                  noForward: restrictions.noForward,
                                  noCopy: restrictions.noCopy,
                                  noSave: v,
                                  screenshotProtection: restrictions.screenshotProtection,
                                ),
                              ))),
                    ),
                    SwitchListTile(
                      title: Text(l10n.secret_chat_settings_screenshot_protection),
                      value: restrictions.screenshotProtection,
                      onChanged: _busy
                          ? null
                          : (v) => unawaited(_withBusy(() => _repo.updateRestrictions(
                                conversationId: widget.conversationId,
                                restrictions: SecretChatRestrictions(
                                  noForward: restrictions.noForward,
                                  noCopy: restrictions.noCopy,
                                  noSave: restrictions.noSave,
                                  screenshotProtection: v,
                                ),
                              ))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.secret_chat_settings_media_views),
                      subtitle: Text(l10n.secret_chat_settings_media_views_subtitle),
                    ),
                    _viewsPicker(
                      l10n: l10n,
                      title: l10n.secret_chat_media_type_image,
                      value: media.image,
                      onChanged: (v) => unawaited(_withBusy(() => _repo.updateMediaViewPolicy(
                            conversationId: widget.conversationId,
                            policy: SecretChatMediaViewPolicy(
                              image: v,
                              video: media.video,
                              voice: media.voice,
                              file: media.file,
                              location: media.location,
                            ),
                          ))),
                    ),
                    _viewsPicker(
                      l10n: l10n,
                      title: l10n.secret_chat_media_type_video,
                      value: media.video,
                      onChanged: (v) => unawaited(_withBusy(() => _repo.updateMediaViewPolicy(
                            conversationId: widget.conversationId,
                            policy: SecretChatMediaViewPolicy(
                              image: media.image,
                              video: v,
                              voice: media.voice,
                              file: media.file,
                              location: media.location,
                            ),
                          ))),
                    ),
                    _viewsPicker(
                      l10n: l10n,
                      title: l10n.secret_chat_media_type_voice,
                      value: media.voice,
                      onChanged: (v) => unawaited(_withBusy(() => _repo.updateMediaViewPolicy(
                            conversationId: widget.conversationId,
                            policy: SecretChatMediaViewPolicy(
                              image: media.image,
                              video: media.video,
                              voice: v,
                              file: media.file,
                              location: media.location,
                            ),
                          ))),
                    ),
                    _viewsPicker(
                      l10n: l10n,
                      title: l10n.secret_chat_media_type_location,
                      value: media.location,
                      onChanged: (v) => unawaited(_withBusy(() => _repo.updateMediaViewPolicy(
                            conversationId: widget.conversationId,
                            policy: SecretChatMediaViewPolicy(
                              image: media.image,
                              video: media.video,
                              voice: media.voice,
                              file: media.file,
                              location: v,
                            ),
                          ))),
                    ),
                  ],
                ),
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

