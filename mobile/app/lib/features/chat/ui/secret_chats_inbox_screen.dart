import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'secret_vault_pin_screen.dart';

/// Список секретных чатов (индекс `userSecretChats`). Перед показом — биометрия или PIN.
class SecretChatsInboxScreen extends ConsumerStatefulWidget {
  const SecretChatsInboxScreen({super.key});

  @override
  ConsumerState<SecretChatsInboxScreen> createState() =>
      _SecretChatsInboxScreenState();
}

class _SecretChatsInboxScreenState
    extends ConsumerState<SecretChatsInboxScreen> {
  bool _booting = true;
  bool _unlocked = false;
  bool _busy = false;
  String? _error;
  bool _needsPrivacySetup = false;

  /// Серверный vault PIN задан (callable). Локально сохранённый PIN — для кнопки Face ID.
  bool _vaultPinConfigured = false;
  bool _biometricsAvailable = false;
  bool _hasSavedVaultPinOnDevice = false;

  /// Только для начальной загрузки hasVaultPin — не смешивать с [_busy] ручного ввода.
  bool _vaultGateInFlight = false;
  bool _pinPromptInFlight = false;
  final _auth = LocalAuthentication();
  final _pinStore = const SecretChatPinDeviceStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runGate());
    });
  }

  Future<void> _runGate() async {
    if (_vaultGateInFlight) return;
    _vaultGateInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    final callables = SecretChatCallables();
    try {
      final has = await callables.hasVaultPin().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (!mounted) return;

      final canBio =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      String? savedLocal;
      if (has) {
        savedLocal = await _pinStore.readVaultPin();
      }

      if (!mounted) return;

      setState(() {
        _vaultPinConfigured = has;
        _biometricsAvailable = canBio;
        _hasSavedVaultPinOnDevice =
            savedLocal != null && savedLocal.trim().length == 4;
        _booting = false;
        _unlocked = false;
        if (!has && !canBio) {
          _needsPrivacySetup = true;
          _error = l10n.privacy_secret_vault_setup_required;
        }
      });

      if (!has) return;

      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || _unlocked) return;

      if (canBio && savedLocal != null && savedLocal.trim().length == 4) {
        await _unlockVaultWithBiometrics(fallbackToPinOnFailure: true);
        return;
      }
      await _promptPinUnlock();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SecretChatsInbox _runGate: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _booting = false;
        _unlocked = false;
        _needsPrivacySetup = true;
        _error = l10n.privacy_secret_vault_setup_required;
      });
    } finally {
      _vaultGateInFlight = false;
    }
  }

  Future<void> _unlockVaultWithBiometrics({
    bool fallbackToPinOnFailure = false,
  }) async {
    if (_busy || !_vaultPinConfigured) return;
    final l10n = AppLocalizations.of(context)!;
    final saved = await _pinStore.readVaultPin();
    if (saved == null || saved.trim().length != 4) {
      if (fallbackToPinOnFailure) {
        await _promptPinUnlock();
      } else {
        setState(() => _error = l10n.secret_chat_biometric_no_saved_pin);
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _auth.authenticate(
        localizedReason: l10n.secret_chat_biometric_reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) {
        if (fallbackToPinOnFailure) {
          await _promptPinUnlock();
        }
        return;
      }
      await SecretChatCallables().verifyVaultPin(pin: saved.trim());
      if (!mounted) return;
      setState(() => _unlocked = true);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SecretChatsInbox biometric vault: $e\n$st');
      }
      if (!mounted) return;
      setState(() => _error = l10n.secret_chat_unlock_failed);
      if (fallbackToPinOnFailure) {
        await _promptPinUnlock();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPin(String pinRaw) async {
    final pin = pinRaw.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(
        () => _error = AppLocalizations.of(context)!.secret_chat_pin_invalid,
      );
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
      setState(
        () => _error = AppLocalizations.of(context)!.secret_chat_unlock_failed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promptPinUnlock() async {
    if (!mounted || _busy || _unlocked || _pinPromptInFlight) return;
    _pinPromptInFlight = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final pin = await SecretVaultPinScreen.open(
        context,
        title: l10n.secret_chat_unlock_title,
        subtitle: l10n.secret_chat_unlock_subtitle,
        confirm: false,
      );
      if (!mounted) return;
      if (pin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.secret_chat_unlock_subtitle)),
        );
        return;
      }
      await _submitPin(pin);
    } finally {
      _pinPromptInFlight = false;
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_promptPinUnlock()),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.secret_chat_unlock_action),
          ),
          if (_vaultPinConfigured &&
              _biometricsAvailable &&
              _hasSavedVaultPinOnDevice) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => unawaited(_unlockVaultWithBiometrics()),
              child: Text(l10n.secret_chat_unlock_biometric),
            ),
          ],
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
        final fromMain =
            (mainIdxAsync.asData?.value?.conversationIds ?? const <String>[])
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
            // Нельзя вызывать sort на списке из провайдера — мутация ломает кеш Riverpod / может давать UB.
            final sorted = List<ConversationWithId>.of(convs)
              ..sort((a, b) {
                final ta =
                    DateTime.tryParse(
                      a.data.lastMessageTimestamp ?? '',
                    )?.millisecondsSinceEpoch ??
                    0;
                final tb =
                    DateTime.tryParse(
                      b.data.lastMessageTimestamp ?? '',
                    )?.millisecondsSinceEpoch ??
                    0;
                return tb.compareTo(ta);
              });
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = sorted[i];
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
            l10n: AppLocalizations.of(context)!,
          );
    final lastMsg = (conversation.data.lastMessageText ?? '').trim();
    final subtitle = lastMsg.isEmpty ? l10n.secret_chat_title : lastMsg;
    final pinfo = partnerId == null
        ? null
        : conversation.data.participantInfo?[partnerId];

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
