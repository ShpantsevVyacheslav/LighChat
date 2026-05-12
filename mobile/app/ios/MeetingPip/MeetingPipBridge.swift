//
//  MeetingPipBridge.swift
//  Native iOS Picture-in-Picture для активной видеоконференции.
//
//  Контракт MethodChannel `lighchat/meeting_pip`:
//   - `isSupported()` → Bool: умеет ли OS показывать PiP-окно для произвольного
//     `AVSampleBufferDisplayLayer` (iOS 15+).
//   - `enter()` → Bool: входит в PiP; видео-кадры подаёт frameSink (TODO: wire
//     с flutter_webrtc RTCVideoTrack для активного спикера).
//   - `exit()` → Bool: выходит из PiP.
//
//  Регистрация: вызывается из `AppDelegate.didInitializeImplicitFlutterEngine`.
//  Для активации добавьте этот файл в Runner target и зовите
//  `LighChatMeetingPipBridge.shared.register(messenger:)`.
//
//  Известные ограничения текущей реализации:
//   - Без подключённого frame sink окно PiP покажет последний доступный
//     кадр или пустое содержимое. Frame sink интегрируется в отдельном
//     native-PR — нужно прокинуть `CMSampleBuffer` из flutter_webrtc-уровня.
//   - PiP запускается только пока приложение в foreground (требование Apple).

import AVKit
import AVFoundation
import Flutter
import UIKit

@available(iOS 15.0, *)
final class LighChatMeetingPipBridge: NSObject {
  static let shared = LighChatMeetingPipBridge()

  private var pipController: AVPictureInPictureController?
  private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
  private var hostView: UIView?
  private var pipContentSource: AVPictureInPictureController.ContentSource?

  private override init() {
    super.init()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/meeting_pip", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "enter":
        DispatchQueue.main.async {
          self.enterPip(result: result)
        }
      case "exit":
        DispatchQueue.main.async {
          self.exitPip(result: result)
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

  private func enterPip(result: @escaping FlutterResult) {
    guard AVPictureInPictureController.isPictureInPictureSupported() else {
      result(false)
      return
    }
    guard let window = Self.keyWindow() else {
      result(false)
      return
    }

    // VoIP audio session для непрерывного аудио в PiP.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord,
        mode: .videoChat,
        options: [.allowBluetooth, .defaultToSpeaker]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}

    let displayLayer = AVSampleBufferDisplayLayer()
    displayLayer.videoGravity = .resizeAspect
    displayLayer.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
    self.sampleBufferDisplayLayer = displayLayer

    let host = UIView(frame: CGRect(x: -4000, y: -4000, width: 4, height: 4))
    host.isUserInteractionEnabled = false
    host.layer.addSublayer(displayLayer)
    window.addSubview(host)
    self.hostView = host

    let source = AVPictureInPictureController.ContentSource(
      sampleBufferDisplayLayer: displayLayer,
      playbackDelegate: LighChatMeetingPipPlayback.shared
    )
    self.pipContentSource = source

    let pip = AVPictureInPictureController(contentSource: source)
    pip.canStartPictureInPictureAutomaticallyFromInline = true
    pip.delegate = LighChatMeetingPipDelegate.shared
    self.pipController = pip

    // Заводим placeholder-кадр, чтобы PiP-окно не было чёрным до прихода
    // первого реального кадра от WebRTC frame sink.
    LighChatMeetingPipFrameSink.shared.attach(layer: displayLayer)
    LighChatMeetingPipFrameSink.shared.pushPlaceholder()

    // `isPictureInPicturePossible` становится true только после нескольких
    // тиков обновления слоя.
    self.attemptStart(pip: pip, attemptsLeft: 30, result: result)
  }

  private func attemptStart(
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
      self.attemptStart(pip: pip, attemptsLeft: attemptsLeft - 1, result: result)
    }
  }

  private func exitPip(result: @escaping FlutterResult) {
    pipController?.stopPictureInPicture()
    teardown()
    result(true)
  }

