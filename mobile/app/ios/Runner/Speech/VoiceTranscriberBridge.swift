import Flutter
import Foundation
import Speech

/// On-device транскрибация голосовых сообщений через Apple Speech Framework.
///
/// Channel: `lighchat/voice_transcribe`. Контракт см. в
/// `mobile/app/lib/features/chat/data/local_voice_transcriber.dart`.
final class VoiceTranscriberBridge: NSObject {
  static let shared = VoiceTranscriberBridge()

  private let recognizerQueue = DispatchQueue(
    label: "lighchat.voice-transcriber", qos: .userInitiated)

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

    case "transcribeFile":
      let args = call.arguments as? [String: Any] ?? [:]
      let filePath = args["filePath"] as? String ?? ""
      let languageTag = args["languageTag"] as? String ?? "en-US"
      transcribe(filePath: filePath, languageTag: languageTag, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(
    filePath: String, languageTag: String, result: @escaping FlutterResult
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
        self.runRecognition(url: url, languageTag: languageTag, result: result)
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

  private func runRecognition(
    url: URL, languageTag: String, result: @escaping FlutterResult
  ) {
    let locale = Locale(identifier: languageTag.replacingOccurrences(of: "-", with: "_"))
    guard let recognizer = SFSpeechRecognizer(locale: locale) else {
      result(
        FlutterError(
          code: "unsupported_lang",
          message: "Recognizer not available for \(languageTag)",
          details: nil))
      return
    }
    if !recognizer.isAvailable {
      result(
        FlutterError(
          code: "recognizer_unavailable",
          message: "Recognizer is currently unavailable",
          details: nil))
      return
    }

    // Tier 1: on-device (если доступно). Fallback на серверное Apple-распознавание
    // — оно работает в РФ и часто точнее на коротких сообщениях.
    let canOnDevice: Bool = {
      if #available(iOS 13.0, *) { return recognizer.supportsOnDeviceRecognition }
      return false
    }()
    performRecognition(
      recognizer: recognizer, url: url,
      onDevice: canOnDevice,
      allowFallback: true,
      result: result)
  }

  private func performRecognition(
    recognizer: SFSpeechRecognizer, url: URL,
    onDevice: Bool, allowFallback: Bool, result: @escaping FlutterResult
  ) {
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.shouldReportPartialResults = false
    if #available(iOS 13.0, *) {
      request.requiresOnDeviceRecognition = onDevice
    }
    request.taskHint = .dictation

    recognizerQueue.async { [weak self] in
      var delivered = false
      let lock = NSLock()
      func deliver(_ value: Any?) {
        lock.lock()
        defer { lock.unlock() }
        if delivered { return }
        delivered = true
        DispatchQueue.main.async { result(value) }
      }

      _ = recognizer.recognitionTask(with: request) { recognitionResult, error in
        if let error = error as NSError? {
          if Self.isNoSpeechError(error) {
            if onDevice && allowFallback {
              // On-device не нашёл речь — это часто означает не «реально нет
              // речи», а «модели не хватило». Пробуем серверный путь Apple.
              lock.lock()
              if !delivered {
                delivered = true
                lock.unlock()
                self?.performRecognition(
                  recognizer: recognizer, url: url,
                  onDevice: false, allowFallback: false, result: result)
              } else {
                lock.unlock()
              }
              return
            }
            deliver(["text": ""])
            return
          }
          if onDevice && allowFallback {
            // Любая иная ошибка on-device — пробуем сервер.
            lock.lock()
            if !delivered {
              delivered = true
              lock.unlock()
              self?.performRecognition(
                recognizer: recognizer, url: url,
                onDevice: false, allowFallback: false, result: result)
            } else {
              lock.unlock()
            }
            return
          }
          deliver(
            FlutterError(
              code: "recognition_failed",
              message: error.localizedDescription,
              details: nil))
          return
        }
        guard let recognitionResult = recognitionResult else { return }
        if recognitionResult.isFinal {
          let text = recognitionResult.bestTranscription.formattedString
          deliver(["text": text])
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
}
