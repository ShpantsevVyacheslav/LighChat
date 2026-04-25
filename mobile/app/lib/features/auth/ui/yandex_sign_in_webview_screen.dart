import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import '../yandex_oauth_start_url.dart';

/// WebView: старт OAuth Яндекс → редиректы → `/auth/yandex#customToken=…` → [FirebaseAuth.signInWithCustomToken].
class YandexSignInWebViewScreen extends ConsumerStatefulWidget {
  const YandexSignInWebViewScreen({super.key});

  @override
  ConsumerState<YandexSignInWebViewScreen> createState() =>
      _YandexSignInWebViewScreenState();
}

class _YandexSignInWebViewScreenState
    extends ConsumerState<YandexSignInWebViewScreen> {
  late final WebViewController _controller;
  var _busy = true;
  String? _error;
  String _currentUrl = '';
  var _tokenHandled = false;

  String? _customTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.fragment.startsWith('customToken=')) {
        final v = uri.fragment.substring('customToken='.length);
        final decoded = Uri.decodeComponent(v);
        return decoded.trim().isNotEmpty ? decoded.trim() : null;
      }
      final q = uri.queryParameters['customToken'];
      if (q != null && q.trim().isNotEmpty) return q.trim();
    } catch (_) {
      // ignore
    }
    return null;
  }

  Future<void> _tryReadTokenFromDocumentHash() async {
    if (_tokenHandled || !mounted) return;
    try {
      final r = await _controller.runJavaScriptReturningResult(
        "(function(){var m=(location.hash||'').match(/customToken=([^&^#]+)/);"
        "return m?decodeURIComponent(m[1]):'';})()",
      );
      if (r is! String) return;
      final raw = r.trim();
      if (raw.isEmpty) return;
      if (raw.isNotEmpty) {
        await _onCustomToken(raw);
      }
    } catch (_) {
      // ignore
    }
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
    final url = Uri.parse(yandexOAuthStartUrl());
    _currentUrl = url.toString();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final next = request.url;
            final token = _customTokenFromUrl(next);
            if (token != null) {
              unawaited(_onCustomToken(token));
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
          onPageFinished: (url) async {
            if (mounted) setState(() => _busy = false);
            if (url.contains('yandex_error=') ||
                url.contains('?yandex_error')) {
              try {
                final uri = Uri.parse(url);
                final err = uri.queryParameters['yandex_error'];
                if (mounted && err != null && err.isNotEmpty) {
                  setState(() => _error = 'Яндекс: $err');
                }
              } catch (_) {
                // ignore
              }
            }
            if (url.contains('/auth/yandex')) {
              await _tryReadTokenFromDocumentHash();
            }
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
    if (_tokenHandled) return;
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
                  msg is String && msg.trim().isNotEmpty
                      ? msg.trim()
                      : 'Ошибка входа через Яндекс.');
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
        setState(() => _error = 'Firebase не готов.');
      }
      return;
    }
    _tokenHandled = true;
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
      if ((isTelegramUid || isYandexUid) &&
          status == RegistrationProfileStatus.incomplete) {
        router.go('/chats');
        return;
      }
      final next = googleRouteFromProfileStatus(status);
      router.go(next ?? '/chats');
    } catch (e) {
      _tokenHandled = false;
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
        title: const Text('Вход через Яндекс'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Открыть в браузере',
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = _currentUrl.trim().isNotEmpty
                  ? _currentUrl.trim()
                  : yandexOAuthStartUrl();
              final ok = await _launchExternal(url);
              if (!ok && mounted) {
                setState(() => _error = 'Не удалось открыть браузер.');
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
