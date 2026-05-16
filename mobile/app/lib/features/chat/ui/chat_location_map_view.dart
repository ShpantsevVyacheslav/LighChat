import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show StandardMessageCodec;

import '../data/google_maps_urls.dart';
import 'chat_cached_network_image.dart';

/// Native MKMapView preview карта для location share (Phase 11).
/// На iOS — нативный Apple Maps через PlatformView; на Android/desktop
/// — fallback на статичный OSM тайл (как было раньше).
///
/// Параметры:
///  - [lat], [lng] — центр и пин
///  - [interactive] — разрешать ли pan/zoom (по умолчанию false для
///    inline-превью в композере)
class ChatLocationMapView extends StatelessWidget {
  const ChatLocationMapView({
    super.key,
    required this.lat,
    required this.lng,
    this.interactive = false,
  });

  final double lat;
  final double lng;
  final bool interactive;

  static const _viewType = 'lighchat/location_map_preview';

  /// HTTP-заголовки для OSM тайлов fallback'а (требует явный User-Agent).
  static const _osmHeaders = <String, String>{
    'User-Agent':
        'LighChatMobile/1.0 (location preview; contact: app)',
  };

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: <String, Object?>{
          'lat': lat,
          'lng': lng,
          'interactive': interactive,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    // Android / desktop — статичный OSM тайл как раньше. Apple Maps
    // нет, MapKit JS можно подключить позже.
    return ChatCachedNetworkImage(
      url: buildChatLocationStaticPreviewUrl(lat, lng),
      httpHeaders: _osmHeaders,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorOverride: const _OsmFallback(),
    );
  }
}

class _OsmFallback extends StatelessWidget {
  const _OsmFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1B1E25),
      child: Center(
        child: Icon(
          Icons.map_outlined,
          color: Colors.white.withValues(alpha: 0.45),
          size: 32,
        ),
      ),
    );
  }
}
