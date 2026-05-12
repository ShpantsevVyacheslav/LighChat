import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // ScreenshotProtectionFacade (Dart) → MethodChannel "lighchat/screenshot_protection".
    // enable: NSWindow.sharingType = .none — окно не появляется в скриншотах /
    // ScreenCaptureKit. disable: возвращаем .readOnly (дефолт).
    // Также блокируем "Open in Mission Control" preview через collectionBehavior.
    let screenshotChannel = FlutterMethodChannel(
      name: "lighchat/screenshot_protection",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    screenshotChannel.setMethodCallHandler { [weak self] call, result in
      guard let window = self else {
        result(FlutterError(code: "no_window", message: "Window deallocated", details: nil))
        return
      }
      switch call.method {
      case "enable":
        window.sharingType = .none
        result(nil)
      case "disable":
        window.sharingType = .readOnly
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NavBarBridge.shared.register(
      messenger: flutterViewController.engine.binaryMessenger)
    NavBarToolbarHost.shared.attach(to: self)

    super.awakeFromNib()
  }
}
