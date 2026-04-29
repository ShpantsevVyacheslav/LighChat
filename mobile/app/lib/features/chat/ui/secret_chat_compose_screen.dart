import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/secret_chat_callables.dart';
import '../data/secret_chat_create.dart';
import '../data/secret_chat_pin_device_storage.dart';
import '../data/user_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_shell_backdrop.dart';
import 'notification_settings_ui.dart';
import 'secret_chat_ttl_sheet.dart';
import 'secret_vault_pin_screen.dart';

/// Routed via [GoRouter] `extra` from «новый секретный чат» flows.
class SecretChatComposeArgs {
  const SecretChatComposeArgs({required this.me, required this.peer});

  final UserProfile me;
  final UserProfile peer;
}

class SecretChatComposeScreen extends ConsumerStatefulWidget {
  const SecretChatComposeScreen({super.key, required this.args});

  final SecretChatComposeArgs args;

  @override
  ConsumerState<SecretChatComposeScreen> createState() =>
      _SecretChatComposeScreenState();
}

class _SecretChatComposeScreenState extends ConsumerState<SecretChatComposeScreen> {
  int _ttlSec = 3600;
  bool _noForward = true;
  bool _noCopy = true;
  bool _noSave = true;
  bool _screenshotProtection = true;
  bool _lockRequired = false;
  String? _vaultPin;
  int? _imageViews;
  int? _videoViews;
  int? _voiceViews;
  int? _fileViews;
  int? _locationViews;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final pin = (_vaultPin ?? '').trim();
    if (pin.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_pin_invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final me = widget.args.me;
    final peer = widget.args.peer;
    try {
      final convId = await createOrOpenSecretDirectChat(
        firestore: FirebaseFirestore.instance,
        currentUserId: uid,
        otherUserId: peer.id,
        currentUserInfo: (
          name: me.name,
          avatar: me.avatar,
          avatarThumb: me.avatarThumb,
        ),
        otherUserInfo: (
          name: peer.name,
          avatar: peer.avatar,
          avatarThumb: peer.avatarThumb,
        ),
        ttlPresetSec: _ttlSec,
        restrictions: SecretChatRestrictions(
          noForward: _noForward,
          noCopy: _noCopy,
          noSave: _noSave,
          screenshotProtection: _screenshotProtection,
        ),
        lockRequired: _lockRequired,
        mediaViewPolicy: SecretChatMediaViewPolicy(
          image: _imageViews,
          video: _videoViews,
          voice: _voiceViews,
          file: _fileViews,
          location: _locationViews,
        ),
      );
      if (pin.length == 4) {
        await SecretChatCallables().setPin(pin: pin);
        await const SecretChatPinDeviceStorage().saveVaultPin(pin);
      }
      if (!mounted) return;
      context.go('/chats/$convId');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final peer = widget.args.peer;

    Widget mediaLimitRow({
      required String title,
      required int? value,
      required ValueChanged<int?> onChanged,
    }) {
      const opts = <int?>[null, 1, 2, 3, 5, 10];
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: kNotificationSettingsBodyTextSize,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            DropdownButton<int?>(
              value: opts.contains(value) ? value : null,
              dropdownColor: const Color(0xFF101926),
              borderRadius: BorderRadius.circular(12),
              underline: const SizedBox.shrink(),
              items: [
                for (final v in opts)
                  DropdownMenuItem<int?>(
                    value: v,
                    child: Text(
                      v == null
                          ? l10n.secret_chat_media_views_unlimited
                          : l10n.secret_chat_media_views_count(v),
                    ),
                  ),
              ],
              onChanged: _busy ? null : (v) => setState(() => onChanged(v)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                NotificationSettingsPageHeader(
                  title: peer.name.trim().isNotEmpty
                      ? '${l10n.secret_chat_title} · ${peer.name}'
                      : l10n.secret_chat_title,
                  leadingIcon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF4DA2FF),
                ),
                const SizedBox(height: 12),
                NotificationSettingsCard(
                  title: l10n.secret_chat_ttl_title,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                      child: SizedBox(
                        height: 30,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: dark ? 0.22 : 0.14),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _ttlSec,
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              items: [
                                for (final sec in SecretChatTtlSheet.presets)
                                  DropdownMenuItem(
                                    value: sec,
                                    child: Text(
                                      SecretChatTtlSheet.presetLabel(l10n, sec),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (v) => setState(() => _ttlSec = v ?? _ttlSec),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NotificationSettingsCard(
                  title: l10n.secret_chat_settings_subtitle,
                  children: [
                    NotificationSettingsSwitchRow(
                      title: l10n.secret_chat_settings_no_forward,
                      value: _noForward,
                      onChanged: _busy ? (_) {} : (v) => setState(() => _noForward = v),
                      disabled: _busy,
                    ),
                    NotificationSettingsSwitchRow(
                      title: l10n.secret_chat_settings_no_copy,
                      value: _noCopy,
                      onChanged: _busy ? (_) {} : (v) => setState(() => _noCopy = v),
                      disabled: _busy,
                    ),
                    NotificationSettingsSwitchRow(
                      title: l10n.secret_chat_settings_no_save,
                      value: _noSave,
                      onChanged: _busy ? (_) {} : (v) => setState(() => _noSave = v),
                      disabled: _busy,
                    ),
                    NotificationSettingsSwitchRow(
                      title: l10n.secret_chat_settings_screenshot_protection,
                      value: _screenshotProtection,
                      onChanged: _busy
                          ? (_) {}
                          : (v) => setState(() => _screenshotProtection = v),
                      disabled: _busy,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(height: 12),
                NotificationSettingsCard(
                  title: l10n.secret_chat_settings_media_views,
                  subtitle: l10n.secret_chat_settings_media_views_subtitle,
                  children: [
                    mediaLimitRow(
                      title: l10n.secret_chat_media_type_image,
                      value: _imageViews,
                      onChanged: (v) => _imageViews = v,
                    ),
                    mediaLimitRow(
                      title: l10n.secret_chat_media_type_video,
                      value: _videoViews,
                      onChanged: (v) => _videoViews = v,
                    ),
                    mediaLimitRow(
                      title: l10n.secret_chat_media_type_voice,
                      value: _voiceViews,
                      onChanged: (v) => _voiceViews = v,
                    ),
                    mediaLimitRow(
                      title: l10n.secret_chat_media_type_file,
                      value: _fileViews,
                      onChanged: (v) => _fileViews = v,
                    ),
                    mediaLimitRow(
                      title: l10n.secret_chat_media_type_location,
                      value: _locationViews,
                      onChanged: (v) => _locationViews = v,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(height: 12),
                NotificationSettingsCard(
                  title: l10n.secret_chat_unlock_title,
                  children: [
                    NotificationSettingsSwitchRow(
                      title: l10n.secret_chat_compose_require_unlock_pin,
                      subtitle: l10n.secret_chat_unlock_subtitle,
                      value: _lockRequired,
                      onChanged: _busy
                          ? (_) {}
                          : (v) => setState(() {
                              _lockRequired = v;
                              if (!v) _vaultPin = null;
                            }),
                      disabled: _busy,
                    ),
                    if (_lockRequired) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          l10n.secret_chat_compose_vault_pin_subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          title: Text(
                            _vaultPin == null
                                ? l10n.secret_chat_pin_label
                                : '${l10n.secret_chat_pin_label}: ••••',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _busy
                              ? null
                              : () async {
                                  final pin = await SecretVaultPinScreen.open(
                                    context,
                                    title: l10n.secret_chat_pin_label,
                                    subtitle: l10n.privacy_secret_vault_new_pin,
                                    confirm: true,
                                  );
                                  if (pin == null || !mounted) return;
                                  setState(() => _vaultPin = pin);
                                },
                        ),
                      ),
                    ],
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : () => unawaited(_submit()),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.secret_chat_compose_create),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
