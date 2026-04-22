import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import '../telegram_bridge_url.dart';

/// WebView с [`/auth/telegram?mobile=1`](https://lighchat.app/auth/telegram?mobile=1): виджет Telegram →
/// callable → `TelegramAuth.postMessage(customToken)` → [FirebaseAuth.signInWithCustomToken].
class TelegramSignInWebViewScreen extends ConsumerStatefulWidget {
  const TelegramSignInWebViewScreen({super.key});

  @override
  ConsumerState<TelegramSignInWebViewScreen> createState() =>
      _TelegramSignInWebViewScreenState();
}

class _TelegramSignInWebViewScreenState
    extends ConsumerState<TelegramSignInWebViewScreen> {
  late final WebViewController _controller;
  var _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final url = Uri.parse(telegramAuthBridgePageUrl());
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TelegramAuth',
        onMessageReceived: (JavaScriptMessage message) {
          unawaited(_onCustomToken(message.message));
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _busy = false);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _error = err.description.isNotEmpty
                  ? err.description
                  : 'Ошибка загрузки страницы';
            });
          },
        ),
      );
    unawaited(_controller.loadRequest(url));
  }

  Future<void> _onCustomToken(String token) async {
    final t = token.trim();
    if (t.isEmpty) return;
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      if (mounted) {
        setState(() => _error = 'Firebase не готов.');
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.signInWithCustomToken(t);
      if (!mounted) return;
      Navigator.of(context).pop();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) context.go('/auth');
        return;
      }
      final status = await getFirestoreRegistrationProfileStatusWithDeadline(
        user,
      );
      if (!mounted) return;
      final next = googleRouteFromProfileStatus(status);
      if (next == null) {
        context.go('/chats');
        return;
      }
      context.go(next);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Не удалось войти: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход через Telegram'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_busy)
            ColoredBox(
              color: scheme.surface.withValues(alpha: 0.85),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
