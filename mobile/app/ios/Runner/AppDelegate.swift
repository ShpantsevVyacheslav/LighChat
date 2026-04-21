import AVFoundation
import AVKit
import Flutter
import UIKit
import FirebaseCore

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
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase as early as possible so plugins that touch Firebase
    // during registration don't log "No app has been configured yet."
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    LighChatIosPipBridge.shared.register(
      messenger: engineBridge.applicationRegistrar.messenger())
  }
}
