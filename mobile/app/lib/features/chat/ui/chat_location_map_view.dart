import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, StandardMessageCodec;
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../data/google_maps_urls.dart';
import '../data/location_scroll_diagnostics.dart';
import 'chat_cached_network_image.dart';

/// Tuple-like возвращаемое значение `onPinMoved` callback.
typedef ChatLocationPinPosition = ({double lat, double lng});

/// Контроллер для одной MKMapView-инстанции. Позволяет caller'у
/// программно сдвинуть центр (например, после forward-геокодирования
/// введённого в композере адреса — Bug #7).
class ChatLocationMapController {
  MethodChannel? _channel;
  Future<void> Function()? _fitToTrackOverride;

  void _bind(MethodChannel channel) {
    _channel = channel;
  }

  /// Android FlutterMap-state регистрирует свой fitToTrack-impl
  /// здесь, чтобы recenter-кнопка работала и без MethodChannel'а
  /// (iOS использует только channel-путь).
  void _bindFitToTrackOverride(Future<void> Function()? impl) {
    _fitToTrackOverride = impl;
  }

  Future<void> setCenter({required double lat, required double lng}) async {
    await _channel?.invokeMethod<void>('setCenter', <String, Object?>{
      'lat': lat,
      'lng': lng,
    });
  }

  /// iMessage / Uber-style center-pin: Flutter рисует фиксированный
  /// пин по центру overlay'я, native MKAnnotation скрывается, и
  /// native начинает эмитить `regionChanged(lat,lng)` при каждом
  /// панорамировании карты — выбранная координата = центр.
  Future<void> setCenterPinMode(bool on) async {
    await _channel?.invokeMethod<void>('setCenterPinMode', <String, Object?>{
      'on': on,
    });
  }

  /// Bug 13: пересоздаёт MKPolyline overlay из переданного списка
  /// точек (lat,lng). Пустой список — удаляет overlay. Native side
  /// сам решает `fitOverlay` для региона (центрируем по последней
  /// точке, чтобы пин и pin совпадали).
  Future<void> setPolyline(List<ChatLocationPinPosition> points) async {
    final coords = points
        .map((p) => <String, Object?>{'lat': p.lat, 'lng': p.lng})
        .toList(growable: false);
    await _channel?.invokeMethod<void>('setPolyline', <String, Object?>{
      'points': coords,
    });
  }

