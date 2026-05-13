import AVFoundation
import AVKit
import CryptoKit
import Flutter
import UIKit
import FirebaseCore
import PushKit
import QuickLook
import QuickLookThumbnailing
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
    LighChatIosImageMarkupBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    LighChatVirtualBackgroundBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    if #available(iOS 15.0, *) {
      LighChatMeetingPipInlineBridge.shared.register(
        messenger: engineBridge.applicationRegistrar.messenger())
    }
    NavBarBridge.shared.register(
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
      guard let args = call.arguments as? [String: Any],
        let rawPath = args["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "\(call.method) expects {path, ...}",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "openFile":
        let title = (args["title"] as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
        DispatchQueue.main.async {
          self.openFile(path: rawPath, title: title, result: result)
        }
      case "buildThumbnail":
        let width = (args["width"] as? NSNumber)?.intValue ?? 128
        let height = (args["height"] as? NSNumber)?.intValue ?? 128
        self.buildThumbnail(path: rawPath, width: width, height: height, result: result)
      default:
        result(FlutterMethodNotImplemented)
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

  private func buildThumbnail(
    path: String,
    width: Int,
    height: Int,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 13.0, *) else {
      result(nil)
      return
    }
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      result(nil)
      return
    }

    let pxW = max(24, width)
    let pxH = max(24, height)
    let keySource = "\(url.path)|\(pxW)x\(pxH)"
    let keyData = Data(keySource.utf8)
    let digest = SHA256.hash(data: keyData)
    let hash = digest.map { String(format: "%02x", $0) }.joined()

    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("chat_document_preview/thumbs", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let outURL = tempDir.appendingPathComponent("\(hash).png")
    if FileManager.default.fileExists(atPath: outURL.path) {
      result(outURL.path)
      return
    }

    let request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: CGSize(width: CGFloat(pxW), height: CGFloat(pxH)),
      scale: UIScreen.main.scale,
      representationTypes: .thumbnail
    )
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
      guard let thumb = representation?.uiImage,
        let png = thumb.pngData()
      else {
        result(nil)
        return
      }
      do {
        try png.write(to: outURL, options: .atomic)
        result(outURL.path)
      } catch {
        result(nil)
      }
    }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return previewItem == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return previewItem ?? LighChatPreviewItem(url: URL(fileURLWithPath: "/"), title: nil)
  }
}

/// Item для QuickLook-редактора. Editing mode выставляется через делегат
/// `QLPreviewControllerDelegate.previewController(_:editingModeFor:)` —
/// возвращаем `.createCopy`, чтобы Apple дала полноценный системный Markup со
/// стикерами / текстом / подписью / фигурами / лупой / описанием изображения
/// (тот же UI, что и в Photos/Mail).
private final class LighChatImageMarkupItem: NSObject, QLPreviewItem {
  let previewItemURL: URL?
  let previewItemTitle: String?

  init(url: URL, title: String?) {
    self.previewItemURL = url
    self.previewItemTitle = title
    super.init()
  }
}

