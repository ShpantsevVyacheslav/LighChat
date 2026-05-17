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

  static String _key({
    required double lat,
    required double lng,
    required double width,
    required double height,
    required bool dark,
  }) {
    return '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)},'
        '${width.toInt()}x${height.toInt()},${dark ? "d" : "l"}';
  }

  /// Возвращает PNG bytes или null. Идентичность Future стабильна
  /// для одинаковых аргументов.
  static Future<Uint8List?> get({
    required double lat,
    required double lng,
    required double width,
    required double height,
    required double scale,
    required bool dark,
  }) {
    if (!Platform.isIOS) return Future<Uint8List?>.value(null);
    final key = _key(
      lat: lat,
      lng: lng,
      width: width,
      height: height,
      dark: dark,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    final future = _fetch(lat, lng, width, height, scale, dark);
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
  ) async {
    try {
      final raw = await _channel.invokeMethod<Uint8List>('snapshot', {
        'lat': lat,
        'lng': lng,
        'width': width,
        'height': height,
        'scale': scale,
        'dark': dark,
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
