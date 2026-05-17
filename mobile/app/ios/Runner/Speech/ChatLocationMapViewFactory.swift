import Flutter
import Foundation
import MapKit
import UIKit

/// Factory для PlatformView'я нативной MKMapView-превью для location
/// share. Регистрируется в `AppDelegate` под viewType
/// `lighchat/location_map_preview`. Параметры из creationParams:
///  - `lat`: Double — широта центра
///  - `lng`: Double — долгота центра
///  - `interactive`: Bool — разрешать ли pan/zoom (для inline-превью
///    в композере — false, чтобы тапы шли в parent gesture detector).
///
/// **Зачем**: вместо OSM статичной плитки (`ChatCachedNetworkImage`)
/// показываем настоящие Apple Maps — векторные тайлы, 3D-здания,
/// dark-mode parity с системой, satellite-режим (если включить).
/// Это шаг к visual паритету с iMessage "Share My Location".
final class ChatLocationMapViewFactory: NSObject, FlutterPlatformViewFactory {
  static let viewType = "lighchat/location_map_preview"

  /// Flutter messenger используется для создания per-view MethodChannel
  /// (`lighchat/location_map_preview/{viewId}`) — Bug #6 (drag annotation)
  /// и Bug #7 (setCenter from Flutter).
  private weak var messenger: FlutterBinaryMessenger?

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let map = (args as? [String: Any]) ?? [:]
    return ChatLocationMapView(
      frame: frame,
      viewId: viewId,
      args: map,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class ChatLocationMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
  private let container: UIView
  private let mapView: MKMapView
  private var pinAnnotation: MKPointAnnotation?
  private var trackPolyline: MKPolyline?
  private var didFitInitialTrack = false
  private let channel: FlutterMethodChannel?
  private let interactive: Bool
  private let draggablePin: Bool
  /// Center-pin mode: native MKAnnotation скрыт, Flutter рисует
  /// фиксированный пин по центру overlay. Native эмитит
  /// `regionChanged(lat, lng)` при каждом regionDidChange — Dart
  /// обновляет lat/lng + state.
  private var centerPinMode: Bool = false

  /// Throttle для `regionChanged`: MKMapView фаерит
  /// `regionDidChangeAnimated` непрерывно во время pan'а (на каждом
  /// кадре). Если эмитить КАЖДОЕ изменение в Dart — там идёт
  /// setState → rebuild → потенциально пересоздаются recognizers и
  /// карта «залипает». Шлём не чаще ~20Hz во время движения, плюс
  /// финальный snapshot на pan-end (willChange=true→false). Финал
  /// гарантирует, что Dart получит корректную последнюю координату.
  private var lastRegionEmit: CFTimeInterval = 0
  private var isRegionChanging: Bool = false

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any],
    messenger: FlutterBinaryMessenger?
  ) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    mapView = MKMapView(frame: .zero)
    mapView.translatesAutoresizingMaskIntoConstraints = false
    mapView.isRotateEnabled = false
    mapView.isPitchEnabled = false
    mapView.showsCompass = false
    mapView.showsScale = false
    mapView.showsBuildings = true

    interactive = (args["interactive"] as? Bool) ?? false
    draggablePin = (args["draggablePin"] as? Bool) ?? false
    centerPinMode = (args["centerPinMode"] as? Bool) ?? false
    mapView.isScrollEnabled = interactive
    mapView.isZoomEnabled = interactive
    // Center-pin mode (Uber/Bolt-style): пин рисуется Flutter'ом
    // фиксированно по центру overlay, юзер двигает карту жестами.
    // В этом режиме всегда показываем синюю «точку» текущей
    // геолокации пользователя — отдельным маркером (если в viewport
    // и есть permission).
    let showsUser = (args["showsUserLocation"] as? Bool) ?? false
    mapView.showsUserLocation = showsUser || centerPinMode

    if let m = messenger {
      channel = FlutterMethodChannel(
        name: "\(ChatLocationMapViewFactory.viewType)/\(viewId)",
        binaryMessenger: m
      )
    } else {
      channel = nil
    }

    super.init()
    mapView.delegate = self

    container.addSubview(mapView)
    NSLayoutConstraint.activate([
      mapView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      mapView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      mapView.topAnchor.constraint(equalTo: container.topAnchor),
      mapView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    // Bug #7: Flutter может попросить сдвинуть центр (setCenter).
    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "deinit", message: nil, details: nil))
        return
      }
      switch call.method {
      case "setCenter":
        let args = (call.arguments as? [String: Any]) ?? [:]
        let lat = (args["lat"] as? NSNumber)?.doubleValue
        let lng = (args["lng"] as? NSNumber)?.doubleValue
        if let lat = lat, let lng = lng {
          self.setCenter(lat: lat, lng: lng)
          result(nil)
        } else {
          result(FlutterError(
            code: "bad_args", message: "lat/lng required", details: nil))
        }
      case "fitToTrack":
        // Phase 13+: показать весь трек на экране (включая текущий
        // пин) — useful для fullscreen после первого pan. Если
        // overlay'я нет — рекомпонуем регион по пину 350×350м, как
        // дефолт.
        self.fitToTrack()
        result(nil)
      case "setCenterPinMode":
        // Flutter переключил pin-in-center mode. Native прячет
        // свой MKAnnotation; Dart рисует фиксированный пин по
        // центру overlay'я.
        let args = (call.arguments as? [String: Any]) ?? [:]
        let on = (args["on"] as? Bool) ?? false
        self.centerPinMode = on
        self.applyCenterPinMode()
        result(nil)
      case "setPolyline":
        // Bug 13: получатель прислал актуальный track. Заменяем
        // существующий overlay новым (или удаляем если points пуст).
        let args = (call.arguments as? [String: Any]) ?? [:]
        let raw = (args["points"] as? [[String: Any]]) ?? []
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(raw.count)
        for p in raw {
          guard let lat = (p["lat"] as? NSNumber)?.doubleValue,
                let lng = (p["lng"] as? NSNumber)?.doubleValue
          else { continue }
          coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        self.applyPolyline(coords: coords)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    applyArgs(args)
  }

  func view() -> UIView { container }

  private func applyArgs(_ args: [String: Any]) {
    let lat = (args["lat"] as? NSNumber)?.doubleValue ?? 0
    let lng = (args["lng"] as? NSNumber)?.doubleValue ?? 0
    setCenter(lat: lat, lng: lng)
  }

  private func setCenter(lat: Double, lng: Double) {
    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    // Compact zoom — улица + ~3 квартала вокруг. Параллель с iMessage
    // location preview.
    let region = MKCoordinateRegion(
      center: coord,
      latitudinalMeters: 350,
      longitudinalMeters: 350)
    mapView.setRegion(region, animated: true)

    // Пин-marker. В center-pin mode native annotation скрыт —
    // Dart рисует фиксированный pin overlay'ем.
    if let existing = pinAnnotation {
      mapView.removeAnnotation(existing)
      pinAnnotation = nil
    }
    if !centerPinMode {
      let pin = MKPointAnnotation()
      pin.coordinate = coord
      mapView.addAnnotation(pin)
      pinAnnotation = pin
    }
  }

  /// Toggle native annotation visibility под текущий centerPinMode.
  /// Также включаем `showsUserLocation`, чтобы в center-pin режиме
  /// всегда отображалась системная «синяя точка» текущей геопозиции
  /// пользователя (если включён permission).
  private func applyCenterPinMode() {
    if centerPinMode {
      if let existing = pinAnnotation {
        mapView.removeAnnotation(existing)
        pinAnnotation = nil
      }
      mapView.showsUserLocation = true
      // Сразу эмитим текущий центр — чтобы Dart-side засинхронил
      // lat/lng при первом включении pin-mode (без ожидания pan'а).
      let c = mapView.region.center
      channel?.invokeMethod("regionChanged", arguments: [
        "lat": c.latitude,
        "lng": c.longitude,
      ])
    } else if pinAnnotation == nil {
      let pin = MKPointAnnotation()
      pin.coordinate = mapView.region.center
      mapView.addAnnotation(pin)
      pinAnnotation = pin
    }
  }

  /// Phase 13+: animate setRegion на boundingMapRect трека + пина.
  /// Если трека нет — zoomToCurrentPin (compact preview region).
  private func fitToTrack() {
    if let line = trackPolyline, line.pointCount > 0 {
      var rect = line.boundingMapRect
      // Если пин выходит за bounds polyline'а (например, пользователь
      // только начал двигаться и pin = первая точка), расширяем
      // прямоугольник, чтобы пин тоже попал.
      if let pin = pinAnnotation {
        let pinPoint = MKMapPoint(pin.coordinate)
        let pinRect = MKMapRect(x: pinPoint.x, y: pinPoint.y, width: 0, height: 0)
        rect = rect.union(pinRect)
      }
      let padding = UIEdgeInsets(top: 80, left: 60, bottom: 80, right: 60)
      mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
      return
    }
    if let pin = pinAnnotation {
      let region = MKCoordinateRegion(
        center: pin.coordinate,
        latitudinalMeters: 350,
        longitudinalMeters: 350)
      mapView.setRegion(region, animated: true)
    }
  }

  /// Bug 13: применяет новый набор координат как MKPolyline overlay.
  /// Удаляет предыдущий overlay (нет diff'инга — replace cheap для
  /// сотен точек, и Flutter всегда шлёт полный snapshot).
  private func applyPolyline(coords: [CLLocationCoordinate2D]) {
    if let prev = trackPolyline {
      mapView.removeOverlay(prev)
      trackPolyline = nil
    }
    guard coords.count >= 2 else { return }
    let line = MKPolyline(coordinates: coords, count: coords.count)
    mapView.addOverlay(line, level: .aboveRoads)
    trackPolyline = line
    // Первый раз когда появились реальные точки — auto-fit чтобы
    // пользователь видел весь пройденный путь. Следующие updates
    // не двигают view (юзер мог зумнуть/панить).
    if !didFitInitialTrack && interactive {
      didFitInitialTrack = true
      fitToTrack()
    }
  }

  // MARK: MKMapViewDelegate

  /// Center-pin mode: при изменении видимого региона эмитим
  /// `regionChanged(lat,lng)` — текущий центр карты, под которым
  /// Flutter рисует фиксированный пин. Dart-side обновляет
  /// выбранную координату.
  ///
  /// Throttle ~20Hz: между двумя emit'ами должно пройти ≥50мс.
  /// `regionDidChangeAnimated` может фаериться непрерывно во время
  /// pan'а — без throttling Dart-side setState флудит и (несмотря
  /// на стабильный gestureRecognizers Set) добавляет лишнюю
  /// rebuild-нагрузку. На конце gesture гарантированно прилетит
  /// финальный «отсроченный» вызов, который мы пропустим в Dart
  /// уже без cap (см. поле `isRegionChanging`).
  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    isRegionChanging = true
  }

  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    let wasChanging = isRegionChanging
    isRegionChanging = false
    guard centerPinMode else { return }
    let now = CACurrentMediaTime()
    // Throttle continuous frame events до 20Hz, НО финальный emit
    // (end-of-change — wasChanging=true и больше did не следует)
    // пропускаем всегда, чтобы Dart увидел точную последнюю точку.
    if !wasChanging && (now - lastRegionEmit) < 0.05 {
      return
    }
    lastRegionEmit = now
    let c = mapView.region.center
    channel?.invokeMethod("regionChanged", arguments: [
      "lat": c.latitude,
      "lng": c.longitude,
    ])
  }

  /// Bug 13: renderer для MKPolyline — синяя линия 4pt со скруглёнными
  /// концами. Цвет совпадает с Apple-blue (системный action accent).
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let line = overlay as? MKPolyline {
      let r = MKPolylineRenderer(polyline: line)
      r.strokeColor = UIColor.systemBlue.withAlphaComponent(0.92)
      r.lineWidth = 4
      r.lineCap = .round
      r.lineJoin = .round
      return r
    }
    return MKOverlayRenderer(overlay: overlay)
  }

  /// Bug #6: возвращаем MKPinAnnotationView с isDraggable=true когда
  /// флаг включён. Default annotation view без `viewFor` отрисуется
  /// red pin, но без drag-handle.
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKUserLocation { return nil }
    let id = "lighchat.location.pin"
    let view: MKMarkerAnnotationView
    if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView {
      dequeued.annotation = annotation
      view = dequeued
    } else {
      view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
    }
    view.isDraggable = draggablePin
    view.canShowCallout = false
    view.markerTintColor = .systemRed
    return view
  }

  /// Bug #6: после drag-end эмитим pinMoved → Flutter.
  func mapView(
    _ mapView: MKMapView,
    annotationView view: MKAnnotationView,
    didChange newState: MKAnnotationView.DragState,
    fromOldState oldState: MKAnnotationView.DragState
  ) {
    guard newState == .ending || newState == .canceling else { return }
    guard let coord = view.annotation?.coordinate else { return }
    channel?.invokeMethod("pinMoved", arguments: [
      "lat": coord.latitude,
      "lng": coord.longitude,
    ])
  }
}
