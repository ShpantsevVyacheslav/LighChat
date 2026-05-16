import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../data/google_maps_urls.dart';
import 'chat_location_map_view.dart';
import 'location_live_countdown.dart';

/// `webview_flutter` нет нативной реализации на Windows / Linux — там
/// `WebViewController()` крашит UI ("Unimplemented platform interface").
/// Для этих платформ показываем placeholder + кнопку «Открыть в браузере».
/// На iOS используем нативный MKMapView (см. ниже), WebView не нужен.
bool get _supportsInlineWebView {
  if (kIsWeb) return false; // web использует свой плагин, но мы туда не идём
  if (defaultTargetPlatform == TargetPlatform.iOS) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Bug D: на iOS используем нативный Apple MKMapView (через
/// PlatformView), а не WebView+OSM Leaflet. Это даёт настоящие Apple
/// Maps с правильным dark-mode parity и без сетевого latency на
/// загрузку HTML/JS+тайлов.
bool get _useNativeAppleMap =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Полноэкранная карта.
///
/// На iOS — нативный Apple MKMapView через [ChatLocationMapView]
/// (Bug D, Phase 14). MKPolyline overlay трека (Bug 13) рисуется
/// автоматически, когда передан `senderUidForTracking` — view
/// сама подписывается на sub-collection `users/{uid}/
/// liveLocationTrackPoints` и обновляет overlay по snapshot'ам.
/// На Android и macOS — WebView (OSM + Leaflet); на Windows /
/// Linux — placeholder с кнопкой «Открыть в браузере».
class SharedLocationMapScreen extends StatefulWidget {
  const SharedLocationMapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.externalMapsUrl,
    this.liveExpiresAtIso,
    this.senderUidForTracking,
  });

  final double lat;
  final double lng;
  final String? externalMapsUrl;
  final String? liveExpiresAtIso;

  /// Bug 13: uid отправителя для подписки на trackPoints. Если задан
  /// и live-session ещё активна — fullscreen MKMapView (на iOS)
  /// будет рисовать MKPolyline пройденного пути.
  final String? senderUidForTracking;

  @override
  State<SharedLocationMapScreen> createState() => _SharedLocationMapScreenState();
}

class _SharedLocationMapScreenState extends State<SharedLocationMapScreen> {
  WebViewController? _web;
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
    if (_useNativeAppleMap) {
      // Bug D: на iOS используем нативную MKMapView — никаких
      // loader'ов, она поднимается мгновенно.
      _loading = false;
      return;
    }
    if (!_supportsInlineWebView) {
      // Windows / Linux: WebView плагин не реализован. Не создаём
      // controller (это бы крашнуло "Unimplemented platform interface").
      _loading = false;
      return;
    }
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
    final web = _web;
    if (web == null) return;
    try {
      await web.setUserAgent('LighChatMobile/1.0');
    } catch (_) {}
    try {
      await web.loadHtmlString(
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
    final web = _web;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_useNativeAppleMap)
            // Bug D: нативный Apple MKMapView на iOS — interactive
            // (pan/zoom) + dark mode parity с системой.
            // Bug 13: если переданы координаты отправителя и live-
            // session активна — отрисовываем MKPolyline трека.
            ChatLocationMapView(
              lat: widget.lat,
              lng: widget.lng,
              interactive: true,
              trackPointsForUid: widget.senderUidForTracking,
            )
          else if (web != null)
            WebViewWidget(controller: web)
          else
            _DesktopLocationFallback(
              lat: widget.lat,
              lng: widget.lng,
              onOpenExternal: _openExternal,
            ),
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

/// Fallback для Windows / Linux: показывает координаты + кнопку «Открыть
/// в браузере». Inline-карта недоступна (webview_flutter не реализован
/// на этих платформах).
class _DesktopLocationFallback extends StatelessWidget {
  const _DesktopLocationFallback({
    required this.lat,
    required this.lng,
    required this.onOpenExternal,
  });

  final double lat;
  final double lng;
  final Future<void> Function() onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Карта недоступна на этой платформе.\nОткройте локацию в браузере.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onOpenExternal(),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Открыть в браузере'),
            ),
          ],
        ),
      ),
    );
  }
}
