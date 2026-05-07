import AVFoundation
import AVKit
import CryptoKit
import Flutter
import UIKit
import FirebaseCore
import PushKit
import QuickLook
import flutter_callkit_incoming

/// Нативный PiP для iOS: отдельный AVPlayer по URL (Flutter `video_player` не отдаёт слой в PiP).
private final class LighChatIosPipBridge: NSObject, AVPictureInPictureControllerDelegate {
  static let shared = LighChatIosPipBridge()

  private var messenger: FlutterBinaryMessenger?
  private var hostView: UIView?
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var pipController: AVPictureInPictureController?

  private override init() {
    super.init()
  }

  func register(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    let channel = FlutterMethodChannel(name: "lighchat/pip", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "enter":
        guard let args = call.arguments as? [String: Any],
          let urlString = args["videoUrl"] as? String,
          let url = URL(string: urlString)
        else {
          result(false)
          return
        }
        let positionMs = (args["positionMs"] as? NSNumber)?.intValue ?? 0
        DispatchQueue.main.async {
          self.startPip(url: url, positionMs: positionMs, result: result)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func startPip(url: URL, positionMs: Int, result: @escaping FlutterResult) {
    teardown()
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .moviePlayback, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}

    guard let window = Self.keyWindow() else {
      result(false)
      return
    }

    let item = AVPlayerItem(url: url)
    let avPlayer = AVPlayer(playerItem: item)
    self.player = avPlayer

    let layer = AVPlayerLayer(player: avPlayer)
    layer.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
    self.playerLayer = layer

    let host = UIView(frame: CGRect(x: -4000, y: -4000, width: 4, height: 4))
    host.isUserInteractionEnabled = false
    host.layer.addSublayer(layer)
    window.addSubview(host)
    self.hostView = host

    guard let pip = AVPictureInPictureController(playerLayer: layer) else {
      teardown()
      result(false)
      return
    }
    pip.delegate = self
    self.pipController = pip

    let time = CMTime(value: CMTimeValue(positionMs), timescale: 1000)
    avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
      guard let self = self else {
        result(false)
        return
      }
      if !finished {
        self.teardown()
        result(false)
        return
      }
      avPlayer.play()
      guard let activePip = self.pipController else {
        self.teardown()
        result(false)
        return
      }
      self.attemptStartPip(pip: activePip, attemptsLeft: 30, result: result)
    }
  }

  /// `isPictureInPicturePossible` часто становится true только после старта воспроизведения.
  private func attemptStartPip(
    pip: AVPictureInPictureController, attemptsLeft: Int, result: @escaping FlutterResult
  ) {
    if pip.isPictureInPicturePossible {
      pip.startPictureInPicture()
      result(true)
      return
    }
    if attemptsLeft <= 0 {
      teardown()
      result(false)
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      self.attemptStartPip(pip: pip, attemptsLeft: attemptsLeft - 1, result: result)
    }
  }

  func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    let ms = currentPositionMs()
    notifyDartFinished(positionMs: ms)
    teardown()
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    teardown()
  }

  private func currentPositionMs() -> Int {
    guard let p = player else { return 0 }
    let seconds = CMTimeGetSeconds(p.currentTime())
    if !seconds.isFinite { return 0 }
    return Int(seconds * 1000.0)
  }

  private func notifyDartFinished(positionMs: Int) {
    guard let messenger = messenger else { return }
    let channel = FlutterMethodChannel(name: "lighchat/pip", binaryMessenger: messenger)
    channel.invokeMethod("pipFinished", arguments: ["positionMs": positionMs])
  }