  /// Phase 13+: показать на экране весь трек (если есть) + пин.
  /// Если трека нет — вернёт пина с дефолтным compact-зумом 350м.
  Future<void> fitToTrack() async {
    final override = _fitToTrackOverride;
    if (override != null) {
      await override();
      return;
    }
    await _channel?.invokeMethod<void>('fitToTrack');
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
    this.centerPinMode = false,
    this.showsUserLocation = false,
    this.onPinMoved,
    this.onMapCenterChanged,
    this.controller,
    this.trackPointsForUid,
  });

  final double lat;
  final double lng;
  final bool interactive;
  final bool draggablePin;

  /// Uber/Bolt/iMessage Send-Pin режим: native MKMapView НЕ рисует
  /// MKAnnotation; пин рисуется Flutter'ом фиксированно по центру
  /// overlay'я. При pan'е карты native эмитит `regionChanged` →
  /// [onMapCenterChanged] получает новую координату центра.
  final bool centerPinMode;

  /// Показывать ли системную «синюю точку» текущей геопозиции
  /// пользователя (Apple `MKMapView.showsUserLocation`). В
  /// center-pin режиме включается автоматически.
  final bool showsUserLocation;

  final ValueChanged<ChatLocationPinPosition>? onPinMoved;

  /// Center-pin mode: native эмитит lat/lng центра при каждом
  /// regionDidChange. Caller обновляет своё состояние «текущая
  /// выбранная точка».
  final ValueChanged<ChatLocationPinPosition>? onMapCenterChanged;

  final ChatLocationMapController? controller;

  /// Bug 13: если задан — подписываемся на sub-collection
  /// `users/{uid}/liveLocationTrackPoints` и рисуем MKPolyline
  /// overlay из пройденных точек. Перерисовываем на каждый snapshot
  /// (Firestore сам диффает, оверхеда нет). Null — overlay не
  /// создаётся (статичная точка как раньше).
  final String? trackPointsForUid;

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
  StreamSubscription<QuerySnapshot<Map<String, Object?>>>? _trackSub;
  final ChatLocationMapController _internalController =
      ChatLocationMapController();
  // Android/desktop: локальное состояние track-полилайна для
  // FlutterMap. На iOS overlay делает native MKMapView через
  // controller — этот список просто не используется в build'е.
  List<ChatLocationPinPosition> _trackPoints =
      const <ChatLocationPinPosition>[];
  final MapController _flutterMapController = MapController();

  /// КРИТИЧНО: gestureRecognizers Set ДОЛЖЕН быть стабильным между
  /// build'ами. Если каждый build создаёт новый Set с новыми Factory
  /// (closure'ами), Flutter PlatformView pipeline пересоздаёт
  /// `EagerGestureRecognizer` на каждом rebuild → при setState
  /// (например, после `regionChanged` в center-pin mode) recognizers
  /// диспоузятся, и следующий pan/zoom не доходит до MKMapView. Юзер
  /// видит «карта залипла, жесты не работают». Создаём один раз и
  /// переиспользуем.
  late final Set<Factory<OneSequenceGestureRecognizer>> _eagerGestureSet =
      <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
  };
  static const Set<Factory<OneSequenceGestureRecognizer>>
      _emptyGestureSet = <Factory<OneSequenceGestureRecognizer>>{};

  ChatLocationMapController get _effectiveController =>
      widget.controller ?? _internalController;

  void _onPlatformViewCreated(int id) {
    final ch = MethodChannel(
      '${ChatLocationMapView._viewType}/$id',
    );
    _channel = ch;
    widget.controller?._bind(ch);
    _internalController._bind(ch);
    ch.setMethodCallHandler((call) async {
      if (call.method == 'pinMoved') {
        final args = call.arguments as Map<Object?, Object?>?;
        if (args == null) return null;
        final lat = (args['lat'] as num?)?.toDouble();
        final lng = (args['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        debugPrint('[map-view] pinMoved lat=$lat lng=$lng');
        widget.onPinMoved?.call((lat: lat, lng: lng));
      } else if (call.method == 'regionChanged') {
        // Center-pin mode: native шлёт центр на каждый pan/zoom-end.
        // Caller (share-panel) обновляет «текущую выбранную»
        // координату, чтобы при tap «Send Pin» отправить её.
        final args = call.arguments as Map<Object?, Object?>?;
        if (args == null) return null;
        final lat = (args['lat'] as num?)?.toDouble();
        final lng = (args['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        widget.onMapCenterChanged?.call((lat: lat, lng: lng));
      }
      return null;
    });
    // Если уже подписаны на trackPoints (subscribe сделал
    // didUpdateWidget / initState до того как PlatformView был
    // создан) — push последнего значения уже отрисуется автоматом
    // в _onTrackSnapshot.
  }

  @override
  void initState() {
    super.initState();
    _subscribeToTrackPointsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ChatLocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // controller-rebind при смене инстанса
    if (oldWidget.controller != widget.controller && _channel != null) {
      widget.controller?._bind(_channel!);
    }
    if (oldWidget.trackPointsForUid != widget.trackPointsForUid) {
      if (_trackSub != null) {
        LocationScrollDiag.trackUnsubscribe();
      }
      _trackSub?.cancel();
      _trackSub = null;
      _subscribeToTrackPointsIfNeeded();
    }
    // Center-pin mode toggled — пушим в native (он скрывает/показывает
    // MKAnnotation и включает showsUserLocation).
    if (oldWidget.centerPinMode != widget.centerPinMode) {
      unawaited(_effectiveController.setCenterPinMode(widget.centerPinMode));
    }
  }

  @override
  void dispose() {
    if (_trackSub != null) {
      LocationScrollDiag.trackUnsubscribe();
    }
    _trackSub?.cancel();
    super.dispose();
  }

  void _subscribeToTrackPointsIfNeeded() {
    final uid = widget.trackPointsForUid;
    if (uid == null || uid.isEmpty) return;
    LocationScrollDiag.trackSubscribe();
    _trackSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('liveLocationTrackPoints')
        .orderBy('ts')
        .limitToLast(720)
        .snapshots()
        .listen(_onTrackSnapshot, onError: (Object e, StackTrace _) {
      debugPrint('[map-view] track snapshot error: $e');
    });
  }

  void _onTrackSnapshot(QuerySnapshot<Map<String, Object?>> snap) {
    final points = <ChatLocationPinPosition>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      points.add((lat: lat, lng: lng));
    }
    debugPrint('[map-view] polyline update: ${points.length} points');
    // iOS: рисует native MKMapView через MethodChannel.
    unawaited(_effectiveController.setPolyline(points));
    // Android/desktop: FlutterMap пере-рендерит PolylineLayer через
    // setState. На iOS можно тоже хранить — не помешает (build на
    // iOS использует UiKitView, FlutterMap не строится).
    if (!Platform.isIOS && mounted) {
      setState(() => _trackPoints = points);
    }
  }

  @override
  Widget build(BuildContext context) {
    LocationScrollDiag.tickMapBuild();
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
              'centerPinMode': widget.centerPinMode,
              'showsUserLocation':
                  widget.showsUserLocation || widget.centerPinMode,
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
            // Bug F: для interactive-карты внутри ListView чата
            // подключаем EagerGestureRecognizer — Flutter gesture
            // arena сразу отдаёт pan-gesture MKMapView. Без него
            // ListView выигрывает арену и MKMapView не получает
            // pan/zoom, выглядя статичной.
            //
            // ВАЖНО: используем кешированный Set (см. поле
            // `_eagerGestureSet`), чтобы не пересоздавать recognizers
            // на каждом rebuild'е — иначе после первого
            // `regionChanged` + setState карта «залипает».
            gestureRecognizers:
                widget.interactive ? _eagerGestureSet : _emptyGestureSet,
          );
        },
      );
    }
    // Android / desktop: интерактивная FlutterMap с OSM тайлами,
    // pin-маркер по центру + polyline overlay если есть трек.
    // Bug 13: на Android получатель теперь видит pan/zoom +
    // нарисованный пройденный путь — паритет с iOS MKMapView.
    if (widget.interactive ||
        widget.draggablePin ||
        widget.trackPointsForUid != null) {
      return _AndroidFlutterMap(
        lat: widget.lat,
        lng: widget.lng,
        interactive: widget.interactive,
        draggablePin: widget.draggablePin,
        trackPoints: _trackPoints,
        controller: _flutterMapController,
        externalController: _effectiveController,
        onPinDragEnd: widget.onPinMoved,
      );
    }
    // Inline-preview в композере / других местах где нужна только
    // картинка (без gestures) — статичный OSM тайл, дёшево.
    return ChatCachedNetworkImage(
      url: buildChatLocationStaticPreviewUrl(widget.lat, widget.lng),
      httpHeaders: ChatLocationMapView._osmHeaders,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorOverride: const _OsmFallback(),
    );
  }
}

