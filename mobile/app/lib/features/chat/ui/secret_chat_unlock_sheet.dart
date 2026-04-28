import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../l10n/app_localizations.dart';
import '../data/secret_chat_callables.dart';
import '../data/secret_chat_pin_device_storage.dart';

class SecretChatUnlockResult {
  const SecretChatUnlockResult({required this.unlocked});

  final bool unlocked;
}

class SecretChatUnlockSheet extends StatefulWidget {
  const SecretChatUnlockSheet({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  State<SecretChatUnlockSheet> createState() => _SecretChatUnlockSheetState();
}

class _SecretChatUnlockSheetState extends State<SecretChatUnlockSheet> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _pinNotSet = false;
  bool _rememberOnDevice = true;
  bool _biometricsAvailable = false;
  bool _hasSavedPin = false;

  final _auth = LocalAuthentication();
  final _pinStore = SecretChatPinDeviceStorage();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      final can = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      final saved = await _pinStore.readPin(conversationId: widget.conversationId);
      if (!mounted) return;
      setState(() {
        _biometricsAvailable = can;
        _hasSavedPin = saved != null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricsAvailable = false;
        _hasSavedPin = false;
      });
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
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
      await SecretChatCallables().unlock(
        conversationId: widget.conversationId,
        pin: pin,
      );
      if (_rememberOnDevice) {
        await _pinStore.savePin(conversationId: widget.conversationId, pin: pin);
      }
      if (!mounted) return;
      Navigator.of(context).pop(const SecretChatUnlockResult(unlocked: true));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      if (e.message == 'PIN_NOT_SET' || e.details == 'PIN_NOT_SET' || e.code == 'failed-precondition') {
        setState(() => _pinNotSet = true);
      }
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_unlock_failed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_unlock_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPinAndUnlock() async {
    if (_busy) return;
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
      await SecretChatCallables().setPin(pin: pin);
      await SecretChatCallables().unlock(conversationId: widget.conversationId, pin: pin);
      if (_rememberOnDevice) {
        await _pinStore.savePin(conversationId: widget.conversationId, pin: pin);
      }
      if (!mounted) return;
      Navigator.of(context).pop(const SecretChatUnlockResult(unlocked: true));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.secret_chat_unlock_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final saved = await _pinStore.readPin(conversationId: widget.conversationId);
      if (saved == null) {
        setState(() => _error = l10n.secret_chat_biometric_no_saved_pin);
        return;
      }
      setState(() {
        _busy = true;
        _error = null;
      });
      final ok = await _auth.authenticate(
        localizedReason: l10n.secret_chat_biometric_reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) {
        setState(() => _error = l10n.secret_chat_unlock_failed);
        return;
      }
      await SecretChatCallables().unlock(
        conversationId: widget.conversationId,
        pin: saved,
        method: 'biometric',
      );
      if (!mounted) return;
      Navigator.of(context).pop(const SecretChatUnlockResult(unlocked: true));
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Biometric unlock failed: $e');
      }
      setState(() => _error = l10n.secret_chat_unlock_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.secret_chat_unlock_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.secret_chat_unlock_subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.secret_chat_pin_label,
                errorText: _error,
              ),
              onSubmitted: (_) => unawaited(_pinNotSet ? _setPinAndUnlock() : _unlock()),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _rememberOnDevice,
              onChanged: _busy ? null : (v) => setState(() => _rememberOnDevice = v),
              title: Text(l10n.secret_chat_remember_pin),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_pinNotSet ? _setPinAndUnlock() : _unlock()),
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_pinNotSet ? l10n.secret_chat_set_pin_and_unlock : l10n.secret_chat_unlock_action),
            ),
            if (_biometricsAvailable) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy || !_hasSavedPin ? null : () => unawaited(_unlockWithBiometrics()),
                child: Text(l10n.secret_chat_unlock_biometric),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(const SecretChatUnlockResult(unlocked: false)),
              child: Text(l10n.common_cancel),
            ),
          ],
        ),
      ),
    );
  }
}

