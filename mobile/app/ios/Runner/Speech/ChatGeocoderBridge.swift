import CoreLocation
import Flutter
import Foundation

/// MethodChannel `lighchat/geocoder` для CLGeocoder reverse-lookup
/// координат → форматированный адрес («ул. Ерёменко 60, Ростов-на-Дону»).
/// Используется в превью карты location share — паритет с iMessage,
/// который под картой показывает адрес, не сырые координаты.
///
/// Apple ограничивает частоту запросов (~50/мин на устройство), поэтому
/// Dart-side кэширует результаты в `ChatLocationAddressCache`.
///
/// Методы:
///   - `reverseGeocode(lat, lng, locale?) → String?`
///     Возвращает форматированный адрес или nil если geocoder не нашёл
///     ничего (океан / Антарктида / no-network в полётном режиме).
final class ChatGeocoderBridge: NSObject {
  static let shared = ChatGeocoderBridge()
  private let geocoder = CLGeocoder()

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/geocoder", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(
    call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    switch call.method {
    case "reverseGeocode":
      let args = (call.arguments as? [String: Any]) ?? [:]
      guard let lat = (args["lat"] as? NSNumber)?.doubleValue,
        let lng = (args["lng"] as? NSNumber)?.doubleValue
      else {
        result(FlutterError(
          code: "bad_args",
          message: "lat/lng required",
          details: nil))
        return
      }
      let localeCode = args["locale"] as? String
      let location = CLLocation(latitude: lat, longitude: lng)
      let locale = localeCode.flatMap { Locale(identifier: $0) }

      let completion: ([CLPlacemark]?, Error?) -> Void = { placemarks, error in
        if let error = error {
          // CLError.network / .geocodeFoundNoResult — не считаем фатальной
          // ошибкой, отдаём nil чтобы Dart показал сырые координаты.
          NSLog("[geocoder] reverseGeocode error: \(error.localizedDescription)")
          result(nil)
          return
        }
        guard let first = placemarks?.first else {
          result(nil)
          return
        }
        result(Self.formatPlacemark(first))
      }

      if #available(iOS 11.0, *), let l = locale {
        geocoder.reverseGeocodeLocation(
          location, preferredLocale: l, completionHandler: completion)
      } else {
        geocoder.reverseGeocodeLocation(
          location, completionHandler: completion)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Форматирует CLPlacemark в стиле iMessage: `«улица номер,
  /// город»` если есть thoroughfare; иначе fallback на name/locality.
  private static func formatPlacemark(_ p: CLPlacemark) -> String? {
    // Компактная форма как у iMessage: «street + number, city».
    var line = ""
    if let street = p.thoroughfare, !street.isEmpty {
      line = street
      if let num = p.subThoroughfare, !num.isEmpty {
        line += " \(num)"
      }
    } else if let name = p.name, !name.isEmpty {
      line = name
    }
    let city = p.locality ?? p.subLocality ?? p.administrativeArea
    if let c = city, !c.isEmpty {
      if line.isEmpty {
        line = c
      } else {
        line = "\(line), \(c)"
      }
    }
    return line.isEmpty ? nil : line
  }
}
