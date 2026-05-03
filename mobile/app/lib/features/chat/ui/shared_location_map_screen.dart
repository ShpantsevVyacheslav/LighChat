import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../data/google_maps_urls.dart';
import 'location_live_countdown.dart';

/// Полноэкранная карта: WebView (OSM + Leaflet) + назад + открыть во внешнем браузере.
class SharedLocationMapScreen extends StatefulWidget {
  const SharedLocationMapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.externalMapsUrl,
    this.liveExpiresAtIso,
  });

  final double lat;
  final double lng;
  final String? externalMapsUrl;
  final String? liveExpiresAtIso;

  @override
  State<SharedLocationMapScreen> createState() => _SharedLocationMapScreenState();
}

class _SharedLocationMapScreenState extends State<SharedLocationMapScreen> {
  late final WebViewController _web;
  var _loading = true;
  Timer? _loadingTimeout;

  void _hideLoader() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    if (!_loading || !mounted) return;
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    final html = buildOpenStreetMapLeafletHtml(widget.lat, widget.lng);
    _loadingTimeout = Timer(const Duration(seconds: 15), _hideLoader);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _hideLoader(),
          onWebResourceError: (_) => _hideLoader(),
          onHttpError: (_) => _hideLoader(),
          onProgress: (progress) {
            if (progress >= 90) _hideLoader();
          },
        ),
      );
    unawaited(_loadMap(html));
  }

  Future<void> _loadMap(String html) async {
    try {
      await _web.setUserAgent('LighChatMobile/1.0');
    } catch (_) {}
    try {
      await _web.loadHtmlString(
        html,
        baseUrl: 'https://unpkg.com/',
      );
    } catch (_) {
      if (mounted) _hideLoader();
    }
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final raw = (widget.externalMapsUrl ?? '').trim();
    final uri = Uri.tryParse(raw.isNotEmpty ? raw : buildGoogleMapsPlaceUrl(widget.lat, widget.lng));
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final exp = widget.liveExpiresAtIso;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _web),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          Positioned(
            top: top + 8,
            left: 8,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            right: 8,
            child: IconButton.filledTonal(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              tooltip: AppLocalizations.of(context)!.shared_location_open_browser_tooltip,
            ),
          ),
          if (exp != null && exp.isNotEmpty)
            Positioned(
              top: top + 56,
              left: 12,
              child: LocationLiveCountdown(expiresAtIso: exp),
            ),
        ],
      ),
    );
  }
}
