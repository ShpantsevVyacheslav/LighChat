import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bug 13+ v3: запрос статичного Apple Maps снимка через native
/// `MKMapSnapshotter`. Используется в `MessageLocationCard` —
/// вместо PlatformView (MKMapView) и OSM-плитки в bubble.
///
/// Native side: [`ChatMapSnapshotBridge.swift`].
/// На non-iOS возвращает null — caller использует OSM fallback.
///
/// In-memory кэш по ключу `lat,lng,w,h,dark`. Размер ограничен
/// `_maxCache` (FIFO eviction). Future-identity стабильна между
/// rebuild'ами bubble — `Image.memory` не дёргает scroll.
class ChatMapSnapshot {
  ChatMapSnapshot._();

  static const _channel = MethodChannel('lighchat/map_snapshot');
  static const _maxCache = 64;

  static final Map<String, Future<Uint8List?>> _cache =
      <String, Future<Uint8List?>>{};
  static final List<String> _cacheOrder = <String>[];

  /// Hash polyline-точек для cache-ключа. Берём кол-во точек +
  /// last-fingerprint (последняя точка с округлением 5 знаков) —
  /// при добавлении новой точки в трек ключ меняется → новый snapshot.
  /// Полный hash 720 точек переоценочно дорого; this approximation
  /// безопасна для трека (новые точки всегда appendятся в конец).
  static String _polylineFingerprint(
    List<({double lat, double lng})> polyline,
  ) {
    if (polyline.isEmpty) return 'none';
    final n = polyline.length;
    final last = polyline.last;
    return '$n@${last.lat.toStringAsFixed(5)},${last.lng.toStringAsFixed(5)}';
  }

  static String _key({
    required double lat,
    required double lng,
    required double width,
    required double height,
    required bool dark,
    required List<({double lat, double lng})> polyline,
  }) {
    return '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)},'
        '${width.toInt()}x${height.toInt()},${dark ? "d" : "l"},'
        '${_polylineFingerprint(polyline)}';
  }

  /// Возвращает PNG bytes или null. Идентичность Future стабильна
  /// для одинаковых аргументов. Если `polyline` непустой — рисуем
  /// трек поверх snapshot, и pin переезжает на последнюю точку.
  static Future<Uint8List?> get({
    required double lat,
    required double lng,
    required double width,
    required double height,
    required double scale,
    required bool dark,
    List<({double lat, double lng})> polyline = const [],
  }) {
    if (!Platform.isIOS) return Future<Uint8List?>.value(null);
    final key = _key(
      lat: lat,
      lng: lng,
      width: width,
      height: height,
      dark: dark,
      polyline: polyline,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    final future = _fetch(lat, lng, width, height, scale, dark, polyline);
    _cache[key] = future;
    _cacheOrder.add(key);
    if (_cacheOrder.length > _maxCache) {
      final evict = _cacheOrder.removeAt(0);
      _cache.remove(evict);
    }
    return future;
  }

  static Future<Uint8List?> _fetch(
    double lat,
    double lng,
    double width,
    double height,
    double scale,
    bool dark,
    List<({double lat, double lng})> polyline,
  ) async {
    try {
      final raw = await _channel.invokeMethod<Uint8List>('snapshot', {
        'lat': lat,
        'lng': lng,
        'width': width,
        'height': height,
        'scale': scale,
        'dark': dark,
        if (polyline.isNotEmpty)
          'polyline': polyline
              .map((p) => <String, Object?>{'lat': p.lat, 'lng': p.lng})
              .toList(growable: false),
      });
      return raw;
    } on PlatformException catch (e) {
      debugPrint('[map-snap] PlatformException: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