/// Бридж для нативного редактора фото в композере. Вместо собственного
/// PencilKit-VC поднимает `QLPreviewController` с `.createCopy`: Apple сама
/// рисует Markup-toolbar (карандаш/маркер/перо/ластик/лассо + «+» меню со
/// стикерами/текстом/подписью/формами/лупой/описанием), а сохранённую копию
/// мы получаем через `previewController(_:didSaveEditedCopyOf:at:)`.
///
/// Контракт MethodChannel `lighchat/image_markup` остался прежним:
/// `editImage(path)` → `String?` — путь к JPEG-копии, или nil при отмене.
private final class LighChatIosImageMarkupBridge: NSObject, QLPreviewControllerDataSource,
  QLPreviewControllerDelegate
{
  static let shared = LighChatIosImageMarkupBridge()

  private var previewItem: LighChatImageMarkupItem?
  private var pendingResult: FlutterResult?
  private var savedURL: URL?

  private override init() {
    super.init()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "lighchat/image_markup", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      guard call.method == "editImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let rawPath = args["path"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "editImage expects {path}",
            details: nil
          )
        )
        return
      }
      DispatchQueue.main.async {
        self.editImage(path: rawPath, result: result)
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

  private func editImage(path: String, result: @escaping FlutterResult) {
    let sourceURL = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: sourceURL.path),
      let presenter = Self.topViewController()
    else {
      result(nil)
      return
    }

    // Если уже есть незавершённый запрос — отменяем его (на случай повторного
    // тапа), чтобы предыдущий FlutterResult не повис.
    if let pending = pendingResult {
      pending(nil)
    }
    pendingResult = result
    savedURL = nil
    previewItem = LighChatImageMarkupItem(url: sourceURL, title: nil)

    let preview = QLPreviewController()
    preview.dataSource = self
    preview.delegate = self
    preview.modalPresentationStyle = .fullScreen
    presenter.present(preview, animated: true)
  }

  // MARK: - QLPreviewControllerDataSource

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return previewItem == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem
  {
    return previewItem
      ?? LighChatImageMarkupItem(url: URL(fileURLWithPath: "/"), title: nil)
  }

  // MARK: - QLPreviewControllerDelegate

  func previewController(
    _ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem
  ) -> QLPreviewItemEditingMode {
    return .createCopy
  }

  func previewController(
    _ controller: QLPreviewController,
    didSaveEditedCopyOf previewItem: QLPreviewItem,
    at modifiedContentsURL: URL
  ) {
    // Apple отдаёт URL во временной директории QuickLook, который может быть
    // вычищен после dismiss. Копируем в свой temp с предсказуемым расширением,
    // чтобы Dart-сторона спокойно прочитала файл по `editedPath`.
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("chat_ios_markup", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let ext = modifiedContentsURL.pathExtension.isEmpty ? "jpg" : modifiedContentsURL.pathExtension
    let outURL = tempDir.appendingPathComponent("edited_\(UUID().uuidString).\(ext)")
    do {
      try FileManager.default.copyItem(at: modifiedContentsURL, to: outURL)
      savedURL = outURL
    } catch {
      savedURL = nil
    }
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    let result = pendingResult
    let url = savedURL
    pendingResult = nil
    savedURL = nil
    previewItem = nil
    result?(url?.path)
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

// MARK: - Meeting Picture-in-Picture (iOS 15+)
//
// Канал `lighchat/meeting_pip` — отдельный от `lighchat/pip` (тот работает
// с URL-видео для chat media-viewer'а). Этот плагин запускает системный
// PiP-окно для активной видеоконференции, чтобы митинг продолжался поверх
// других экранов приложения.
//
// Архитектура (рекомендованный Apple путь для video-call'ов, iOS 15+):
//   1. Контент-VC: `LighChatMeetingPipCallVC` наследует
//      `AVPictureInPictureVideoCallViewController` — внутри
//      `AVSampleBufferDisplayLayer`, заполняющий вью.
//   2. PiP-controller инициализируется через
//      `ContentSource(activeVideoCallSourceView:contentViewController:)` —
//      source view живёт в окне (1×1 px, прозрачный), чтобы Apple
//      могла «потянуть» PiP-окно из этой точки.
//   3. Dart присылает trackId локальной video-track'и → находим
//      `LocalVideoTrack` через `FlutterWebRTCPlugin.sharedSingleton`,
//      вешаем `LighChatPipVideoRenderer` через `addRenderer:` (Swift:
//      `add(_:)`). Каждый RTCVideoFrame → CMSampleBuffer → enqueue в
//      displayLayer контент-VC.
//   4. На `exit`/teardown — снимаем renderer, освобождаем VC.
//
// Раньше был AVSampleBufferDisplayLayer + `sampleBufferDisplayLayer:
// playbackDelegate:` content-source с offscreen-host'ом (-4000,-4000) —
// этот вариант капризно реагирует на `isPictureInPicturePossible` и
// требует видимой иерархии. VideoCallViewController-API специально
// под наш кейс и проще запускается.

@available(iOS 15.0, *)
final class LighChatMeetingPipCallVC: AVPictureInPictureVideoCallViewController {
  let displayLayer = AVSampleBufferDisplayLayer()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    displayLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(displayLayer)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    displayLayer.frame = view.bounds
  }
}

@available(iOS 15.0, *)
private final class LighChatMeetingPipInlineBridge: NSObject,
  AVPictureInPictureControllerDelegate
{
  static let shared = LighChatMeetingPipInlineBridge()

  private var pipController: AVPictureInPictureController?
  private var callVC: LighChatMeetingPipCallVC?
  private var sourceView: UIView?

  /// trackId, полученный из Dart (см. `bindLocalTrack`). Используется для
  /// поиска LocalVideoTrack в FlutterWebRTCPlugin.sharedSingleton.
  private var boundTrackId: String?
  private let pipRenderer = LighChatPipVideoRenderer()
  private var rendererAttached = false

  private override init() { super.init() }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/meeting_pip", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "enter":
        DispatchQueue.main.async { self.enterPip(result: result) }
      case "exit":
        DispatchQueue.main.async {
          self.pipController?.stopPictureInPicture()
          self.teardown()
          result(true)
        }
      case "bindLocalTrack":
        if let args = call.arguments as? [String: Any],
          let id = args["trackId"] as? String, !id.isEmpty
        {
          self.boundTrackId = id
          // Если PiP уже активно — переподцепимся к новому треку.
          if self.rendererAttached {
            self.detachRendererFromTrack()
            self.attachRendererToTrack()
          }
          result(true)
        } else {
          result(false)
        }
      case "unbindLocalTrack":
        self.detachRendererFromTrack()
        self.boundTrackId = nil
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Найти `LocalVideoTrack` через `FlutterWebRTCPlugin.sharedSingleton` и
  /// повесить наш renderer.
  private func attachRendererToTrack() {
    guard let trackId = boundTrackId,
      let plugin = FlutterWebRTCPlugin.sharedSingleton(),
      let localTracks = plugin.localTracks
    else { return }
    guard let raw = localTracks[trackId] else { return }
    // raw — это id<LocalTrack>; для видео это LocalVideoTrack.
    guard let videoTrack = raw as? LocalVideoTrack else { return }
    pipRenderer.displayLayer = callVC?.displayLayer
    // ObjC селектор `addRenderer:` Swift-interop переименовал в `add(_:)`.
    videoTrack.add(pipRenderer)
    rendererAttached = true
  }

  private func detachRendererFromTrack() {
    guard rendererAttached,
      let trackId = boundTrackId,
      let plugin = FlutterWebRTCPlugin.sharedSingleton(),
      let localTracks = plugin.localTracks,
      let raw = localTracks[trackId],
      let videoTrack = raw as? LocalVideoTrack
    else {
      rendererAttached = false
      pipRenderer.displayLayer = nil
      return
    }
    videoTrack.remove(pipRenderer)
    pipRenderer.displayLayer = nil
    rendererAttached = false
  }

  private static func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func enterPip(result: @escaping FlutterResult) {
    guard AVPictureInPictureController.isPictureInPictureSupported(),
      let window = Self.keyWindow()
    else {
      result(false)
      return
    }

    // VoIP-сессия — чтобы аудио митинга не отключилось при сворачивании.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .videoChat,
        options: [.allowBluetooth, .defaultToSpeaker])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}

    // 1. Source view — обязан быть в видимой иерархии. Делаем 1×1 px,
    // прозрачный, без интеракций. Apple использует его положение как
    // «откуда улетает» PiP-окно при старте.
    let src = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    src.backgroundColor = .clear
    src.isUserInteractionEnabled = false
    src.alpha = 0
    window.addSubview(src)
    self.sourceView = src

    // 2. Content view controller — то, что увидит юзер в PiP-окне.
    let vc = LighChatMeetingPipCallVC()
    // Aspect соотношения определяют размер мини-окна. 9:16 — типичный
    // портрет фронтальной камеры на iPhone.
    vc.preferredContentSize = CGSize(width: 9, height: 16)
    self.callVC = vc

    // 3. PiP controller через ContentSource VideoCall-API.
    let source = AVPictureInPictureController.ContentSource(
      activeVideoCallSourceView: src,
      contentViewController: vc
    )
    let pip = AVPictureInPictureController(contentSource: source)
    pip.canStartPictureInPictureAutomaticallyFromInline = true
    pip.delegate = self
    self.pipController = pip

    // 4. Подцепляем renderer — если уже знаем trackId, реальные кадры
    // полетят в displayLayer контент-VC.
    attachRendererToTrack()

    // 5. Стартуем. isPictureInPicturePossible становится true после того,
    // как контент-VC появится в иерархии (через короткий cycle layout'а).
    self.attemptStart(pip: pip, attemptsLeft: 30, result: result)
  }

  private func attemptStart(
    pip: AVPictureInPictureController, attemptsLeft: Int,
    result: @escaping FlutterResult
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
      self.attemptStart(pip: pip, attemptsLeft: attemptsLeft - 1, result: result)
    }
  }

  fileprivate func teardown() {
    detachRendererFromTrack()
    pipController?.delegate = nil
    pipController = nil
    callVC = nil
    sourceView?.removeFromSuperview()
    sourceView = nil
  }

  // MARK: AVPictureInPictureControllerDelegate

  func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) { teardown() }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) { teardown() }
}

