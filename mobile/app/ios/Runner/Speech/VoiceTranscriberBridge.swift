import Flutter
import Foundation
import NaturalLanguage
import Speech

/// On-device транскрибация голосовых сообщений через Apple Speech Framework.
///
/// Channel: `lighchat/voice_transcribe`. Контракт см. в
/// `mobile/app/lib/features/chat/data/local_voice_transcriber.dart`.
///
/// Поддерживается двухпроходный авто-детект языка: после первого прогона
/// результат пропускается через `NLLanguageRecognizer`; если язык текста
/// расходится с локалью распознавателя — делаем повторный прогон с
/// определённой локалью. Это покрывает кейс «UI на en, голосовое на ru»,
/// где английский распознаватель Apple возвращает мусор/empty.
final class VoiceTranscriberBridge: NSObject {
  static let shared = VoiceTranscriberBridge()
  private static let logTag = "[VoiceTranscribe]"

  private let recognizerQueue = DispatchQueue(
    label: "lighchat.voice-transcriber", qos: .userInitiated)

  /// Лог в `os_log`/`NSLog` — видно в Xcode console и `flutter run`.
  private static func log(_ message: @autoclosure () -> String) {
    NSLog("%@ %@", logTag, message())
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/voice_transcribe", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "supportedLocales":
      let tags = SFSpeechRecognizer.supportedLocales()
        .map { $0.identifier.replacingOccurrences(of: "_", with: "-") }
        .sorted()
      result(tags)

    case "detectLanguage":
      // Определение языка по строке через NLLanguageRecognizer (быстро, на
      // устройстве, без моделей). Используется для текстовых сообщений в чате,
      // чтобы решить, показывать ли кнопку «Translate».
      let args = call.arguments as? [String: Any] ?? [:]
      let text = args["text"] as? String ?? ""
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result(["language": "", "confidence": 0.0])
        return
      }
      let recognizer = NLLanguageRecognizer()
      recognizer.processString(text)
      let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
      if let top = hypotheses.max(by: { $0.value < $1.value }) {
        result([
          "language": top.key.rawValue.lowercased(),
          "confidence": top.value,
        ])
      } else {
        result(["language": "", "confidence": 0.0])
      }

