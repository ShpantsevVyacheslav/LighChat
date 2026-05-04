import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import '../telegram_bridge_url.dart';

/// WebView с `/auth/telegram?mobile=1` на прод-домене (см. [telegramAuthBridgePageUrl]).
/// Виджет Telegram →
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
  String _currentUrl = '';

  bool _isTelegramExternalUrl(String url) {
    return url.startsWith('tg://') ||
        url.startsWith('https://t.me/') ||
        url.startsWith('https://telegram.me/') ||
        url.startsWith('https://telegram.org/') ||
        url.startsWith('intent://');
  }

  String? _customTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Hash: #customToken=...
      if (uri.fragment.startsWith('customToken=')) {
        final v = uri.fragment.substring('customToken='.length);
        final decoded = Uri.decodeComponent(v);
        return decoded.trim().isNotEmpty ? decoded.trim() : null;
      }
      // Query: ?customToken=...
      final q = uri.queryParameters['customToken'];
      if (q != null && q.trim().isNotEmpty) return q.trim();
    } catch (_) {
      // ignore
    }
    return null;
  }

  Future<bool> _launchExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    final url = Uri.parse(telegramAuthBridgePageUrl());
    _currentUrl = url.toString();
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
          onNavigationRequest: (request) async {
            final next = request.url;
            final token = _customTokenFromUrl(next);
            if (token != null) {
              unawaited(_onCustomToken(token));
              return NavigationDecision.prevent;
            }
            if (_isTelegramExternalUrl(next)) {
              final ok = await _launchExternal(next);
              if (!ok && mounted) {
                setState(() => _error = AppLocalizations.of(context)!.telegram_sign_in_open_telegram_failed);
              }
              return NavigationDecision.prevent;
            }
            if (mounted) {
              setState(() => _currentUrl = next);
            } else {
              _currentUrl = next;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _currentUrl = url);
            } else {
              _currentUrl = url;
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _busy = false);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _error = err.description.isNotEmpty
                  ? err.description
                  : AppLocalizations.of(context)!.telegram_sign_in_page_load_error;
            });
          },
        ),
      );
    unawaited(_controller.loadRequest(url));
  }

  Future<void> _onCustomToken(String token) async {
    final raw = token.trim();
    if (raw.isEmpty) return;
    var t = raw;
    if (raw.startsWith('{')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final type = decoded['type'];
          if (type == 'error') {
            final msg = decoded['message'];
            if (mounted) {
              setState(() => _error =
                  msg is String && msg.trim().isNotEmpty ? msg.trim() : AppLocalizations.of(context)!.telegram_sign_in_login_error);
            }
            return;
          }
          final tok = decoded['token'];
          if (tok is String && tok.trim().isNotEmpty) {
            t = tok.trim();
          }
        }
      } catch (_) {
        // keep raw token
      }
    }
    if (t.isEmpty) return;
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.telegram_sign_in_firebase_not_ready);
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
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        router.go('/auth');
        return;
      }
      final status = await getFirestoreRegistrationProfileStatusWithDeadline(
        user,
      );
      final isTelegramUid = RegExp(r'^tg_\d+$').hasMatch(user.uid);
      final isYandexUid = RegExp(r'^ya_\d+$').hasMatch(user.uid);
      // Telegram / Yandex users may not have phone/email on first sign-in; don't block them
      // on the "Google complete profile" screen (it has no bottom nav).
      if ((isTelegramUid || isYandexUid) &&
          status == RegistrationProfileStatus.incomplete) {
        router.go('/chats');
        return;
      }
      final next = googleRouteFromProfileStatus(status);
      router.go(next ?? '/chats');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context)!.telegram_sign_in_login_failed(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.telegram_sign_in_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.telegram_sign_in_open_in_browser,
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = _currentUrl.trim().isNotEmpty
                  ? _currentUrl.trim()
                  : telegramAuthBridgePageUrl();
              final ok = await _launchExternal(url);
              if (!ok && mounted) {
                setState(() => _error = AppLocalizations.of(context)!.telegram_sign_in_browser_failed);
              }
            },
          ),
        ],
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