  private func teardown() {
    pipController?.delegate = nil
    pipController = nil
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    playerLayer = nil
    hostView?.removeFromSuperview()
    hostView = nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase as early as possible so plugins that touch Firebase
    // during registration don't log "No app has been configured yet."
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    #if !DEBUG
    setupVoipRegistry()
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    LighChatIosPipBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    LighChatIosDocumentPreviewBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    LighChatVirtualBackgroundBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func setupVoipRegistry() {
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry
  }

  private func normalizedString(_ raw: Any?) -> String? {
    guard let value = raw else { return nil }
    let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
    return text.isEmpty ? nil : text
  }

  private func boolValue(_ raw: Any?) -> Bool {
    switch raw {
    case let value as Bool:
      return value
    case let value as NSNumber:
      return value.boolValue
    case let value as String:
      let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return normalized == "1" || normalized == "true" || normalized == "video"
    default:
      return false
    }
  }

  private func callkitUuid(from callId: String) -> String {
    let digest = Insecure.MD5.hash(data: Foundation.Data(callId.utf8))
    let hash = digest.map { String(format: "%02x", $0) }.joined()
    let p1 = String(hash.prefix(8))
    let p2 = String(hash.dropFirst(8).prefix(4))
    let p3 = String(hash.dropFirst(12).prefix(4))
    let p4 = String(hash.dropFirst(16).prefix(4))
    let p5 = String(hash.dropFirst(20).prefix(12))
    return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    guard type == .voIP else { return }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let dict = payload.dictionaryPayload
    let rawCallId = normalizedString(dict["callId"]) ??
      normalizedString(dict["id"]) ??
      UUID().uuidString
    let callkitId = callkitUuid(from: rawCallId)
    let callerName = normalizedString(dict["callerName"]) ??
      normalizedString(dict["nameCaller"]) ??
      normalizedString(dict["handle"]) ??
      "Кто-то"
    let isVideo = boolValue(dict["isVideo"])
    let data = flutter_callkit_incoming.Data(
      id: callkitId,
      nameCaller: callerName,
      handle: callerName,
      type: isVideo ? 1 : 0
    )
    data.extra = [
      "callId": rawCallId,
      "callerName": callerName,
      "isVideo": isVideo ? "1" : "0",
      "callkitId": callkitId,
    ]

    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      completion()
      return
    }
    plugin.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }
}

private final class LighChatPreviewItem: NSObject, QLPreviewItem {
  let previewItemURL: URL?
  let previewItemTitle: String?

  init(url: URL, title: String?) {
    self.previewItemURL = url
    self.previewItemTitle = title
    super.init()
  }
}

private final class LighChatIosDocumentPreviewBridge: NSObject, QLPreviewControllerDataSource {
  static let shared = LighChatIosDocumentPreviewBridge()

  private var previewItem: LighChatPreviewItem?

  private override init() {
    super.init()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "lighchat/document_preview", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(false)
        return
      }
      guard call.method == "openFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let rawPath = args["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "openFile expects {path, title?}",
            details: nil
          )
        )
        return
      }
      let title = (args["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      DispatchQueue.main.async {
        self.openFile(path: rawPath, title: title, result: result)
      }
    }
  }

  private static func topViewController() -> UIViewController? {
    guard let root = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?
      .rootViewController
    else {
      return nil
    }
    var current = root
    while let presented = current.presentedViewController {
      current = presented
    }
    return current
  }

  private func openFile(path: String, title: String?, result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      result(false)
      return
    }
    guard let presenter = Self.topViewController() else {
      result(false)
      return
    }

    previewItem = LighChatPreviewItem(url: url, title: title)
    let preview = QLPreviewController()
    preview.dataSource = self
    presenter.present(preview, animated: true) {
      result(true)
    }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return previewItem == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return previewItem ?? LighChatPreviewItem(url: URL(fileURLWithPath: "/"), title: nil)
  }
}

/// Бридж для виртуального фона mobile-митинга.
///
/// Сейчас хранит состояние и пишет в лог; реальный пиксельный pipeline
/// (AVCaptureSession hook -> ML Kit Selfie-Segmentation / Vision ->
///  Metal compositor -> flutter_webrtc RTCVideoSource) подключается отдельным
/// native-PR (см. docs/mobile/meetings-virtual-background.md).
///
/// Канал: `lighchat/virtual_background`, методы — `setMode`, `dispose`.
private final class LighChatVirtualBackgroundBridge: NSObject {
  static let shared = LighChatVirtualBackgroundBridge()

  private var currentMode: String = "none"
  private var currentImagePath: String?

  private override init() {
    super.init()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/virtual_background",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "setMode":
        guard let args = call.arguments as? [String: Any],
          let mode = args["mode"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "setMode expects {mode, imageAssetPath?}",
              details: nil
            )
          )
          return
        }
        if !["none", "blur", "image"].contains(mode) {
          result(
            FlutterError(
              code: "invalid_mode",
              message: "unknown virtual background mode: \(mode)",
              details: nil
            )
          )
          return
        }
        self.currentMode = mode
        self.currentImagePath = args["imageAssetPath"] as? String
        NSLog(
          "[LighChatVirtualBg] setMode mode=%@ imagePath=%@ (native pipeline TBD)",
          mode,
          self.currentImagePath ?? "nil"
        )
        result(nil)
      case "dispose":
        self.currentMode = "none"
        self.currentImagePath = nil
        NSLog("[LighChatVirtualBg] dispose")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
