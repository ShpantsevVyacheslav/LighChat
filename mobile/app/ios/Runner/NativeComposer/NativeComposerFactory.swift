import Flutter
import Foundation
import UIKit

/// Factory для PlatformView'я нативного композера. Регистрируется в
/// `AppDelegate.didInitializeImplicitFlutterEngine` под viewType
/// `lighchat/native_composer`. Каждый instance создаёт свой `UITextView`
/// + per-view `FlutterMethodChannel` `lighchat/native_composer_<viewId>`
/// для двусторонней синхронизации с Dart-side `NativeIosComposerField`.
///
/// **Зачем**: Flutter `TextField` рендерится Skia и не получает системные
/// Cut/Copy/Paste/Replace/AutoFill/Writing Tools (iOS 26+) / диктовку /
/// QuickType подсказки / smart selection. Нативный `UITextView` даёт это
/// всё бесплатно. См. Phase 1 в плане «нативный composer».
final class NativeComposerFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  static let viewType = "lighchat/native_composer"

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
    return NativeComposerView(
      frame: frame, viewId: viewId, args: map, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
