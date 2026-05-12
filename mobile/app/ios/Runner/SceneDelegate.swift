import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first
    else { return }

    // Find the FlutterViewController that FlutterSceneDelegate installed and
    // attach the native nav-bar overlay to its view. We avoid swapping root
    // controllers so Flutter view state, keyboard, and engine wiring stay
    // intact.
    DispatchQueue.main.async {
      var vc = window.rootViewController
      while let presented = vc?.presentedViewController {
        vc = presented
      }
      if let host = (vc as? FlutterViewController) ?? findFlutterVC(in: vc) {
        NavBarOverlayHost.shared.attach(to: host)
      }
    }
  }
}

private func findFlutterVC(in vc: UIViewController?) -> FlutterViewController? {
  guard let vc = vc else { return nil }
  if let flutter = vc as? FlutterViewController { return flutter }
  for child in vc.children {
    if let found = findFlutterVC(in: child) { return found }
  }
  return nil
}
