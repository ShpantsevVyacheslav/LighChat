import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';

/// Wrapper над CLGeocoder bridge (iOS only). Reverse-geocodes
/// `(lat, lng)` в форматированный адрес типа «ул. Ерёменко 60,
/// Ростов-на-Дону» — паритет с iMessage location preview.
///
/// На Android/desktop возвращает null (вызывающий показывает сырые
/// координаты).
///
/// Apple жёстко лимитит частоту запросов CLGeocoder (~50 / минуту /
/// устройство). Поэтому:
///  - Дёргаем максимум 1 запрос на координатную пару (округлено до
///    1e-5 градуса — это ~1 метр, для preview точность избыточна).
///  - Кэшируем результат in-memory `_cache` пока приложение живёт.
///  - In-flight запросы de-dup'аются через `_inFlight`.
class ChatLocationGeocoder {
  ChatLocationGeocoder._();
  static final ChatLocationGeocoder instance = ChatLocationGeocoder._();

  static const _channel = MethodChannel('lighchat/geocoder');

  final Map<String, String?> _cache = <String, String?>{};
  final Map<String, Future<String?>> _inFlight = <String, Future<String?>>{};

  /// Возвращает форматированный адрес или null если geocoder не нашёл
  /// (океан / Антарктида / нет сети) или платформа не поддерживается.
  /// Использует системную локаль устройства для языка ответа.
  Future<String?> reverseGeocode(double lat, double lng) async {
    if (!Platform.isIOS) return null;
    final key = _cacheKey(lat, lng);
    if (_cache.containsKey(key)) return _cache[key];
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final locale = PlatformDispatcher.instance.locale.toLanguageTag();
    final future = _doReverseGeocode(lat, lng, locale).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    final result = await future;
    _cache[key] = result;
    return result;
  }

  Future<String?> _doReverseGeocode(
    double lat,
    double lng,
    String locale,
  ) async {
    try {
      final raw = await _channel.invokeMethod<String?>('reverseGeocode', {
        'lat': lat,
        'lng': lng,
        'locale': locale,
      });
      return raw;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Округляем до 5 знаков после запятой (~1м точность) — большинство
  /// запросов на близкие координаты схлопывается в один кэш-hit.
  String _cacheKey(double lat, double lng) {
    return '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
  }
}