/// Bug 13: интерактивная карта на Android / desktop через
/// `flutter_map` (OSM тайлы, не требует API ключа). Полный паритет
/// с iOS MKMapView: pin по центру, опциональный polyline трека,
/// центрирование на (lat,lng).
class _AndroidFlutterMap extends StatefulWidget {
  const _AndroidFlutterMap({
    required this.lat,
    required this.lng,
    required this.interactive,
    required this.draggablePin,
    required this.trackPoints,
    required this.controller,
    required this.externalController,
    this.onPinDragEnd,
  });

  final double lat;
  final double lng;
  final bool interactive;
  final bool draggablePin;
  final List<ChatLocationPinPosition> trackPoints;
  final MapController controller;
  final ChatLocationMapController externalController;
  final ValueChanged<ChatLocationPinPosition>? onPinDragEnd;

  @override
  State<_AndroidFlutterMap> createState() => _AndroidFlutterMapState();
}

class _AndroidFlutterMapState extends State<_AndroidFlutterMap> {
  late ll.LatLng _pin;
  bool _didFitTrack = false;

  @override
  void initState() {
    super.initState();
    _pin = ll.LatLng(widget.lat, widget.lng);
    widget.externalController._bindFitToTrackOverride(_fitToTrackAsync);
  }

  @override
  void dispose() {
    widget.externalController._bindFitToTrackOverride(null);
    super.dispose();
  }

  Future<void> _fitToTrackAsync() async {
    if (!mounted) return;
    _fitToTrack();
  }

  @override
  void didUpdateWidget(covariant _AndroidFlutterMap old) {
    super.didUpdateWidget(old);
    if (old.lat != widget.lat || old.lng != widget.lng) {
      _pin = ll.LatLng(widget.lat, widget.lng);
    }
    // Авто-fit на первом непустом snapshot (паритет iOS native
    // applyPolyline). Дальше user сам управляет zoom'ом.
    if (!_didFitTrack &&
        widget.trackPoints.length >= 2 &&
        widget.interactive) {
      _didFitTrack = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitToTrack();
      });
    }
  }

  void _fitToTrack() {
    final pts = widget.trackPoints;
    if (pts.length < 2) return;
    final coords = <ll.LatLng>[
      _pin,
      for (final p in pts) ll.LatLng(p.lat, p.lng),
    ];
    final bounds = LatLngBounds.fromPoints(coords);
    widget.controller.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.trackPoints;
    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: _pin,
        initialZoom: 16,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.flingAnimation
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'online.lighchat.app',
          // OSM Foundation tiles требуют явный User-Agent.
          tileProvider: NetworkTileProvider(
            headers: const {
              'User-Agent':
                  'LighChatMobile/1.0 (flutter_map; contact: app)',
            },
          ),
        ),
        if (pts.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [for (final p in pts) ll.LatLng(p.lat, p.lng)],
                color: const Color(0xFF1E88E5).withValues(alpha: 0.92),
                strokeWidth: 4,
                borderStrokeWidth: 0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: _pin,
              width: 36,
              height: 36,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onPanEnd: widget.draggablePin && widget.onPinDragEnd != null
                    ? (_) => widget.onPinDragEnd!(
                          (lat: _pin.latitude, lng: _pin.longitude),
                        )
                    : null,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFD32F2F),
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ],
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
