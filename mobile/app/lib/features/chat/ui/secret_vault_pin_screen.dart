import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SecretVaultPinScreen extends StatefulWidget {
  const SecretVaultPinScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.confirm = false,
  });

  final String title;
  final String subtitle;
  final bool confirm;

  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool confirm = false,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SecretVaultPinScreen(
          title: title,
          subtitle: subtitle,
          confirm: confirm,
        ),
      ),
    );
  }

  @override
  State<SecretVaultPinScreen> createState() => _SecretVaultPinScreenState();
}

class _SecretVaultPinScreenState extends State<SecretVaultPinScreen> {
  static const _pinLen = 4;
  String _pin = '';
  String? _firstPass;
  String? _error;

  String _activeSubtitle(AppLocalizations l10n) {
    if (!widget.confirm) return widget.subtitle;
    if (_firstPass == null) return widget.subtitle;
    return l10n.privacy_secret_vault_repeat_pin;
  }

  void _addDigit(String d) {
    if (_pin.length >= _pinLen) return;
    setState(() {
      _pin = '$_pin$d';
      _error = null;
    });
    if (_pin.length == _pinLen) {
      _onPinCompleted();
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onPinCompleted() {
    if (!widget.confirm) {
      Navigator.of(context).pop(_pin);
      return;
    }
    if (_firstPass == null) {
      setState(() {
        _firstPass = _pin;
        _pin = '';
      });
      return;
    }
    if (_firstPass != _pin) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _pin = '';
        _firstPass = null;
        _error = l10n.privacy_secret_vault_pin_mismatch;
      });
      return;
    }
    Navigator.of(context).pop(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left_rounded, size: 32),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeSubtitle(l10n),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pinLen,
                (i) => Container(
                  width: 13,
                  height: 13,
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Column(
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '⌫'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final key in row)
                            _PinPadButton(
                              label: key,
                              onTap: key.isEmpty
                                  ? null
                                  : () {
                                      if (key == '⌫') {
                                        _backspace();
                                      } else {
                                        _addDigit(key);
                                      }
                                    },
                            ),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.common_cancel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinPadButton extends StatelessWidget {
  const _PinPadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 82,
      height: 82,
      child: Material(
        color: enabled ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w400,
                color: enabled ? Colors.white : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
