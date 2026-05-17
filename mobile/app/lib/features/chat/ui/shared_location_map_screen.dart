import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../data/google_maps_urls.dart';
import 'chat_location_map_view.dart';
import 'location_live_countdown.dart';

/// `webview_flutter` нет нативной реализации на Windows / Linux — там
/// `WebViewController()` крашит UI ("Unimplemented platform interface").
/// Для этих платформ показываем placeholder + кнопку «Открыть в
/// браузере». На iOS используем нативный MKMapView, на Android и
/// macOS — FlutterMap (OSM, интерактив + polyline трека).
bool get _useInlineMap {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;
}


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
  // Phase 13+: контроллер native MKMapView для recenter-кнопки. Не
  // используется на не-iOS платформах, но безопасен (методы — no-op
  // когда канал ещё не привязан).
  final ChatLocationMapController _mapController =
      ChatLocationMapController();

  /// Distance pill: расстояние «от меня до точки локации». Считается
  /// только когда `senderUidForTracking != null` (т.е. это просмотр
  /// чужой live-локации, не своей). `null` пока не получили fix или
  /// permission denied — pill не рисуется.
  double? _distanceMeters;
  StreamSubscription<Position>? _myPosSub;

  void _hideLoader() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    if (!_loading || !mounted) return;
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initMyPosition());
    // Bug 13+: на iOS и Android карта inline (нативная MKMapView /
    // FlutterMap соответственно) — рендерится мгновенно. WebView+
    // Leaflet оставляем только для macOS-fallback'а и desktop.
    if (_useInlineMap) {
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
    _myPosSub?.cancel();
    super.dispose();
  }

  /// Distance pill — только когда смотрим ЧУЖУЮ live-локацию
  /// (`senderUidForTracking != null`). Своя локация = расстояние 0,
  /// pill бесполезна.
  bool get _showDistance =>
      (widget.senderUidForTracking ?? '').isNotEmpty;

  Future<void> _initMyPosition() async {
    if (!_showDistance) return;
    if (kIsWeb) return;
    try {
      // 1) Быстрый fallback из last-known fix'а (мгновенно). Даже если
      // он слегка устарел, pill даст осмысленное число пока
      // подтянется live-fix.
      final last = await Geolocator.getLastKnownPosition()
          .catchError((_) => null);
      if (last != null && mounted) {
        setState(() => _distanceMeters = _calcDistance(last));
      }
      // 2) Permission + position stream (точный live-fix). distanceFilter=20
      // — обновление при движении >=20м, экономим батарею.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      _myPosSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _distanceMeters = _calcDistance(pos));
      });
    } catch (_) {
      // graceful: pill просто не появится.
    }
  }

  double _calcDistance(Position me) {
    return Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      widget.lat,
      widget.lng,
    );
  }

  String _formatDistance(double meters, AppLocalizations l10n) {
    if (meters < 1000) {
      return l10n.shared_location_distance_meters(meters.round());
    }
    final km = meters / 1000;
    final txt = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return l10n.shared_location_distance_km(txt);
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
          if (_useInlineMap)
            // Bug D + Bug 13: на iOS — нативный Apple MKMapView, на
            // Android — FlutterMap (OSM + polyline). Обе ветки сами
            // рисуют polyline трека по `trackPointsForUid` и поднимают
            // pin по центру.
            ChatLocationMapView(
              lat: widget.lat,
              lng: widget.lng,
              interactive: true,
              trackPointsForUid: widget.senderUidForTracking,
              controller: _mapController,
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
          // Distance pill — поверх карты, по центру сверху. Только
          // для просмотра ЧУЖОЙ live-локации (`senderUidForTracking`
          // != null) и если permission получили fix.
          if (_showDistance && _distanceMeters != null)
            Positioned(
              top: top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: _DistancePill(
                  text: _formatDistance(
                    _distanceMeters!,
                    AppLocalizations.of(context)!,
                  ),
                ),
              ),
            ),
          // Phase 13+: recenter-кнопка для inline-карт (iOS native
          // MKMapView и Android FlutterMap). Показывает весь трек +
          // пин fit-to-rect. Полезна когда user сам зумнул и потерял
          // текущую позицию из view.
          if (_useInlineMap)
            Positioned(
              right: 12,
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
              child: FloatingActionButton.small(
                heroTag: 'shared_loc_recenter',
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () =>
                    unawaited(_mapController.fitToTrack()),
                tooltip: 'Показать весь трек',
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  size: 22,
                ),
              ),
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

/// Pill «N м/км от вас» поверх fullscreen-карты. Glass-blur,
/// тёмный фон + walking-figure icon. Readable на любом стиле карты.
class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_walk_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
