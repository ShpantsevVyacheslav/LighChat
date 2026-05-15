import Flutter
import Foundation

#if canImport(FoundationModels)
  import FoundationModels
#endif

/// Bridge к Apple Intelligence Foundation Models (iOS 18.1+/26+).
///
/// Channel: `lighchat/apple_intelligence`.
///
/// Доступные методы:
///  - `isAvailable()` → `Bool`
///  - `summarizeText(text)` → `String?` — 1-2 предложения резюме
///  - `rewriteText(text, style)` → `String?` — переписать текст в стиле
///    (`friendly` | `formal` | `shorter` | `longer` | `proofread`)
///  - `summarizeMessages(messages)` → `String?` — компактный digest по списку
///    последних сообщений в чате (формат `Sender: text\n`)
///
/// Если фреймворк отсутствует / модель не загружена / юзер отключил Apple
/// Intelligence — возвращаем `null`. Dart-уровень должен fail-gracefully.
final class AppleIntelligenceBridge: NSObject {
  static let shared = AppleIntelligenceBridge()
  private static let logTag = "[AppleIntelligence]"

  /// Активные стрим-задачи: streamId → Task. Хранятся чтобы можно было
  /// cancelStream() их остановить — пользователь может закрыть шторку до
  /// завершения генерации.
  private var streamTasks: [String: Task<Void, Never>] = [:]
  private var streamSink: FlutterEventSink?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/apple_intelligence", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    let stream = FlutterEventChannel(
      name: "lighchat/apple_intelligence_stream", binaryMessenger: messenger)
    stream.setStreamHandler(_AiStreamHandler(bridge: self))
  }

  func attachStreamSink(_ sink: @escaping FlutterEventSink) {
    streamSink = sink
  }

  func detachStreamSink() {
    streamSink = nil
  }

  private func emit(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.streamSink?(payload)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "isAvailable":
      result(Self.isFoundationModelsAvailable())

    case "availabilityStatus":
      result(Self.availabilityStatus())

    case "summarizeText":
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if text.isEmpty { result(nil); return }
      Self.respond(
        instructions:
          "You are a concise summarizer. Always reply in the same language as the input. Output one or two short sentences.",
        prompt: "Summarize this briefly:\n\n\(text)",
        completion: result)

    case "rewriteText":
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let style = (args["style"] as? String ?? "friendly").lowercased()
      if text.isEmpty { result(nil); return }
      let (sys, ask) = Self.rewritePrompt(style: style, text: text)
      Self.respond(instructions: sys, prompt: ask, completion: result)

    case "summarizeMessages":
      let messages = (args["messages"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if messages.isEmpty { result(nil); return }
      Self.respond(
        instructions:
          "You are a chat digest writer. Always reply in the same language as the dialog. Output 3-5 short bullet points, each prefixed with '— '. Focus on decisions, questions, plans and named entities.",
        prompt:
          "Summarize the recent dialog from a group chat:\n\n\(messages)",
        completion: result)

    case "streamSummarize":
      let streamId = (args["streamId"] as? String) ?? ""
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if streamId.isEmpty || text.isEmpty {
        result(false); return
      }
      startStream(
        streamId: streamId,
        instructions:
          "You are a concise summarizer. Always reply in the same language as the input. Output one or two short sentences.",
        prompt: "Summarize this briefly:\n\n\(text)")
      result(true)

    case "streamRewrite":
      let streamId = (args["streamId"] as? String) ?? ""
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let style = (args["style"] as? String ?? "friendly").lowercased()
      if streamId.isEmpty || text.isEmpty {
        result(false); return
      }
      let (sys, ask) = Self.rewritePrompt(style: style, text: text)
      startStream(streamId: streamId, instructions: sys, prompt: ask)
      result(true)

    case "cancelStream":
      let streamId = (args["streamId"] as? String) ?? ""
      if let t = streamTasks.removeValue(forKey: streamId) {
        t.cancel()
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startStream(
    streamId: String, instructions: String, prompt: String
  ) {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
          emit([
            "streamId": streamId,
            "event": "error",
            "reason": "unavailable",
          ])
          return
        }
        let task = Task { [weak self] in
          guard let self = self else { return }
          do {
            let session = LanguageModelSession(instructions: instructions)
            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
              if Task.isCancelled { break }
              // partial.content — накопительный текст, не дельта.
              self.emit([
                "streamId": streamId,
                "event": "delta",
                "content": partial.content,
              ])
            }
            if !Task.isCancelled {
              self.emit([
                "streamId": streamId,
                "event": "done",
              ])
            }
          } catch is CancellationError {
            // silent
          } catch {
            NSLog("%@ stream error: %@", Self.logTag, "\(error)")
            self.emit([
              "streamId": streamId,
              "event": "error",
              "reason": "exception",
            ])
          }
          self.streamTasks.removeValue(forKey: streamId)
        }
        streamTasks[streamId] = task
        return
      }
    #endif
    emit([
      "streamId": streamId,
      "event": "error",
      "reason": "unsupportedOs",
    ])
  }

  static func isFoundationModelsAvailable() -> Bool {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        let avail = model.availability
        if case .available = avail { return true }
        NSLog("%@ availability check: %@", logTag, "\(avail)")
      } else {
        NSLog("%@ iOS < 26 — Foundation Models not present", logTag)
      }
    #else
      NSLog("%@ FoundationModels framework absent in SDK", logTag)
    #endif
    return false
  }

  /// Подробный статус модели — для UI «почему AI не работает». Возвращает
  /// один из: `available`, `appleIntelligenceNotEnabled`, `modelNotReady`,
  /// `deviceNotEligible`, `unsupportedOs`, `sdkMissing`, `unknown`.
  static func availabilityStatus() -> String {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
          return "available"
        case .unavailable(let reason):
          let r = "\(reason)".lowercased()
          if r.contains("appleintelligencenotenabled") {
            return "appleIntelligenceNotEnabled"
          }
          if r.contains("modelnotready") || r.contains("downloading") {
            return "modelNotReady"
          }
          if r.contains("devicenoteligible") {
            return "deviceNotEligible"
          }
          NSLog("%@ unknown unavailability reason: %@", logTag, r)
          return "unknown"
        @unknown default:
          return "unknown"
        }
      }
      return "unsupportedOs"
    #else
      return "sdkMissing"
    #endif
  }

  private static func rewritePrompt(style: String, text: String)
    -> (String, String)
  {
    let system: String
    switch style {
    case "formal":
      system =
        "You are a writing assistant. Rewrite the message to sound more formal and polite while preserving meaning. Reply in the same language as input. Do not add extra commentary, output only the rewritten message."
    case "shorter":
      system =
        "You are a writing assistant. Rewrite the message as briefly as possible while preserving meaning. Reply in the same language as input. Output only the rewritten message."
    case "longer":
      system =
        "You are a writing assistant. Rewrite the message a bit more elaborately, adding natural details, while preserving the original meaning. Reply in the same language. Output only the rewritten message."
    case "proofread":
      system =
        "You are a proofreader. Fix spelling, grammar and awkward phrasing without changing the meaning or tone. Reply in the same language as input. Output only the corrected message."
    default:  // "friendly"
      system =
        "You are a writing assistant. Rewrite the message to sound friendlier and warmer while preserving meaning. Reply in the same language as input. Output only the rewritten message."
    }
    return (system, "Rewrite this message:\n\n\(text)")
  }

  private static func respond(
    instructions: String, prompt: String,
    completion: @escaping FlutterResult
  ) {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
          NSLog("%@ Foundation Models unavailable", logTag)
          completion(nil)
          return
        }
        Task {
          do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            let content = response.content
            DispatchQueue.main.async { completion(content) }
          } catch {
            NSLog("%@ respond failed: %@", logTag, "\(error)")
            DispatchQueue.main.async { completion(nil) }
          }
        }
        return
      }
    #endif
    completion(nil)
  }
}

private final class _AiStreamHandler: NSObject, FlutterStreamHandler {
  init(bridge: AppleIntelligenceBridge) { self.bridge = bridge }
  weak var bridge: AppleIntelligenceBridge?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    bridge?.attachStreamSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    bridge?.detachStreamSink()
    return nil
  }
}
