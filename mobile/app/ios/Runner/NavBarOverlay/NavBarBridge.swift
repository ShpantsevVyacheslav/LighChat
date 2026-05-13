import Flutter
import UIKit

/// MethodChannel + EventChannel bridge for the native nav-bar overlay.
///
/// Contract: see `mobile/app/lib/platform/native_nav_bar/native_nav_bar_facade.dart`
/// and `docs/arcitecture/native-nav-bar.md`.
final class NavBarBridge: NSObject, FlutterStreamHandler {
  static let shared = NavBarBridge()

  private var eventSink: FlutterEventSink?

  func register(messenger: FlutterBinaryMessenger) {
    let method = FlutterMethodChannel(
      name: "lighchat/native_nav", binaryMessenger: messenger)
    method.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    let events = FlutterEventChannel(
      name: "lighchat/native_nav/events", binaryMessenger: messenger)
    events.setStreamHandler(self)

    NavBarOverlayHost.shared.onEvent = { [weak self] type, payload in
      self?.send(type: type, payload: payload)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    NavBarOverlayHost.log("MethodChannel<- \(call.method)")
    DispatchQueue.main.async {
      switch call.method {
      case "setTopBar":
        NavBarOverlayHost.shared.applyTopBar(args)
        result(nil)
      case "setBottomBar":
        NavBarOverlayHost.shared.applyBottomBar(args)
        result(nil)
      case "setSearchMode":
        NavBarOverlayHost.shared.applySearch(args)
        result(nil)
      case "setSelectionMode":
        NavBarOverlayHost.shared.applySelection(args)
        result(nil)
      case "setScrollOffset":
        let offset = (args["contentOffset"] as? NSNumber)?.doubleValue ?? 0
        NavBarOverlayHost.shared.applyScrollOffset(CGFloat(offset))
        result(nil)
      case "setTopBlur":
        let enabled = args["enabled"] as? Bool ?? false
        NavBarOverlayHost.shared.applyTopBlur(enabled: enabled)
        result(nil)
      case "log":
        // Pass-through Dart-логов в NSLog с префиксом `[NavBarOverlay]`,
        // чтобы они появлялись рядом с native-логами в Xcode Console
        // (Flutter debugPrint иногда теряется в фильтрах).
        let msg = args["message"] as? String ?? ""
        NavBarOverlayHost.log(msg)
        result(nil)
      default:
        NavBarOverlayHost.log("MethodChannel<- неизвестный метод \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func send(type: String, payload: [String: Any]) {
    NavBarOverlayHost.log("EventChannel-> \(type) payload=\(payload)")
    DispatchQueue.main.async {
      if self.eventSink == nil {
        NavBarOverlayHost.log("EventChannel-> eventSink==nil, событие потеряно: \(type)")
      }
      self.eventSink?(["type": type, "payload": payload])
    }
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
