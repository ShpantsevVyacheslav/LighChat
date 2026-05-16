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

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let map = (args as? [String: Any]) ?? [:]
    return ChatLocationMapView(frame: frame, args: map)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class ChatLocationMapView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let mapView: MKMapView
  private var pinAnnotation: MKPointAnnotation?

  init(frame: CGRect, args: [String: Any]) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    mapView = MKMapView(frame: .zero)
    mapView.translatesAutoresizingMaskIntoConstraints = false
    mapView.isRotateEnabled = false
    mapView.isPitchEnabled = false
    mapView.showsCompass = false
    mapView.showsScale = false
    mapView.showsBuildings = true

    let interactive = (args["interactive"] as? Bool) ?? false
    mapView.isScrollEnabled = interactive
    mapView.isZoomEnabled = interactive

    super.init()

    container.addSubview(mapView)
    NSLayoutConstraint.activate([
      mapView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      mapView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      mapView.topAnchor.constraint(equalTo: container.topAnchor),
      mapView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    applyArgs(args)
  }

  func view() -> UIView { container }

  private func applyArgs(_ args: [String: Any]) {
    let lat = (args["lat"] as? NSNumber)?.doubleValue ?? 0
    let lng = (args["lng"] as? NSNumber)?.doubleValue ?? 0
    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    // Compact zoom — улица + ~3 квартала вокруг. Параллель с iMessage
    // location preview.
    let region = MKCoordinateRegion(
      center: coord,
      latitudinalMeters: 350,
      longitudinalMeters: 350)
    mapView.setRegion(region, animated: false)

    // Пин-marker. Apple Maps render'ит его в системном стиле
    // (callout disabled — превью статичное).
    if let existing = pinAnnotation {
      mapView.removeAnnotation(existing)
    }
    let pin = MKPointAnnotation()
    pin.coordinate = coord
    mapView.addAnnotation(pin)
    pinAnnotation = pin
  }
}
