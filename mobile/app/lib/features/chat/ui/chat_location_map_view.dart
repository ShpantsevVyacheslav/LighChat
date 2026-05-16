import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, StandardMessageCodec;
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;

import '../data/google_maps_urls.dart';
import 'chat_cached_network_image.dart';

/// Tuple-like возвращаемое значение `onPinMoved` callback.
typedef ChatLocationPinPosition = ({double lat, double lng});

/// Контроллер для одной MKMapView-инстанции. Позволяет caller'у
/// программно сдвинуть центр (например, после forward-геокодирования
/// введённого в композере адреса — Bug #7).
class ChatLocationMapController {
  MethodChannel? _channel;

  void _bind(MethodChannel channel) {
    _channel = channel;
  }

  Future<void> setCenter({required double lat, required double lng}) async {
    await _channel?.invokeMethod<void>('setCenter', <String, Object?>{
      'lat': lat,
      'lng': lng,
    });
  }
}

/// Native MKMapView preview карта для location share (Phase 11).
/// На iOS — нативный Apple Maps через PlatformView; на Android/desktop
/// — fallback на статичный OSM тайл (как было раньше).
///
/// Параметры:
///  - [lat], [lng] — центр и пин
///  - [interactive] — разрешать ли pan/zoom (по умолчанию false для
///    inline-превью в композере)
///  - [draggablePin] — Bug #6: разрешить пользователю перетащить пин
///    по карте; native side ставит `pin.isDraggable = true` + слушает
///    didChange:newState=.ending и эмитит `pinMoved` событие.
///  - [onPinMoved] — Bug #6: callback с новыми координатами после
///    drag-end. Если null — событие игнорируется.
///  - [controller] — Bug #7: caller может вызвать setCenter(lat,lng)
///    для программного сдвига карты (forward geocoding по composer
///    text).
class ChatLocationMapView extends StatefulWidget {
  const ChatLocationMapView({
    super.key,
    required this.lat,
    required this.lng,
    this.interactive = false,
    this.draggablePin = false,
    this.onPinMoved,
    this.controller,
  });

  final double lat;
  final double lng;
  final bool interactive;
  final bool draggablePin;
  final ValueChanged<ChatLocationPinPosition>? onPinMoved;
  final ChatLocationMapController? controller;

  static const _viewType = 'lighchat/location_map_preview';

  /// HTTP-заголовки для OSM тайлов fallback'а (требует явный User-Agent).
  static const _osmHeaders = <String, String>{
    'User-Agent':
        'LighChatMobile/1.0 (location preview; contact: app)',
  };

  @override
  State<ChatLocationMapView> createState() => _ChatLocationMapViewState();
}

class _ChatLocationMapViewState extends State<ChatLocationMapView> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    final ch = MethodChannel(
      '${ChatLocationMapView._viewType}/$id',
    );
    _channel = ch;
    widget.controller?._bind(ch);
    ch.setMethodCallHandler((call) async {
      if (call.method == 'pinMoved') {
        final args = call.arguments as Map<Object?, Object?>?;
        if (args == null) return null;
        final lat = (args['lat'] as num?)?.toDouble();
        final lng = (args['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        debugPrint('[map-view] pinMoved lat=$lat lng=$lng');
        widget.onPinMoved?.call((lat: lat, lng: lng));
      }
      return null;
    });
  }

  @override
  void didUpdateWidget(covariant ChatLocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // controller-rebind при смене инстанса
    if (oldWidget.controller != widget.controller && _channel != null) {
      widget.controller?._bind(_channel!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // UiKitView рендерится через PlatformView pipeline; при zero/<1
      // ширине или высоте Flutter генерит invalid matrix («TransformLayer
      // is constructed with an invalid matrix» — спам в логах). Guard
      // через LayoutBuilder: если constraints не realized, показываем
      // нейтральный плейсхолдер вместо PlatformView.
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (!w.isFinite || !h.isFinite || w < 1 || h < 1) {
            return const _OsmFallback();
          }
          return UiKitView(
            viewType: ChatLocationMapView._viewType,
            creationParams: <String, Object?>{
              'lat': widget.lat,
              'lng': widget.lng,
              'interactive': widget.interactive,
              'draggablePin': widget.draggablePin,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
            // Bug #5: интерактивная карта должна жадно перехватывать
            // pan/zoom. Для preview (inline в композере над клавиатурой)
            // оставляем transparent — gestures должны падать на нижний
            // gesture-detector (закрытие popover'а и т.п.).
            hitTestBehavior: widget.interactive
                ? PlatformViewHitTestBehavior.opaque
                : PlatformViewHitTestBehavior.transparent,
          );
        },
      );
    }
    // Android / desktop — статичный OSM тайл как раньше. Apple Maps
    // нет, MapKit JS можно подключить позже.
    return ChatCachedNetworkImage(
      url: buildChatLocationStaticPreviewUrl(widget.lat, widget.lng),
      httpHeaders: ChatLocationMapView._osmHeaders,
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