    case "detectSentiment":
      // Сентимент-анализ строки через NLTagger.sentimentScore — `-1.0` … `+1.0`.
      // На iOS 13+ работает офлайн, без отдельных моделей. Хорошо ловит сильную
      // тональность («ты молодец», «бесит»); на нейтральных коротких фразах
      // вернёт ~0.0 — это нормально, UI должен интерпретировать как «нейтрально».
      let args = call.arguments as? [String: Any] ?? [:]
      let text = args["text"] as? String ?? ""
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        result(["score": 0.0])
        return
      }
      if #available(iOS 13.0, *) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(
          at: text.startIndex,
          unit: .paragraph,
          scheme: .sentimentScore)
        let score = Double(tag?.rawValue ?? "0") ?? 0.0
        result(["score": score])
      } else {
        result(["score": 0.0])
      }

    case "transcribeFile":
      let args = call.arguments as? [String: Any] ?? [:]
      let filePath = args["filePath"] as? String ?? ""
      let languageTag = args["languageTag"] as? String ?? "en-US"
      let autoDetect = (args["autoDetect"] as? Bool) ?? true
      let fallbackLocales = (args["fallbackLocales"] as? [String]) ?? []
      Self.log(
        "transcribeFile path=\(filePath) primary=\(languageTag) "
          + "auto=\(autoDetect) fallbacks=\(fallbackLocales)")
      transcribe(
        filePath: filePath, languageTag: languageTag,
        autoDetect: autoDetect,
        fallbackLocales: fallbackLocales,
        result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(
    filePath: String, languageTag: String,
    autoDetect: Bool, fallbackLocales: [String],
    result: @escaping FlutterResult
  ) {
    if filePath.isEmpty {
      result(
        FlutterError(code: "invalid_url", message: "Empty filePath", details: nil))
      return
    }
    let url = URL(fileURLWithPath: filePath)
    if !FileManager.default.fileExists(atPath: url.path) {
      result(
        FlutterError(code: "file_not_found", message: filePath, details: nil))
      return
    }

    requestAuthorization { [weak self] status in
      guard let self = self else { return }
      switch status {
      case .authorized:
        self.runRecognitionFlow(
          url: url, languageTag: languageTag,
          autoDetect: autoDetect, fallbackLocales: fallbackLocales,
          result: result)
      case .denied:
        result(
          FlutterError(
            code: "permission_denied",
            message: "Speech recognition permission denied",
            details: nil))
      case .restricted:
        result(
          FlutterError(
            code: "permission_restricted",
            message: "Speech recognition restricted on this device",
            details: nil))
      case .notDetermined:
        result(
          FlutterError(
            code: "permission_denied",
            message: "Permission not granted",
            details: nil))
      @unknown default:
        result(
          FlutterError(
            code: "permission_denied",
            message: "Unknown permission state",
            details: nil))
      }
    }
  }

  private func requestAuthorization(
    _ completion: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
  ) {
    let current = SFSpeechRecognizer.authorizationStatus()
    if current == .authorized {
      completion(.authorized)
      return
    }
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async { completion(status) }
    }
  }

  // MARK: - Recognition flow

  private func runRecognitionFlow(
    url: URL, languageTag: String,
    autoDetect: Bool, fallbackLocales: [String],
    result: @escaping FlutterResult
  ) {
    let primary = Locale(
      identifier: languageTag.replacingOccurrences(of: "-", with: "_"))
    let candidates: [Locale] = [primary] + fallbackLocales.map {
      Locale(identifier: $0.replacingOccurrences(of: "-", with: "_"))
    }
    attemptRecognitionCandidates(
      url: url, candidates: candidates, autoDetect: autoDetect,
      index: 0, lastError: nil, result: result)
  }

  /// Перебираем локали-кандидаты по порядку. Берём первый непустой
  /// результат; пустые/ошибки скипают локаль. Если всё опустошилось —
  /// возвращаем пусто (или ошибку, если ни одна локаль не дала результата
  /// даже на ошибку).
  private func attemptRecognitionCandidates(
    url: URL, candidates: [Locale], autoDetect: Bool,
    index: Int, lastError: NSError?, result: @escaping FlutterResult
  ) {
    guard index < candidates.count else {
      Self.log("all candidates exhausted, returning empty")
      if let err = lastError, candidates.count == 1 {
        result(
          FlutterError(
            code: "recognition_failed",
            message: err.localizedDescription,
            details: nil))
      } else {
        result([
          "text": "",
          "detectedLanguage": "",
          "segments": [],
        ])
      }
      return
    }
    let locale = candidates[index]
    Self.log("attempt #\(index) locale=\(locale.identifier)")
    guard let recognizer = makeRecognizer(locale: locale) else {
      Self.log(
        "→ recognizer unavailable for \(locale.identifier), trying next")
      attemptRecognitionCandidates(
        url: url, candidates: candidates, autoDetect: autoDetect,
        index: index + 1, lastError: lastError, result: result)
      return
    }
    performRecognition(recognizer: recognizer, url: url) {
      [weak self] outcome in
      switch outcome {
      case .failure(let error):
        Self.log(
          "→ failure on \(locale.identifier): "
            + "[\(error.domain) \(error.code)] \(error.localizedDescription)")
        self?.attemptRecognitionCandidates(
          url: url, candidates: candidates, autoDetect: autoDetect,
          index: index + 1, lastError: error, result: result)
      case .success(let output):
        Self.log(
          "→ success on \(locale.identifier), textLen=\(output.text.count) "
            + "segs=\(output.segments.count) "
            + "preview=\"\(output.text.prefix(60))\"")
        if !output.text.isEmpty {
          if autoDetect {
            self?.maybeReRunWithDetectedLanguage(
              originalLocale: locale, originalOutput: output,
              url: url, result: result)
          } else {
            result([
              "text": output.text,
              "detectedLanguage": locale.languageCode ?? "",
              "segments": output.segments,
            ])
          }
          return
        }
        // Пустой результат — пробуем следующего кандидата.
        Self.log("→ empty text, trying next candidate")
        self?.attemptRecognitionCandidates(
          url: url, candidates: candidates, autoDetect: autoDetect,
          index: index + 1, lastError: lastError, result: result)
      }
    }
  }

  private func makeRecognizer(locale: Locale) -> SFSpeechRecognizer? {
    guard let recognizer = SFSpeechRecognizer(locale: locale) else {
      return nil
    }
    if !recognizer.isAvailable { return nil }
    return recognizer
  }

  /// Результат одного прогона распознавания: финальный текст + word-level
  /// сегменты с таймкодами для karaoke-подсветки и skip-silence.
  struct RecognitionOutput {
    let text: String
    let segments: [[String: Any]] // {text, start, duration, confidence}
  }

  /// Запуск распознавания с fallback'ом on-device → серверное Apple-распознавание.
  /// Возвращает `Result<RecognitionOutput, NSError>`:
  /// - `.success(empty)` — речь не распознана (no-speech ошибки трактуем как пустоту);
  /// - `.success(filled)` — финальный текст + сегменты;
  /// - `.failure(err)` — неустранимая ошибка.
  private func performRecognition(
    recognizer: SFSpeechRecognizer, url: URL,
    completion: @escaping (Result<RecognitionOutput, NSError>) -> Void
  ) {
    let canOnDevice: Bool = {
      if #available(iOS 13.0, *) { return recognizer.supportsOnDeviceRecognition }
      return false
    }()
    performRecognitionPass(
      recognizer: recognizer, url: url,
      onDevice: canOnDevice, allowFallback: true,
      completion: completion)
  }

  private func performRecognitionPass(
    recognizer: SFSpeechRecognizer, url: URL,
    onDevice: Bool, allowFallback: Bool,
    completion: @escaping (Result<RecognitionOutput, NSError>) -> Void
  ) {
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.shouldReportPartialResults = false
    if #available(iOS 13.0, *) {
      request.requiresOnDeviceRecognition = onDevice
    }
    // Авто-пунктуация (точки, запятые, ?, !) — iOS 16+.
    if #available(iOS 16.0, *) {
      request.addsPunctuation = true
    }
    request.taskHint = .dictation

    recognizerQueue.async { [weak self] in
      var delivered = false
      let lock = NSLock()
      func deliver(_ value: Result<RecognitionOutput, NSError>) {
        lock.lock(); defer { lock.unlock() }
        if delivered { return }
        delivered = true
        DispatchQueue.main.async { completion(value) }
      }
      func tryFallback() -> Bool {
        lock.lock()
        if delivered { lock.unlock(); return false }
        delivered = true
        lock.unlock()
        self?.performRecognitionPass(
          recognizer: recognizer, url: url,
          onDevice: false, allowFallback: false,
          completion: completion)
        return true
      }

      _ = recognizer.recognitionTask(with: request) { recognitionResult, error in
        if let error = error as NSError? {
          if Self.isNoSpeechError(error) {
            if onDevice && allowFallback, tryFallback() { return }
            deliver(.success(RecognitionOutput(text: "", segments: [])))
            return
          }
          if onDevice && allowFallback, tryFallback() { return }
          deliver(.failure(error))
          return
        }
        guard let recognitionResult = recognitionResult else { return }
        if recognitionResult.isFinal {
          let transcription = recognitionResult.bestTranscription
          let text = transcription.formattedString
          let segments: [[String: Any]] = transcription.segments.map {
            seg in
            [
              "text": seg.substring,
              "start": seg.timestamp,
              "duration": seg.duration,
              "confidence": seg.confidence,
            ]
          }
          deliver(.success(RecognitionOutput(text: text, segments: segments)))
        }
      }
    }
  }

  private static func isNoSpeechError(_ error: NSError) -> Bool {
    if error.domain == "kAFAssistantErrorDomain"
      && [203, 1110, 1700].contains(error.code)
    {
      return true
    }
    return error.localizedDescription.lowercased().contains("no speech")
  }

  // MARK: - Auto language detection

  /// После первого прогона определяем язык по тексту. Если он отличается от
  /// локали распознавателя с уверенностью ≥ 0.75 — повторяем распознавание
  /// с правильной локалью и возвращаем новый результат. Иначе — оставляем
  /// первичный текст.
  private func maybeReRunWithDetectedLanguage(
    originalLocale: Locale,
    originalOutput: RecognitionOutput,
    url: URL,
    result: @escaping FlutterResult
  ) {
    let originalCode = (originalLocale.languageCode ?? "").lowercased()
    let originalText = originalOutput.text
    let originalSegs = originalOutput.segments
    let langRecognizer = NLLanguageRecognizer()
    langRecognizer.processString(originalText)
    let hypotheses = langRecognizer.languageHypotheses(withMaximum: 3)
    let sorted = hypotheses.sorted { $0.value > $1.value }
    Self.log(
      "NLLanguageRecognizer top hypotheses: "
        + sorted.prefix(3)
        .map { "\($0.key.rawValue)=\(String(format: "%.2f", $0.value))" }
        .joined(separator: ", "))
    func keepOriginal() {
      result([
        "text": originalText,
        "detectedLanguage": originalCode,
        "segments": originalSegs,
      ])
    }
    guard let (topLang, confidence) = sorted.first else {
      Self.log("→ no hypotheses, keeping original (\(originalCode))")
      keepOriginal()
      return
    }
    let detectedCode = topLang.rawValue.lowercased()
    if detectedCode == originalCode || confidence < 0.75 {
      Self.log(
        "→ detected=\(detectedCode) same as original or low conf, "
          + "keeping original (\(originalCode))")
      keepOriginal()
      return
    }
    // Подбираем поддерживаемую локаль распознавания для определённого языка.
    guard let newLocale = bestRecognitionLocale(for: detectedCode) else {
      Self.log("→ no SFSpeech locale for \(detectedCode), keeping original")
      keepOriginal()
      return
    }
    guard let newRecognizer = makeRecognizer(locale: newLocale) else {
      Self.log(
        "→ recognizer unavailable for \(newLocale.identifier), keeping original")
      keepOriginal()
      return
    }
    Self.log(
      "→ re-running with detected locale=\(newLocale.identifier) "
        + "(conf=\(String(format: "%.2f", confidence)))")
    performRecognition(recognizer: newRecognizer, url: url) { outcome in
      switch outcome {
      case .success(let secondary):
        if secondary.text.isEmpty {
          Self.log(
            "→ rerun returned empty, falling back to original (\(originalCode))")
          keepOriginal()
        } else {
          let finalLang = newLocale.languageCode ?? detectedCode
          Self.log(
            "→ rerun success, final lang=\(finalLang) "
              + "textLen=\(secondary.text.count) segs=\(secondary.segments.count)")
          result([
            "text": secondary.text,
            "detectedLanguage": finalLang,
            "segments": secondary.segments,
          ])
        }
      case .failure(let err):
        Self.log(
          "→ rerun failed [\(err.domain) \(err.code)] \(err.localizedDescription), "
            + "keeping original")
        keepOriginal()
      }
    }
  }

  /// Из множества поддерживаемых локалей Apple Speech выбираем ту, которая
  /// соответствует языку (BCP-47 prefix). Приоритет — каноничные регионы
  /// (`ru_RU`, `en_US`, `pt_BR`, `es_ES` и т. п.).
  private func bestRecognitionLocale(for languageCode: String) -> Locale? {
    let lang = languageCode.lowercased()
    let supported = SFSpeechRecognizer.supportedLocales()
    let candidates = supported.filter {
      ($0.languageCode ?? "").lowercased() == lang
    }
    if candidates.isEmpty { return nil }
    let preferredRegion = Self.preferredRegion(for: lang)
    if let exact = candidates.first(where: { $0.regionCode == preferredRegion }) {
      return exact
    }
    return candidates.first
  }

  private static func preferredRegion(for languageCode: String) -> String {
    switch languageCode {
    case "ru": return "RU"
    case "en": return "US"
    case "es": return "ES"
    case "pt": return "BR"
    case "tr": return "TR"
    case "id": return "ID"
    case "kk": return "KZ"
    case "uz": return "UZ"
    case "de": return "DE"
    case "fr": return "FR"
    case "it": return "IT"
    case "ja": return "JP"
    case "ko": return "KR"
    case "zh": return "CN"
    case "ar": return "SA"
    case "uk": return "UA"
    case "be": return "BY"
    case "pl": return "PL"
    case "cs": return "CZ"
    case "nl": return "NL"
    case "sv": return "SE"
    case "no", "nb": return "NO"
    case "fi": return "FI"
    case "da": return "DK"
    case "el": return "GR"
    case "he": return "IL"
    case "th": return "TH"
    case "vi": return "VN"
    case "hi": return "IN"
    default: return languageCode.uppercased()
    }
  }
}
