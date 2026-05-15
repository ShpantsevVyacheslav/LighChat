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
      let normalizedTag = languageTag?
        .replacingOccurrences(of: "_", with: "-")
      // Выбираем лучший доступный голос: premium > enhanced > default.
      // По дефолту AVSpeechSynthesisVoice(language:) даёт самый низкий
      // Compact, который звучит как «робот». Premium/Enhanced требуют
      // установки в Settings → Accessibility → Spoken Content → Voices,
      // но если они есть — звучат естественно (нейросетевой синтез).
      let voice = Self.pickBestVoice(languageTag: normalizedTag)
      if let voice = voice {
        utterance.voice = voice
        let qualityName: String = {
          if #available(iOS 16.0, *) {
            switch voice.quality {
            case .premium: return "premium"
            case .enhanced: return "enhanced"
            default: return "default"
            }
          }
          return "default"
        }()
        NSLog(
          "%@ picked voice: %@ (lang=%@ quality=%@)",
          Self.logTag, voice.name, voice.language, qualityName)
      } else if let tag = normalizedTag {
        // Fallback на legacy API (даст Compact, но хоть что-то).
        utterance.voice = AVSpeechSynthesisVoice(language: tag)
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

    case "voiceQualityInfo":
      let args = call.arguments as? [String: Any] ?? [:]
      let tag = (args["languageTag"] as? String)?
        .replacingOccurrences(of: "_", with: "-")
      result(Self.voiceQualityInfo(languageTag: tag))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Выбирает лучший доступный голос для запрошенного языка.
  /// Приоритет: premium → enhanced → default.
  /// Внутри одного качества предпочитаем точное совпадение `ru-RU`
  /// над `ru-*`. Premium доступен только iOS 16+.
  private static func pickBestVoice(languageTag: String?)
    -> AVSpeechSynthesisVoice?
  {
    let allVoices = AVSpeechSynthesisVoice.speechVoices()
    let langCandidates: [String]
    if let tag = languageTag, !tag.isEmpty {
      // Точная локаль + язык-префикс. Это позволит «ru» подобрать ru-RU,
      // а «ru-RU» — именно его.
      let lang = String(tag.split(separator: "-").first ?? "")
      langCandidates = [tag, lang].filter { !$0.isEmpty }
    } else {
      langCandidates = [Locale.current.identifier]
    }

    func matches(_ voice: AVSpeechSynthesisVoice, _ candidate: String) -> Bool {
      let vl = voice.language.lowercased()
      let cl = candidate.lowercased()
      return vl == cl || vl.hasPrefix("\(cl)-") || cl.hasPrefix("\(vl)-")
    }

    // Сначала точные совпадения, потом префикс.
    for candidate in langCandidates {
      let matched = allVoices.filter { matches($0, candidate) }
      if matched.isEmpty { continue }
      // Сортируем по quality (выше = лучше).
      let sorted = matched.sorted { a, b in
        Self.qualityRank(a) > Self.qualityRank(b)
      }
      return sorted.first
    }
    return nil
  }

  private static func qualityRank(_ voice: AVSpeechSynthesisVoice) -> Int {
    if #available(iOS 16.0, *) {
      switch voice.quality {
      case .premium: return 3
      case .enhanced: return 2
      default: return 1
      }
    }
    switch voice.quality {
    case .enhanced: return 2
    default: return 1
    }
  }

  /// Сообщает Dart-слою какое максимальное качество доступно для языка.
  /// Возвращает map `{ best: 'premium'|'enhanced'|'default'|'none',
  /// hasEnhancedOrBetter: bool, voiceName: String? }`.
  /// Dart может показать пользователю tip: «качайте Enhanced в Настройках».
  private static func voiceQualityInfo(languageTag: String?)
    -> [String: Any]
  {
    guard let voice = pickBestVoice(languageTag: languageTag) else {
      return ["best": "none", "hasEnhancedOrBetter": false, "voiceName": nil]
    }
    let q = qualityRank(voice)
    let label: String
    switch q {
    case 3: label = "premium"
    case 2: label = "enhanced"
    default: label = "default"
    }
    return [
      "best": label,
      "hasEnhancedOrBetter": q >= 2,
      "voiceName": voice.name,
      "voiceLanguage": voice.language,
    ]
  }
}
