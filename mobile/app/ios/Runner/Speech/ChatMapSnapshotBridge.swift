import Flutter
import MapKit
import UIKit

/// Bug 13+ v3: MKMapSnapshotter bridge — рендерит Apple Maps в
/// UIImage без PlatformView. Используется в `MessageLocationCard`
/// для inline-bubble: статичный snapshot дешевле, чем живая
/// MKMapView через PlatformView (которая создавалась+уничтожалась
/// на каждом recycle в ListView и спамила `CAMetalLayer
/// setDrawableSize 0×0` + `Resetting GeoCSS zone allocator`).
///
/// Channel: `lighchat/map_snapshot`
/// Method:  `snapshot`
/// Args:
///   - `lat`: Double
///   - `lng`: Double
///   - `width`: Double — pt
///   - `height`: Double — pt
///   - `scale`: Double — devicePixelRatio (для retina)
///   - `dark`: Bool — рисовать ли в dark mode trait
/// Result: `Uint8List` (PNG bytes) | nil on error.
///
/// MKMapSnapshotter сам кэшируется внутри iOS — повторный вызов
/// для близких координат отрабатывает быстро. Dart-side ещё
/// кэширует результаты по ключу `lat,lng,size,dark`.
final class ChatMapSnapshotBridge: NSObject {
  static let shared = ChatMapSnapshotBridge()

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/map_snapshot", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(
    call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    guard call.method == "snapshot" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let args = (call.arguments as? [String: Any]) ?? [:]
    guard let lat = (args["lat"] as? NSNumber)?.doubleValue,
      let lng = (args["lng"] as? NSNumber)?.doubleValue,
      let w = (args["width"] as? NSNumber)?.doubleValue,
      let h = (args["height"] as? NSNumber)?.doubleValue
    else {
      result(FlutterError(
        code: "bad_args", message: "lat/lng/width/height required",
        details: nil))
      return
    }
    let scale = (args["scale"] as? NSNumber)?.doubleValue ?? 2.0
    let dark = (args["dark"] as? Bool) ?? false
    // Bug 13+ v4: polyline overlay в snapshot. Если передан непустой
    // массив, рисуем UIBezierPath поверх snapshot.image через
    // snapshot.point(for:) — координата → CGPoint.
    let polylineRaw = (args["polyline"] as? [[String: Any]]) ?? []
    var polylineCoords: [CLLocationCoordinate2D] = []
    polylineCoords.reserveCapacity(polylineRaw.count)
    for p in polylineRaw {
      guard let plat = (p["lat"] as? NSNumber)?.doubleValue,
            let plng = (p["lng"] as? NSNumber)?.doubleValue
      else { continue }
      polylineCoords.append(
        CLLocationCoordinate2D(latitude: plat, longitude: plng))
    }

    let options = MKMapSnapshotter.Options()
    // Если есть polyline — fit region на bounding (pin + все точки).
    // Иначе — compact 350×350m по pin'у.
    let centerCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    if polylineCoords.count >= 2 {
      var minLat = lat, maxLat = lat, minLng = lng, maxLng = lng
      for c in polylineCoords {
        if c.latitude < minLat { minLat = c.latitude }
        if c.latitude > maxLat { maxLat = c.latitude }
        if c.longitude < minLng { minLng = c.longitude }
        if c.longitude > maxLng { maxLng = c.longitude }
      }
      let span = MKCoordinateSpan(
        // +30% padding, минимум 0.003° (~330м)
        latitudeDelta: max((maxLat - minLat) * 1.3, 0.003),
        longitudeDelta: max((maxLng - minLng) * 1.3, 0.003))
      options.region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
          latitude: (minLat + maxLat) / 2,
          longitude: (minLng + maxLng) / 2),
        span: span)
    } else {
      options.region = MKCoordinateRegion(
        center: centerCoord,
        latitudinalMeters: 350,
        longitudinalMeters: 350)
    }
    options.size = CGSize(width: w, height: h)
    options.scale = CGFloat(scale)
    if #available(iOS 13.0, *) {
      options.traitCollection = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: dark ? .dark : .light),
      ])
      options.mapType = .standard
      options.pointOfInterestFilter = .includingAll
      options.showsBuildings = true
    }

    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.start(with: .global(qos: .userInitiated)) { snapshot, error in
      if let error = error {
        NSLog("[map-snap] error: \(error.localizedDescription)")
        DispatchQueue.main.async { result(nil) }
        return
      }
      guard let snapshot = snapshot else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      // Накладываем красный pin в центре. Поскольку
      // MKAnnotationView нативно недоступен в snapshot'е, рисуем
      // системную SF Symbol «mappin.and.ellipse» вручную через
      // CoreGraphics.
      let img = snapshot.image
      UIGraphicsBeginImageContextWithOptions(img.size, true, img.scale)
      img.draw(at: .zero)
      // Polyline overlay — синий path 3pt + полупрозрачная подложка
      // (rim 5pt) для контраста на любом стиле карты. Рендерим до пина
      // чтобы pin был сверху.
      if polylineCoords.count >= 2 {
        var points: [CGPoint] = []
        points.reserveCapacity(polylineCoords.count)
        for c in polylineCoords {
          let pt = snapshot.point(for: c)
          if pt.x.isFinite && pt.y.isFinite {
            points.append(pt)
          }
        }
        if points.count >= 2 {
          let strokeWidth: CGFloat = 3 * img.scale / CGFloat(scale)
          let rimWidth: CGFloat = strokeWidth + 2
          let path = UIBezierPath()
          path.move(to: points.first!)
          for p in points.dropFirst() {
            path.addLine(to: p)
          }
          // rim (полупрозрачный белый под низ)
          UIColor.white.withAlphaComponent(0.55).setStroke()
          path.lineWidth = rimWidth
          path.lineCapStyle = .round
          path.lineJoinStyle = .round
          path.stroke()
          // основной stroke
          UIColor.systemBlue.withAlphaComponent(0.95).setStroke()
          path.lineWidth = strokeWidth
          path.stroke()
        }
      }
      // Пин в центре, но если есть polyline — pin рисуем над
      // ПОСЛЕДНЕЙ точкой трека (это текущая позиция отправителя).
      let pinTargetCoord = polylineCoords.last ?? centerCoord
      let pinScreenPoint = snapshot.point(for: pinTargetCoord)
      let pinSize: CGFloat = 32 * img.scale / CGFloat(scale)
      // pin рисуется так чтобы tip смотрел в pinTargetCoord. Для
      // SF Symbol `mappin.circle.fill` визуальный tip ~центр-низ.
      let pinX = pinScreenPoint.x - pinSize / 2
      let pinY = pinScreenPoint.y - pinSize * 0.9
      let pinRect = CGRect(x: pinX, y: pinY, width: pinSize, height: pinSize)
      if #available(iOS 13.0, *) {
        let cfg = UIImage.SymbolConfiguration(
          pointSize: pinSize * 0.9, weight: .bold)
        let pin = UIImage(
          systemName: "mappin.circle.fill",
          withConfiguration: cfg)?
          .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        pin?.draw(in: pinRect)
      } else {
        UIColor.systemRed.setFill()
        UIBezierPath(ovalIn: pinRect).fill()
      }
      let composed = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      guard let png = composed?.pngData() else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      DispatchQueue.main.async {
        result(FlutterStandardTypedData(bytes: png))
      }
    }
  }
}
