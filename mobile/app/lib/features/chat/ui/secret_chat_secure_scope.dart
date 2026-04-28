import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecretChatSecureScope extends StatefulWidget {
  const SecretChatSecureScope({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<SecretChatSecureScope> createState() => _SecretChatSecureScopeState();
}

class _SecretChatSecureScopeState extends State<SecretChatSecureScope> {
  bool _applied = false;

  Future<void> _apply(bool enabled) async {
    if (!Platform.isAndroid) return;
    if (enabled) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _applied = true;
    } else if (_applied) {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      _applied = false;
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

