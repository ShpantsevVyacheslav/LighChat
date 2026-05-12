import AppKit
import FlutterMacOS

/// MethodChannel + EventChannel bridge mirroring the iOS NavBarBridge.
/// Wraps `NavBarToolbarHost` so the Dart facade can drive native UI on macOS.
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

    NavBarToolbarHost.shared.onEvent = { [weak self] type, payload in
      self?.send(type: type, payload: payload)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    DispatchQueue.main.async {
      switch call.method {
      case "setTopBar":
        NavBarToolbarHost.shared.applyTopBar(args)
        result(nil)
      case "setBottomBar":
        NavBarToolbarHost.shared.applyBottomBar(args)
        result(nil)
      case "setSearchMode":
        NavBarToolbarHost.shared.applySearch(args)
        result(nil)
      case "setSelectionMode":
        NavBarToolbarHost.shared.applySelection(args)
        result(nil)
      case "setScrollOffset":
        let offset = (args["contentOffset"] as? NSNumber)?.doubleValue ?? 0
        NavBarToolbarHost.shared.applyScrollOffset(CGFloat(offset))
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func send(type: String, payload: [String: Any]) {
    DispatchQueue.main.async {
      self.eventSink?(["type": type, "payload": payload])
    }
  }

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