// MARK: - LighChatPipVideoRenderer
//
// Конформит RTCVideoRenderer (WebRTC SDK) — мы вешаем эту штуку на
// `LocalVideoTrack.addRenderer(_:)` через flutter_webrtc, и каждый
// входящий RTCVideoFrame конвертируется в CMSampleBuffer, который
// летит в `AVSampleBufferDisplayLayer` PiP-окна.
//
// Поддерживаем только `RTCCVPixelBuffer`-backed кадры (нулевая копия) —
// камера и ReplayKit на iOS отдают именно такие. Если когда-нибудь
// потребуется I420 (например, software-decoded поток) — добавим
// конвертацию через manual UV-pack в NV12 CVPixelBuffer.
@available(iOS 15.0, *)
final class LighChatPipVideoRenderer: NSObject, RTCVideoRenderer {
  /// Выставляется LighChatMeetingPipInlineBridge перед attach'ем; при
  /// teardown — обнуляется. Renderer держит weak, чтобы не задерживать
  /// layer в памяти после exit'а PiP.
  weak var displayLayer: AVSampleBufferDisplayLayer?

  /// Не используется (RTCVideoRenderer обязан реализовать, но AVSampleBuffer
  /// сам читает размер из CVPixelBuffer).
  func setSize(_ size: CGSize) {}

