import Flutter
import Foundation

#if canImport(FoundationModels)
  import FoundationModels
#endif

/// Bridge к Apple Intelligence Foundation Models (iOS 18.1+/26+).
///
/// Channel: `lighchat/apple_intelligence`. Если фреймворк отсутствует
/// (старый SDK), устройство не поддерживается (старый чип / нет Apple
/// Intelligence) или пользователь не включил AI — возвращаем `null`, чтобы
/// Dart мог упасть на эвристику.
///
/// Сейчас доступен один метод:
///  - `summarizeText(text, locale)` → `String?` — короткое 1–2 предложение
///    резюме, на том же языке, что и текст.
final class AppleIntelligenceBridge: NSObject {
  static let shared = AppleIntelligenceBridge()
  private static let logTag = "[AppleIntelligence]"

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/apple_intelligence", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(Self.isFoundationModelsAvailable())

    case "summarizeText":
      let args = call.arguments as? [String: Any] ?? [:]
      let text = (args["text"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if text.isEmpty {
        result(nil)
        return
      }
      Self.summarize(text: text, completion: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Доступны ли Foundation Models на этом устройстве прямо сейчас
  /// (фреймворк существует И модель загружена И юзер не отключил AI).
  static func isFoundationModelsAvailable() -> Bool {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
          return true
        }
        return false
      }
    #endif
    return false
  }

  private static func summarize(
    text: String, completion: @escaping FlutterResult
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
            let session = LanguageModelSession(
              instructions:
                "You are a concise summarizer. Always reply in the same language as the input. Output one or two short sentences."
            )
            let prompt = "Summarize this voice message transcript briefly:\n\n\(text)"
            let response = try await session.respond(to: prompt)
            DispatchQueue.main.async { completion(response.content) }
          } catch {
            NSLog("%@ summarize failed: %@", logTag, "\(error)")
            DispatchQueue.main.async { completion(nil) }
          }
        }
        return
      }
    #endif
    completion(nil)
  }
}
