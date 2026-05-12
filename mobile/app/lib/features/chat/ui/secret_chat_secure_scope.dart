import 'package:flutter/material.dart';

import '../../../platform/screenshot_protection_facade.dart';

class SecretChatSecureScope extends StatefulWidget {
  const SecretChatSecureScope({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<SecretChatSecureScope> createState() => _SecretChatSecureScopeState();
}

class _SecretChatSecureScopeState extends State<SecretChatSecureScope> {
  Future<void> _apply(bool enabled) async {
    if (enabled) {
      await ScreenshotProtectionFacade.instance.enable();
    } else {
      await ScreenshotProtectionFacade.instance.disable();
    }
  }

  @override
  void initState() {
    super.initState();
    // Best-effort; do not crash UI on failure.
    _apply(widget.enabled).catchError((_) {});
  }

  @override
  void didUpdateWidget(covariant SecretChatSecureScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _apply(widget.enabled).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _apply(false).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