  fileprivate func teardown() {
    pipController?.delegate = nil
    pipController = nil
    pipContentSource = nil
    sampleBufferDisplayLayer = nil
    hostView?.removeFromSuperview()
    hostView = nil
    LighChatMeetingPipFrameSink.shared.detach()
  }
}

@available(iOS 15.0, *)
private final class LighChatMeetingPipDelegate: NSObject,
  AVPictureInPictureControllerDelegate
{
  static let shared = LighChatMeetingPipDelegate()

  func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    LighChatMeetingPipBridge.shared.teardown()
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    LighChatMeetingPipBridge.shared.teardown()
  }
}

@available(iOS 15.0, *)
private final class LighChatMeetingPipPlayback: NSObject,
  AVPictureInPictureSampleBufferPlaybackDelegate
{
  static let shared = LighChatMeetingPipPlayback()

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    setPlaying playing: Bool
  ) {
    // Live-стрим — управление паузой не нужно.
  }

  func pictureInPictureControllerTimeRangeForPlayback(
    _ pictureInPictureController: AVPictureInPictureController
  ) -> CMTimeRange {
    // Live: бесконечный неограниченный диапазон.
    return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
  }

  func pictureInPictureControllerIsPlaybackPaused(
    _ pictureInPictureController: AVPictureInPictureController
  ) -> Bool {
    return false
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    didTransitionToRenderSize newRenderSize: CMVideoDimensions
  ) {}

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}

/// Frame sink: внешний (flutter_webrtc) код пушит сюда CMSampleBuffer,
/// мы их кладём в AVSampleBufferDisplayLayer. Пока интеграции нет —
/// показываем серый placeholder, чтобы PiP-окно появилось и принял первый
/// `pictureInPictureControllerTimeRangeForPlayback`.
@available(iOS 15.0, *)
final class LighChatMeetingPipFrameSink {
  static let shared = LighChatMeetingPipFrameSink()
  private weak var layer: AVSampleBufferDisplayLayer?

  func attach(layer: AVSampleBufferDisplayLayer) {
    self.layer = layer
  }

  func detach() {
    self.layer = nil
  }

  func push(sampleBuffer: CMSampleBuffer) {
    guard let layer = layer else { return }
    if layer.isReadyForMoreMediaData {
      layer.enqueue(sampleBuffer)
    }
  }

  /// Заглушка-серый кадр 1x1 — пока WebRTC sink не подключён, нужен один
  /// валидный CMSampleBuffer, чтобы `isPictureInPicturePossible` стал true.
  func pushPlaceholder() {
    guard let layer = layer else { return }
    var pixelBuffer: CVPixelBuffer?
    let attrs: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]
    CVPixelBufferCreate(
      kCFAllocatorDefault, 320, 240, kCVPixelFormatType_32BGRA,
      attrs as CFDictionary, &pixelBuffer)
    guard let buffer = pixelBuffer else { return }
    CVPixelBufferLockBaseAddress(buffer, [])
    if let ptr = CVPixelBufferGetBaseAddress(buffer) {
      // Заливаем тёмно-серым (RGBA в BGRA layout).
      let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
      let height = CVPixelBufferGetHeight(buffer)
      let total = rowBytes * height
      memset(ptr, 0x20, total)
    }
    CVPixelBufferUnlockBaseAddress(buffer, [])

    var formatDesc: CMFormatDescription?
    CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: nil, imageBuffer: buffer, formatDescriptionOut: &formatDesc)
    guard let desc = formatDesc else { return }

    var timing = CMSampleTimingInfo(
      duration: CMTime(value: 1, timescale: 30),
      presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000),
      decodeTimeStamp: .invalid)

    var sampleBuffer: CMSampleBuffer?
    CMSampleBufferCreateForImageBuffer(
      allocator: nil, imageBuffer: buffer, dataReady: true,
      makeDataReadyCallback: nil, refcon: nil,
      formatDescription: desc, sampleTiming: &timing,
      sampleBufferOut: &sampleBuffer)
    if let sb = sampleBuffer, layer.isReadyForMoreMediaData {
      layer.enqueue(sb)
    }
  }
}
