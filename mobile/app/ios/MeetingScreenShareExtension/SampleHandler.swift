//
//  SampleHandler.swift
//  MeetingScreenShareExtension — ReplayKit Broadcast Extension target.
//
//  Цель: захватывать кадры экрана через ReplayKit (отдельный процесс) и
//  передавать их в Runner-приложение через App Group + Darwin notifications.
//  В Runner новый плагин `LighChatMeetingScreenShareReceiver` подаст эти
//  кадры в собственный RTCVideoSource (flutter_webrtc) и заменит исходящий
//  video-track митинга.
//
//  Шаги, которые надо сделать в Xcode (выходят за рамки этого файла):
//   1. File → New → Target → "Broadcast Upload Extension". Bundle id:
//      `com.lighchat.app.MeetingScreenShareExtension` (или ваш Team prefix).
//   2. Подключить App Group `group.com.lighchat.app` к Runner и к
//      MeetingScreenShareExtension target'ам.
//   3. Заменить сгенерированный SampleHandler.swift на этот файл.
//   4. В Runner-таргете зарегистрировать receiver — см.
//      `ios/MeetingPip/MeetingScreenShareReceiver.swift`.
//   5. На стороне Dart: вызвать `RPSystemBroadcastPickerView` (или
//      `replaceTrack`) когда юзер тапает кнопку демонстрации экрана.
//
//  Этот файл компилируется ТОЛЬКО внутри отдельной таргет-программы
//  Broadcast Extension — Runner-таргет его не должен включать.

import ReplayKit
import CoreVideo
import os.log

private let appGroupId = "group.com.lighchat.app"
private let frameSharedKey = "lighchat.meeting.screen.frame"
private let frameUpdateNotification = "com.lighchat.app.screen_share.frame"
private let broadcastStartedNotification = "com.lighchat.app.screen_share.started"
private let broadcastStoppedNotification = "com.lighchat.app.screen_share.stopped"

@objc(LighChatScreenShareSampleHandler)
final class SampleHandler: RPBroadcastSampleHandler {

  private let logger = OSLog(subsystem: "com.lighchat.app", category: "ScreenShare")

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    os_log("Broadcast started", log: logger, type: .info)
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(broadcastStartedNotification as CFString),
      nil, nil, true
    )
  }

  override func broadcastFinished() {
    os_log("Broadcast finished", log: logger, type: .info)
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(broadcastStoppedNotification as CFString),
      nil, nil, true
    )
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer,
    with sampleBufferType: RPSampleBufferType
  ) {
    guard sampleBufferType == .video else { return }
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    // Сериализуем CVPixelBuffer в shared memory App Group.
    // Полный байтовый пуш: width|height|pixelFormat|rowBytes|planes...
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
    let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let dataSize = rowBytes * height

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

    var header = Data()
    header.append(UInt32(width).bigEndianData)
    header.append(UInt32(height).bigEndianData)
    header.append(UInt32(format).bigEndianData)
    header.append(UInt32(rowBytes).bigEndianData)
    header.append(UInt32(dataSize).bigEndianData)

    var payload = header
    payload.append(Data(bytes: baseAddress, count: dataSize))

    if let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.set(payload, forKey: frameSharedKey)
    }

    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(frameUpdateNotification as CFString),
      nil, nil, true
    )
  }
}

private extension UInt32 {
  var bigEndianData: Data {
    var v = self.bigEndian
    return Data(bytes: &v, count: 4)
  }
}
