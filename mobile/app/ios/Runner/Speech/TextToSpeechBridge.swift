import AVFoundation
import Flutter
import Foundation

/// Нативный TTS через `AVSpeechSynthesizer` — для функции «прочитать вслух»
/// текстовое сообщение в чате. Полностью оффлайн, ничего не тянет с сервера.
///
/// Channel: `lighchat/text_to_speech`. Методы:
///  - `speak(text, languageTag)` — начать чтение; если уже что-то читалось,
///     останавливает предыдущее.
///  - `stop()` — прекратить чтение.
///  - `isSpeaking()` — bool.
final class TextToSpeechBridge: NSObject {
  static let shared = TextToSpeechBridge()
  private static let logTag = "[TextToSpeech]"

  private let synthesizer = AVSpeechSynthesizer()

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/text_to_speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      let args = call.arguments as? [String: Any] ?? [:]
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let languageTag = args["languageTag"] as? String
      let rate = args["rate"] as? Double
      if text.isEmpty {
        result(false)
        return
      }
      // Останавливаем предыдущее чтение, если было.
      if synthesizer.isSpeaking {
        synthesizer.stopSpeaking(at: .immediate)
      }
      // Делаем плеер «доступным» для динамика, перебиваем mute-switch.
      do {
        try AVAudioSession.sharedInstance().setCategory(
          .playback, mode: .spokenAudio, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
      } catch {
        NSLog("%@ audio session setup failed: %@", Self.logTag, "\(error)")
      }
      let utterance = AVSpeechUtterance(string: text)
      if let tag = languageTag {
        utterance.voice = AVSpeechSynthesisVoice(
          language: tag.replacingOccurrences(of: "_", with: "-"))
      }
      utterance.rate = rate != nil
        ? Float(rate!)
        : AVSpeechUtteranceDefaultSpeechRate
      utterance.pitchMultiplier = 1.0
      utterance.preUtteranceDelay = 0
      synthesizer.speak(utterance)
      result(true)

    case "stop":
      if synthesizer.isSpeaking {
        synthesizer.stopSpeaking(at: .immediate)
      }
      result(nil)

    case "isSpeaking":
      result(synthesizer.isSpeaking)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
