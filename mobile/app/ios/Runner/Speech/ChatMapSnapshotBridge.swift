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

    let options = MKMapSnapshotter.Options()
    options.region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
      latitudinalMeters: 350,
      longitudinalMeters: 350)
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
      let pinSize: CGFloat = 32 * img.scale / CGFloat(scale)
      let pinX = (img.size.width - pinSize) / 2
      // pin рисуем чуть выше центра, чтобы tip пина смотрел на точку
      let pinY = (img.size.height - pinSize) / 2 - pinSize * 0.4
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
