import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/nav_bar_config.dart';
import '../../../platform/native_nav_bar/native_nav_scaffold.dart';
import '../data/chat_link_normalization.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LinkWebViewScreen extends StatefulWidget {
  const LinkWebViewScreen({super.key, required this.url});

  final String url;

  static void open(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LinkWebViewScreen(url: url)),
    );
  }

  @override
  State<LinkWebViewScreen> createState() => _LinkWebViewScreenState();
}

class _LinkWebViewScreenState extends State<LinkWebViewScreen> {
  late final WebViewController _controller;
  String _currentUrl = '';
  String _pageTitle = '';
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    final initialUri = tryParseHttpChatLink(widget.url);
    _currentUrl = initialUri?.toString() ?? normalizeChatLinkUrl(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            final uri = Uri.tryParse(url);
            if (uri != null &&
                !uri.isScheme('http') &&
                !uri.isScheme('https') &&
                !uri.isScheme('about') &&
                !uri.isScheme('data')) {
              unawaited(_launchExternal(url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _currentUrl = url);
            _updateNavState();
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            final title = await _controller.getTitle();
            setState(() {
              _currentUrl = url;
              _pageTitle = title ?? '';
            });
            _updateNavState();
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress / 100.0);
          },
          onWebResourceError: (_) {},
        ),
      );
    if (initialUri != null) {
      unawaited(_controller.loadRequest(initialUri));
    } else {
      // Prevent a blank page when the link cannot be loaded in WebView.
      unawaited(_launchExternal(_currentUrl));
    }
  }

  Future<void> _updateNavState() async {
    final back = await _controller.canGoBack();
    final fwd = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = fwd;
    });
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url.trim()) ?? tryParseHttpChatLink(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _displayHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host.isNotEmpty ? uri.host : url;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final host = _displayHost(_currentUrl);
    final title = _pageTitle.isNotEmpty ? _pageTitle : host;

    return NativeNavScaffold(
      top: NavBarTopConfig(
        title: NavBarTitle(title: title, subtitle: host),
        leading: const NavBarLeading.close(),
        trailing: [
          const NavBarAction(
            id: 'copy_url',
            icon: NavBarIcon('doc.on.doc'),
          ),
          const NavBarAction(
            id: 'open_browser',
            icon: NavBarIcon('safari'),
          ),
        ],
      ),
      onBack: () => Navigator.of(context).pop(),
      onAction: (id) {
        if (id == 'copy_url') {
          Clipboard.setData(ClipboardData(text: _currentUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.link_webview_copied_snackbar),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (id == 'open_browser') {
          unawaited(_launchExternal(_currentUrl));
        }
      },
      body: Column(
        children: [
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
          Container(
            decoration: BoxDecoration(
              color: dark
                  ? scheme.surface.withValues(alpha: 0.95)
                  : scheme.surfaceContainerHigh,
              border: Border(
                top: BorderSide(
                  color: scheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: _canGoBack
                          ? () => unawaited(_controller.goBack())
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: _canGoForward
                          ? () => unawaited(_controller.goForward())
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => unawaited(_controller.reload()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      onPressed: () => unawaited(_launchExternal(_currentUrl)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
