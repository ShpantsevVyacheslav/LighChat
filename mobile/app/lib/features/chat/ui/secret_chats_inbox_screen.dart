import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:local_auth/local_auth.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/dm_display_title.dart';
import '../data/secret_chat_callables.dart';
import '../data/secret_chat_pin_device_storage.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_avatar.dart';
import 'chat_shell_backdrop.dart';

/// Список секретных чатов (индекс `userSecretChats`). Перед показом — биометрия или PIN.
class SecretChatsInboxScreen extends ConsumerStatefulWidget {
  const SecretChatsInboxScreen({super.key});

  @override
  ConsumerState<SecretChatsInboxScreen> createState() =>
      _SecretChatsInboxScreenState();
}

class _SecretChatsInboxScreenState extends ConsumerState<SecretChatsInboxScreen> {
  bool _booting = true;
  bool _unlocked = false;
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _needsPrivacySetup = false;
  final _auth = LocalAuthentication();
  final _pinStore = const SecretChatPinDeviceStorage();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runGate());
    });
  }

  Future<void> _runGate() async {
    final l10n = AppLocalizations.of(context)!;
    final callables = SecretChatCallables();
    try {
      final has = await callables
          .hasVaultPin()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!mounted) return;
      if (!has) {
        final canBio =
            await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (!mounted) return;
        if (!canBio) {
          setState(() {
            _booting = false;
            _unlocked = false;
            _needsPrivacySetup = true;
            _error = l10n.privacy_secret_vault_setup_required;
          });
          return;
        }
        setState(() {
          _booting = false;
          _unlocked = false;
        });
        return;
      }

      final canBio = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canBio) {
        final ok = await _auth.authenticate(
          localizedReason: l10n.secret_chat_biometric_reason,
        );
        if (ok) {
          final saved = await _pinStore.readVaultPin();
          if (saved != null && saved.length == 4) {
            await callables.verifyVaultPin(pin: saved);
            if (!mounted) return;
            setState(() {
              _booting = false;
              _unlocked = true;
            });
            return;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _booting = false;
        _unlocked = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booting = false;
        _unlocked = false;
        _needsPrivacySetup = true;
        _error = l10n.privacy_secret_vault_setup_required;
      });
    }
  }

  Future<void> _submitPin() async {
    final pin = _pin.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_pin_invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SecretChatCallables().verifyVaultPin(pin: pin);
      await _pinStore.saveVaultPin(pin);
      if (!mounted) return;
      setState(() => _unlocked = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_unlock_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.secret_chats_title),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            child: _booting
                ? const Center(child: CircularProgressIndicator())
                : !_unlocked
                    ? _pinGate(context, l10n)
                    : _SecretChatList(currentUserId: user.uid),
          ),
        ],
      ),
    );
  }

  Widget _pinGate(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.secret_chat_unlock_subtitle,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: l10n.secret_chat_pin_label,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_submitPin()),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.secret_chat_unlock_action),
          ),
          if (_needsPrivacySetup) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go('/settings/privacy'),
              child: Text(l10n.privacy_title),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecretChatList extends ConsumerWidget {
  const _SecretChatList({required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idxAsync = ref.watch(userSecretChatIndexProvider(currentUserId));
    final mainIdxAsync = ref.watch(userChatIndexProvider(currentUserId));
    return idxAsync.when(
      data: (idx) {
        final directIds = idx?.conversationIds ?? const <String>[];
        final fromMain = (mainIdxAsync.asData?.value?.conversationIds ?? const <String>[])
            .where((id) => id.startsWith('sdm_'))
            .toList(growable: false);
        final ids = directIds.isNotEmpty ? directIds : fromMain;
        if (ids.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.chat_list_empty_all_body,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final convAsync = ref.watch(
          conversationsProvider((key: conversationIdsCacheKey(ids))),
        );
        return convAsync.when(
          data: (convs) {
            convs.sort((a, b) {
              final ta = DateTime.tryParse(a.data.lastMessageTimestamp ?? '')
                      ?.millisecondsSinceEpoch ??
                  0;
              final tb = DateTime.tryParse(b.data.lastMessageTimestamp ?? '')
                      ?.millisecondsSinceEpoch ??
                  0;
              return tb.compareTo(ta);
            });
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: convs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = convs[i];
                return _SecretChatRow(
                  currentUserId: currentUserId,
                  conversation: c,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _SecretChatRow extends StatelessWidget {
  const _SecretChatRow({
    required this.currentUserId,
    required this.conversation,
  });

  final String currentUserId;
  final ConversationWithId conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final others = conversation.data.participantIds
        .where((id) => id != currentUserId)
        .toList(growable: false);
    final partnerId = others.isEmpty ? null : others.first;
    final title = partnerId == null
        ? l10n.secret_chat_title
        : dmConversationDisplayTitle(
            currentUserId: currentUserId,
            conversation: conversation,
            otherUserId: partnerId,
          );
    final lastMsg = (conversation.data.lastMessageText ?? '').trim();
    final subtitle =
        lastMsg.isEmpty ? l10n.secret_chat_title : lastMsg;
    final pinfo = partnerId == null ? null : conversation.data.participantInfo?[partnerId];

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/chats/${conversation.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ChatAvatar(
                title: title.isNotEmpty ? title : '?',
                avatarUrl: pinfo?.avatarThumb ?? pinfo?.avatar,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