  func renderFrame(_ frame: RTCVideoFrame?) {
    guard let frame = frame, let layer = self.displayLayer else { return }

    // На iOS камера/screen-share отдают RTCCVPixelBuffer (NV12). Если
    // буфер другой — пропускаем кадр (PiP покажет последний валидный).
    // Конверсия I420→NV12 руками — отдельная задача, пока не нужна.
    guard let cv = frame.buffer as? RTCCVPixelBuffer else { return }
    let pb = cv.pixelBuffer

    // Учитываем rotation: PiP сам не вращает кадр, поэтому если устройство
    // в портретной ориентации (frame.rotation = ._90), нужно прокрутить.
    // Простейший способ — выставить sampleBuffer attachments
    // `kCMSampleAttachmentKey_DisplayImmediately`. Реальный rotate под
    // капотом делает CoreMedia + Metal.
    var formatDesc: CMFormatDescription?
    let status = CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: nil, imageBuffer: pb, formatDescriptionOut: &formatDesc)
    guard status == noErr, let desc = formatDesc else { return }

    let pts = CMTime(value: frame.timeStampNs, timescale: 1_000_000_000)
    var timing = CMSampleTimingInfo(
      duration: CMTime(value: 1, timescale: 30),
      presentationTimeStamp: pts,
      decodeTimeStamp: .invalid)

    var sampleBuffer: CMSampleBuffer?
    CMSampleBufferCreateForImageBuffer(
      allocator: nil, imageBuffer: pb, dataReady: true,
      makeDataReadyCallback: nil, refcon: nil,
      formatDescription: desc, sampleTiming: &timing,
      sampleBufferOut: &sampleBuffer)
    guard let sb = sampleBuffer else { return }

    // displayImmediately — нужно, потому что у нас live-стрим, не
    // плановое воспроизведение. attachments array возвращает CFArray
    // изменяемых CFMutableDictionary'ев — пишем флаг прямо в первый.
    if let attachments = CMSampleBufferGetSampleAttachmentsArray(
      sb, createIfNecessary: true) as NSArray?,
      let dict = attachments.firstObject as? NSMutableDictionary
    {
      dict[kCMSampleAttachmentKey_DisplayImmediately] = true
    }

    // enqueue должен идти на main или на dedicated serial queue.
    DispatchQueue.main.async { [weak layer] in
      guard let layer = layer else { return }
      if layer.status == .failed {
        layer.flush()
      }
      if layer.isReadyForMoreMediaData {
        layer.enqueue(sb)
      }
    }
  }

}
