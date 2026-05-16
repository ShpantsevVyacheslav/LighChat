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
  private let channel: FlutterMethodChannel?
  private let interactive: Bool
  private let draggablePin: Bool

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
    mapView.isScrollEnabled = interactive
    mapView.isZoomEnabled = interactive

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

    // Пин-marker. Apple Maps render'ит его в системном стиле.
    if let existing = pinAnnotation {
      mapView.removeAnnotation(existing)
    }
    let pin = MKPointAnnotation()
    pin.coordinate = coord
    mapView.addAnnotation(pin)
    pinAnnotation = pin
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
  }

  // MARK: MKMapViewDelegate

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
