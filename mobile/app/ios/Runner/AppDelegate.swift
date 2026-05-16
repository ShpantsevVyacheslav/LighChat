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
    VoiceTranscriberBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    TextToSpeechBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    AppleIntelligenceBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    LiveTextBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    VoiceActivityBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    HapticsBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    DocumentScannerBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    CommunicationIntentsBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    SubjectLiftBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    SpotlightBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
    // Native composer (Phase 1): PlatformView с настоящим UITextView,
    // даёт системные Cut/Copy/Paste/Replace/AutoFill/Writing Tools.
    // Использование гейтится Dart-side feature flag — пока виджет
    // подключён только в тестовой ветке.
    let composerFactory = NativeComposerFactory(
      messenger: engineBridge.applicationRegistrar.messenger())
    engineBridge.applicationRegistrar.register(
      composerFactory, withId: NativeComposerFactory.viewType)

    // Phase 11: native location preview через MKMapView (вместо OSM
    // тайла) + reverse geocoder для отображения адреса. Используется
    // в `ComposerPendingLocationPreview` и потенциально в message
    // bubble c locationShare.
    let mapFactory = ChatLocationMapViewFactory(
      messenger: engineBridge.applicationRegistrar.messenger())
    engineBridge.applicationRegistrar.register(
      mapFactory, withId: ChatLocationMapViewFactory.viewType)
    ChatGeocoderBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if SpotlightBridge.shared.handleUserActivity(userActivity) {
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler)
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

  /// Текущий applied поворот (радианы). 0 = no rotation.
  /// LighChatPipVideoRenderer сравнивает с frame.rotation и пере-применяет
  /// transform только при изменении.
  var appliedRotation: CGFloat = 0

  /// Кнопка «Вернуться в звонок» в углу PiP-окна. По тапу зовёт
  /// `lighchat/meeting_pip:returnToCall` → Dart popUntil meeting-room.
  /// AVPictureInPictureVideoCallViewController пропускает gesture'ы
  /// своих subviews сквозь систему overlay'я PiP.
  private let returnButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    displayLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(displayLayer)

    // Return-to-call: круглая полупрозрачная кнопка снизу-по-центру.
    returnButton.translatesAutoresizingMaskIntoConstraints = false
    returnButton.setImage(
      UIImage(systemName: "phone.fill.arrow.up.right"),
      for: .normal)
    returnButton.tintColor = .white
    returnButton.backgroundColor = UIColor.systemBlue
    returnButton.layer.cornerRadius = 22
    returnButton.clipsToBounds = true
    returnButton.addTarget(
      self, action: #selector(returnTapped), for: .touchUpInside)
    view.addSubview(returnButton)
    NSLayoutConstraint.activate([
      returnButton.widthAnchor.constraint(equalToConstant: 44),
      returnButton.heightAnchor.constraint(equalToConstant: 44),
      returnButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      returnButton.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    displayLayer.frame = view.bounds
    // Перецентрируем displayLayer после rotation — anchor по центру.
    displayLayer.position = CGPoint(
      x: view.bounds.midX, y: view.bounds.midY)
  }

  @objc private func returnTapped() {
    if #available(iOS 15.0, *) {
      LighChatMeetingPipInlineBridge.shared.returnToCallFromPip()
    }
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
  /// Сохраняем messenger при register'е — нужен для invokeMethod
  /// обратно в Dart (например, на тап «Вернуться в звонок»).
  private weak var messenger: FlutterBinaryMessenger?
  /// Запущен ли prepare/start транзишен. Защищает от двойного
  /// startPictureInPicture за один шаг (AVKit возвращает -1001 если
  /// предыдущий ещё не завершился).
  private var startInFlight = false

  /// trackId, полученный из Dart (см. `bindLocalTrack`). Используется для
  /// поиска LocalVideoTrack в FlutterWebRTCPlugin.sharedSingleton.
  private var boundTrackId: String?
  private let pipRenderer = LighChatPipVideoRenderer()
  private var rendererAttached = false

  private override init() { super.init() }

  func register(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    let channel = FlutterMethodChannel(
      name: "lighchat/meeting_pip", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isSupported":
        let v = AVPictureInPictureController.isPictureInPictureSupported()
        NSLog("[MeetingPiP] isSupported → %@", v ? "true" : "false")
        result(v)
      case "enter":
        NSLog("[MeetingPiP] enter requested (boundTrackId=%@)",
              self.boundTrackId ?? "nil")
        DispatchQueue.main.async { self.enterPip(result: result) }
      case "exit":
        NSLog("[MeetingPiP] exit requested")
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
          NSLog("[MeetingPiP] bindLocalTrack id=%@ (rendererAttached=%@)",
                id, self.rendererAttached ? "true" : "false")
          // Eager prepare: создаём PiP-controller СРАЗУ, не ждём
          // явного `enter`. AVKit с `canStartPictureInPictureAuto-
          // maticallyFromInline = true` сам триггерит PiP при сворачивании
          // приложения, но только если controller уже жив. Без этого
          // auto-PiP не работал.
          DispatchQueue.main.async {
            self.preparePipIfNeeded()
            self.enableBackgroundCameraIfPossible()
            // Если PiP уже активно — переподцепимся к новому треку.
            if self.rendererAttached {
              self.detachRendererFromTrack()
            }
            self.attachRendererToTrack()
          }
          result(true)
        } else {
          NSLog("[MeetingPiP] bindLocalTrack rejected (empty id)")
          result(false)
        }
      case "unbindLocalTrack":
        NSLog("[MeetingPiP] unbindLocalTrack id=%@", self.boundTrackId ?? "nil")
        DispatchQueue.main.async {
          self.detachRendererFromTrack()
          self.boundTrackId = nil
          self.teardown()
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NSLog("[MeetingPiP] channel registered")
  }

  /// Найти `LocalVideoTrack` через `FlutterWebRTCPlugin.sharedSingleton` и
  /// повесить наш renderer.
  private func attachRendererToTrack() {
    guard let trackId = boundTrackId else {
      NSLog("[MeetingPiP] attachRenderer: no trackId bound")
      return
    }
    guard let plugin = FlutterWebRTCPlugin.sharedSingleton() else {
      NSLog("[MeetingPiP] attachRenderer: sharedSingleton nil")
      return
    }
    guard let localTracks = plugin.localTracks else {
      NSLog("[MeetingPiP] attachRenderer: plugin.localTracks nil")
      return
    }
    // `localTracks` — NSMutableDictionary; Swift не даёт ему `.keys`
    // напрямую, поэтому идём через `allKeys` (NSDictionary API).
    NSLog("[MeetingPiP] attachRenderer: localTracks keys=%@",
          localTracks.allKeys.description)
    guard let raw = localTracks[trackId] else {
      NSLog("[MeetingPiP] attachRenderer: trackId=%@ NOT FOUND in localTracks",
            trackId)
      return
    }
    // raw — это id<LocalTrack>; для видео это LocalVideoTrack.
    guard let videoTrack = raw as? LocalVideoTrack else {
      NSLog("[MeetingPiP] attachRenderer: raw is %@, not LocalVideoTrack",
            String(describing: type(of: raw)))
      return
    }
    pipRenderer.displayLayer = callVC?.displayLayer
    pipRenderer.contentVC = callVC
    NSLog("[MeetingPiP] attachRenderer: adding pipRenderer to LocalVideoTrack "
        + "(displayLayer set: %@)",
        pipRenderer.displayLayer != nil ? "yes" : "no")
    // ObjC селектор `addRenderer:` Swift-interop переименовал в `add(_:)`.
    videoTrack.add(pipRenderer)
    rendererAttached = true
  }

  private func detachRendererFromTrack() {
    guard rendererAttached else {
      pipRenderer.displayLayer = nil
      pipRenderer.contentVC = nil
      return
    }
    guard let trackId = boundTrackId,
      let plugin = FlutterWebRTCPlugin.sharedSingleton(),
      let localTracks = plugin.localTracks,
      let raw = localTracks[trackId],
      let videoTrack = raw as? LocalVideoTrack
    else {
      NSLog("[MeetingPiP] detachRenderer: track gone, clearing local flag")
      rendererAttached = false
      pipRenderer.displayLayer = nil
      pipRenderer.contentVC = nil
      return
    }
    NSLog("[MeetingPiP] detachRenderer: removing pipRenderer from track %@",
          trackId)
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

  /// Разрешаем камере продолжать съёмку, когда приложение уходит в фон.
  /// Без этого AVCaptureSession iOS автоматически приостанавливает
  /// камеру → PiP-окно замерзает на последнем кадре.
  ///
  /// Apple ввёл `multitaskingCameraAccessEnabled` (iOS 16+) специально
  /// под наш кейс — без необходимости `voip` background mode (которого
  /// у нас нет на Personal Team / Free Apple ID). Доступно на любом
  /// устройстве с iPad-multitasking-style camera ИЛИ iPhone, который
  /// рапортует `multitaskingCameraAccessSupported = true` (с iPhone XS и
  /// новее обычно поддерживается, особенно когда есть PiP-сессия).
  ///
  /// Требования Apple:
  ///   - app содержит `audio` в UIBackgroundModes (✓ настроено);
  ///   - AVAudioSession настроена с .playAndRecord и аудио-input
  ///     (✓ настраиваем в `preparePipIfNeeded`);
  ///   - вызывать на той же сессии, что у RTCCameraVideoCapturer.
  fileprivate func enableBackgroundCameraIfPossible() {
    guard #available(iOS 16.0, *) else {
      NSLog("[MeetingPiP] background-camera: iOS<16, skip")
      return
    }
    guard let plugin = FlutterWebRTCPlugin.sharedSingleton() else {
      NSLog("[MeetingPiP] background-camera: no plugin singleton")
      return
    }
    guard let capturer = plugin.videoCapturer else {
      NSLog("[MeetingPiP] background-camera: capturer not ready yet")
      return
    }
    let session = capturer.captureSession
    if !session.isMultitaskingCameraAccessSupported {
      NSLog("[MeetingPiP] background-camera: NOT supported on this device")
      return
    }
    if session.isMultitaskingCameraAccessEnabled {
      NSLog("[MeetingPiP] background-camera: already enabled")
      return
    }
    // Apple требует обернуть write в beginConfiguration/commitConfiguration
    // если сессия уже running. flutter_webrtc стартует её сразу после
    // getUserMedia, так что на этом этапе running=true.
    session.beginConfiguration()
    session.isMultitaskingCameraAccessEnabled = true
    session.commitConfiguration()
    NSLog(
      "[MeetingPiP] background-camera: ✅ ENABLED (supported=true, was=false)")
  }

  /// Создаём PiP-controller если ещё не создан. Делаем это ЕДИНОЖДЫ на
  /// весь lifetime митинга (на `bindLocalTrack`). После этого AVKit с
  /// `canStartPictureInPictureAutomaticallyFromInline = true` сам
  /// триггерит PiP при `applicationWillResignActive` — авто-PiP при
  /// сворачивании приложения.
  fileprivate func preparePipIfNeeded() {
    if self.pipController != nil { return }
    guard AVPictureInPictureController.isPictureInPictureSupported(),
      let window = Self.keyWindow()
    else {
      NSLog("[MeetingPiP] prepare: bail — no support or keyWindow")
      return
    }

    // VoIP-сессия — чтобы аудио митинга не отключилось при сворачивании.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .videoChat,
        options: [.allowBluetooth, .defaultToSpeaker])
      try AVAudioSession.sharedInstance().setActive(true)
      NSLog("[MeetingPiP] prepare: AVAudioSession configured")
    } catch {
      NSLog("[MeetingPiP] prepare: AVAudioSession ERROR — %@",
            error.localizedDescription)
    }
    // После аудиосессии — открываем камере фон. ВАЖНО: порядок именно
    // такой, многозадачный camera access проверяет audio session config.
    enableBackgroundCameraIfPossible()
    setupSourceAndController(in: window)
    NSLog("[MeetingPiP] prepare: pipController ready for auto-PiP")
  }

  private func enterPip(result: @escaping FlutterResult) {
    let supported = AVPictureInPictureController.isPictureInPictureSupported()
    NSLog("[MeetingPiP] enterPip: supported=%@", supported ? "true" : "false")
    guard supported, let window = Self.keyWindow() else {
      NSLog("[MeetingPiP] enterPip: bail — supported=%@ keyWindow=%@",
            supported ? "true" : "false",
            Self.keyWindow() == nil ? "nil" : "ok")
      result(false)
      return
    }

    // Если PiP уже создан (повторный клик или auto-prepare) — не
    // пересоздаём, просто пробуем стартануть на существующем контроллере.
    if let existing = self.pipController {
      NSLog(
        "[MeetingPiP] enterPip: pipController already exists "
          + "(active=%@, possible=%@) — reusing",
        existing.isPictureInPictureActive ? "true" : "false",
        existing.isPictureInPicturePossible ? "true" : "false")
      if existing.isPictureInPictureActive {
        result(true)
        return
      }
      attemptStart(pip: existing, attemptsLeft: 30, result: result)
      return
    }

    // Если eager-prepare ещё не успел (редкий случай) — конфигурируем
    // сессию и controller тут.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord, mode: .videoChat,
        options: [.allowBluetooth, .defaultToSpeaker])
      try AVAudioSession.sharedInstance().setActive(true)
      NSLog("[MeetingPiP] enterPip: AVAudioSession configured")
    } catch {
      NSLog("[MeetingPiP] enterPip: AVAudioSession ERROR — %@",
            error.localizedDescription)
    }

    setupSourceAndController(in: window)
    attachRendererToTrack()
    guard let pip = self.pipController else {
      result(false)
      return
    }
    self.attemptStart(pip: pip, attemptsLeft: 30, result: result)
  }

  /// Создаём source-view + content-VC + PiP-controller. Используется и
  /// для eager prepare (на bindLocalTrack), и для on-demand enterPip.
  private func setupSourceAndController(in window: UIWindow) {
    // 1. Source view — обязан быть в видимой иерархии. AVKit капризно
    // реагирует на `alpha=0` (видит «не отображается» и
    // startPictureInPicture no-op'ит без ошибки) и на нулевой размер.
    // Поэтому даём 80×80 + alpha 0.01 — глазу не видно, но AVKit
    // считает «view active».
    let src = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    src.backgroundColor = .clear
    src.isUserInteractionEnabled = false
    src.alpha = 0.01
    window.addSubview(src)
    src.setNeedsLayout()
    src.layoutIfNeeded()
    self.sourceView = src
    NSLog(
      "[MeetingPiP] setup: sourceView added (windowSize=%@, srcFrame=%@, "
        + "srcAlpha=%.2f, srcInWindow=%@)",
      NSCoder.string(for: window.bounds.size),
      NSCoder.string(for: src.frame),
      Double(src.alpha),
      src.window != nil ? "yes" : "no")

    // 2. Content view controller — то, что увидит юзер в PiP-окне.
    // `loadViewIfNeeded()` форсит viewDidLoad — иначе AVKit видит
    // «view не загружен» и молча no-op'ит startPictureInPicture.
    let vc = LighChatMeetingPipCallVC()
    vc.preferredContentSize = CGSize(width: 480, height: 640)
    vc.loadViewIfNeeded()
    vc.view.frame = CGRect(x: 0, y: 0, width: 480, height: 640)
    vc.view.setNeedsLayout()
    vc.view.layoutIfNeeded()
    self.callVC = vc
    NSLog(
      "[MeetingPiP] setup: callVC ready (viewLoaded=%@, view.bounds=%@, "
        + "displayLayer.frame=%@)",
      vc.isViewLoaded ? "yes" : "no",
      NSCoder.string(for: vc.view.bounds),
      NSCoder.string(for: vc.displayLayer.frame))

    // 3. PiP controller через ContentSource VideoCall-API.
    let source = AVPictureInPictureController.ContentSource(
      activeVideoCallSourceView: src,
      contentViewController: vc
    )
    let pip = AVPictureInPictureController(contentSource: source)
    // КЛЮЧЕВОЕ для auto-PiP: iOS сам стартует PiP при
    // `applicationWillResignActive` если этот флаг true И controller жив.
    pip.canStartPictureInPictureAutomaticallyFromInline = true
    pip.delegate = self
    self.pipController = pip
    NSLog("[MeetingPiP] setup: PiP controller created "
        + "(canStartAutomaticallyFromInline=true)")
  }

  private func attemptStart(
    pip: AVPictureInPictureController, attemptsLeft: Int,
    result: @escaping FlutterResult
  ) {
    NSLog(
      "[MeetingPiP] attemptStart: possible=%@ active=%@ suspended=%@ "
        + "inFlight=%@ left=%d",
      pip.isPictureInPicturePossible ? "true" : "false",
      pip.isPictureInPictureActive ? "true" : "false",
      pip.isPictureInPictureSuspended ? "true" : "false",
      startInFlight ? "true" : "false",
      attemptsLeft)
    // Guard: уже идёт транзишен или PiP активен — не дёргаем заново.
    if pip.isPictureInPictureActive || startInFlight {
      NSLog("[MeetingPiP] attemptStart: PiP already active or starting, skip")
      result(true)
      return
    }
    if pip.isPictureInPicturePossible {
      NSLog("[MeetingPiP] attemptStart: calling startPictureInPicture()")
      startInFlight = true
      pip.startPictureInPicture()
      result(true)
      return
    }
    if attemptsLeft <= 0 {
      NSLog("[MeetingPiP] attemptStart: GAVE UP — isPictureInPicturePossible "
          + "never became true (window size: %@, hasCallVC=%@, "
          + "hasSourceView=%@, rendererAttached=%@)",
          NSCoder.string(for: callVC?.view.bounds.size ?? .zero),
          callVC != nil ? "yes" : "no",
          sourceView != nil ? "yes" : "no",
          rendererAttached ? "yes" : "no")
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
    NSLog("[MeetingPiP] teardown")
    detachRendererFromTrack()
    pipController?.delegate = nil
    pipController = nil
    callVC = nil
    sourceView?.removeFromSuperview()
    sourceView = nil
    pipRenderer.frameCount = 0
  }

  // MARK: AVPictureInPictureControllerDelegate

  func pictureInPictureControllerWillStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    NSLog("[MeetingPiP] delegate: WILL START")
  }

  /// Таймер, который раз в 1 секунду логирует «жив ли поток кадров».
  /// Запускается на DID START, гасится на WILL/DID STOP. Если кадры
  /// перестали приходить — увидим заморозку в логах.
  private var frameLivenessTimer: Timer?
  private var lastLoggedFrameCount: Int = 0

  func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    NSLog("[MeetingPiP] delegate: DID START")
    startInFlight = false
    lastLoggedFrameCount = pipRenderer.frameCount
    frameLivenessTimer?.invalidate()
    frameLivenessTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                              repeats: true) { [weak self] _ in
      guard let self = self else { return }
      let cur = self.pipRenderer.frameCount
      let diff = cur - self.lastLoggedFrameCount
      let layer = self.callVC?.displayLayer
      NSLog(
        "[MeetingPiP] LIVENESS: framesLast1s=%d total=%d layerStatus=%@ "
          + "ready=%@",
        diff, cur,
        Self.layerStatusString(layer?.status ?? .unknown),
        layer?.isReadyForMoreMediaData == true ? "yes" : "no")
      if diff == 0 {
        NSLog(
          "[MeetingPiP] LIVENESS: ⚠️ FROZEN — no frames in last 1s "
            + "(renderer.displayLayer=%@, rendererAttached=%@, "
            + "boundTrackId=%@)",
          self.pipRenderer.displayLayer != nil ? "set" : "nil",
          self.rendererAttached ? "yes" : "no",
          self.boundTrackId ?? "nil")
      }
      self.lastLoggedFrameCount = cur
    }
  }

  private static func layerStatusString(_ s: AVQueuedSampleBufferRenderingStatus)
    -> String
  {
    switch s {
    case .unknown: return "unknown"
    case .rendering: return "rendering"
    case .failed: return "failed"
    @unknown default: return "unknown"
    }
  }

  func pictureInPictureControllerWillStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    NSLog("[MeetingPiP] delegate: WILL STOP")
    frameLivenessTimer?.invalidate()
    frameLivenessTimer = nil
  }

  func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    NSLog("[MeetingPiP] delegate: DID STOP")
    startInFlight = false
    frameLivenessTimer?.invalidate()
    frameLivenessTimer = nil
    // НЕ зовём teardown — controller остаётся жив для повторного
    // запуска (например, авто-PiP при следующем сворачивании). Renderer
    // не отключаем. Освободим всё на unbindLocalTrack/dispose.
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    NSLog("[MeetingPiP] delegate: FAILED — %@ (domain=%@ code=%ld)",
          error.localizedDescription,
          (error as NSError).domain,
          (error as NSError).code)
    startInFlight = false
    // -1001 (CannotEnter) обычно временный: система занята/transition
    // в процессе. Controller оставляем живым — следующий enter может
    // сработать. teardown только когда unbindLocalTrack/dispose.
  }

  /// Вызывается из LighChatMeetingPipCallVC при тапе на «Вернуться».
  /// Сообщаем Dart, чтобы тот закрыл /chats и вернулся в комнату.
  fileprivate func returnToCallFromPip() {
    NSLog("[MeetingPiP] returnToCallFromPip tapped")
    if let messenger = self.messenger {
      let ch = FlutterMethodChannel(
        name: "lighchat/meeting_pip", binaryMessenger: messenger)
      ch.invokeMethod("returnToCall", arguments: nil)
    }
    // Заодно гасим PiP-окно, чтобы пользователь вернулся к полному UI.
    pipController?.stopPictureInPicture()
  }
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

  /// Ссылка на parent VC — нужна, чтобы применить affine transform для
  /// поворота кадра (камера на iOS отдаёт 640×480 + rotation=90, что
  /// нужно повернуть на 90° для портретного отображения).
  weak var contentVC: LighChatMeetingPipCallVC?

  /// Счётчик принятых кадров — раз в N логируем, чтобы видеть, что
  /// поток идёт. Сбрасывается в `teardown`.
  var frameCount: Int = 0

  /// Не используется (RTCVideoRenderer обязан реализовать, но AVSampleBuffer
  /// сам читает размер из CVPixelBuffer).
  func setSize(_ size: CGSize) {
    NSLog("[MeetingPiP] renderer.setSize → %@", NSCoder.string(for: size))
  }

  /// Маппинг WebRTC rotation → радианы для CALayer transform.
  private func radians(for rotation: RTCVideoRotation) -> CGFloat {
    switch rotation {
    case ._90: return .pi / 2
    case ._180: return .pi
    case ._270: return -.pi / 2
    default: return 0
    }
  }

  func renderFrame(_ frame: RTCVideoFrame?) {
    guard let frame = frame else {
      NSLog("[MeetingPiP] renderer.renderFrame: nil frame")
      return
    }
    guard let layer = self.displayLayer else {
      // Кадры приходят, но layer не подключён — это значит attach был
      // вызван без enterPip (или мы уже teardown'нулись).
      if frameCount % 60 == 0 {
        NSLog("[MeetingPiP] renderer: frame received but displayLayer=nil")
      }
      frameCount += 1
      return
    }

    // На iOS камера/screen-share отдают RTCCVPixelBuffer (NV12). Если
    // буфер другой — пропускаем кадр (PiP покажет последний валидный).
    // Конверсия I420→NV12 руками — отдельная задача, пока не нужна.
    guard let cv = frame.buffer as? RTCCVPixelBuffer else {
      if frameCount % 60 == 0 {
        NSLog("[MeetingPiP] renderer: non-CVPixelBuffer frame (type=%@), skip",
              String(describing: type(of: frame.buffer)))
      }
      frameCount += 1
      return
    }
    let pb = cv.pixelBuffer

    if frameCount == 0 {
      NSLog(
        "[MeetingPiP] renderer: FIRST FRAME (%dx%d, rotation=%ld)",
        CVPixelBufferGetWidth(pb), CVPixelBufferGetHeight(pb),
        frame.rotation.rawValue)
    } else if frameCount % 120 == 0 {
      NSLog("[MeetingPiP] renderer: %d frames pumped", frameCount)
    }
    frameCount += 1

    // Применить поворот при первом кадре и при смене rotation. CALayer
    // affine-transform поворачивает layer в его parent. AVSample-
    // BufferDisplayLayer с videoGravity=.resizeAspect аккуратно впишет
    // 640×480 → 480×640 portrait после 90° поворота.
    let targetRotation = radians(for: frame.rotation)
    if let vc = contentVC, vc.appliedRotation != targetRotation {
      let layer = layer  // capture local
      let rot = targetRotation
      DispatchQueue.main.async {
        layer.setAffineTransform(CGAffineTransform(rotationAngle: rot))
        vc.appliedRotation = rot
        NSLog("[MeetingPiP] renderer: applied rotation %.2f rad", Double(rot))
      }
    }

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
