import CoreHaptics
import Flutter
import Foundation
import UIKit

/// Bridge для богатых haptic-паттернов через Core Haptics (iOS 13+).
///
/// Channel: `lighchat/haptics`. Методы:
///  - `play(event)` — воспроизвести семантический паттерн (см. `HapticEvent`)
///  - `isAvailable()` — поддерживает ли устройство Core Haptics
///
/// Если Core Haptics недоступен (iPhone 7 и старше, симулятор) —
/// fallback на простой `UIImpactFeedbackGenerator` (старый API). Так
/// что вызов из Flutter всегда даёт что-то, ничего не падает.
final class HapticsBridge: NSObject {
  static let shared = HapticsBridge()
  private static let logTag = "[Haptics]"

  private var engine: CHHapticEngine?
  private var supportsHaptics: Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/haptics", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(supportsHaptics)

    case "play":
      let args = call.arguments as? [String: Any] ?? [:]
      let event = args["event"] as? String ?? ""
      playSemantic(event: event)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Семантические события — карта на конкретные паттерны.
  private func playSemantic(event: String) {
    switch event {
    case "sendMessage":
      playSimple(.light)
      playPattern(.sendMessage)
    case "receiveMessage":
      playSimple(.soft)
      playPattern(.receiveMessage)
    case "longPress":
      playSimple(.medium)
    case "success":
      playSimple(.success)
      playPattern(.success)
    case "warning":
      playSimple(.warning)
    case "error":
      playSimple(.error)
    case "tick":
      playSimple(.rigid)
    case "selectionChanged":
      playSelection()
    case "reactionBurst":
      playPattern(.reactionBurst)
    default:
      playSimple(.light)
    }
  }

  // MARK: - Fallback (старый API)

  private enum SimpleStyle {
    case light, medium, soft, rigid
    case success, warning, error
  }

  private func playSimple(_ style: SimpleStyle) {
    switch style {
    case .light:
      let g = UIImpactFeedbackGenerator(style: .light)
      g.prepare(); g.impactOccurred()
    case .medium:
      let g = UIImpactFeedbackGenerator(style: .medium)
      g.prepare(); g.impactOccurred()
    case .soft:
      if #available(iOS 13.0, *) {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.prepare(); g.impactOccurred()
      }
    case .rigid:
      if #available(iOS 13.0, *) {
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.prepare(); g.impactOccurred()
      }
    case .success:
      let g = UINotificationFeedbackGenerator()
      g.prepare(); g.notificationOccurred(.success)
    case .warning:
      let g = UINotificationFeedbackGenerator()
      g.prepare(); g.notificationOccurred(.warning)
    case .error:
      let g = UINotificationFeedbackGenerator()
      g.prepare(); g.notificationOccurred(.error)
    }
  }

  private func playSelection() {
    let g = UISelectionFeedbackGenerator()
    g.prepare(); g.selectionChanged()
  }

  // MARK: - Rich Core Haptics patterns

  private enum HapticPattern {
    case sendMessage, receiveMessage, success, reactionBurst
  }

  private func ensureEngine() {
    if engine != nil { return }
    guard supportsHaptics else { return }
    do {
      let e = try CHHapticEngine()
      e.isAutoShutdownEnabled = true
      try e.start()
      e.resetHandler = { [weak self] in
        try? self?.engine?.start()
      }
      engine = e
    } catch {
      NSLog("%@ engine init failed: %@", Self.logTag, "\(error)")
    }
  }

  private func playPattern(_ p: HapticPattern) {
    guard supportsHaptics else { return }
    ensureEngine()
    guard let engine = engine else { return }
    let events: [CHHapticEvent]
    switch p {
    case .sendMessage:
      // Один короткий transient «pop» с быстрым нарастанием.
      events = [
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85),
          ],
          relativeTime: 0)
      ]
    case .receiveMessage:
      // Мягкий двойной tap с маленьким зазором.
      events = [
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
          ],
          relativeTime: 0),
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
          ],
          relativeTime: 0.08),
      ]
    case .success:
      // Три нарастающих tap-а — как «галочка».
      events = [
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
          ],
          relativeTime: 0),
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7),
          ],
          relativeTime: 0.06),
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
          ],
          relativeTime: 0.14),
      ]
    case .reactionBurst:
      // «Праздничный салют» — несколько быстрых случайных tap-ов.
      events = stride(from: 0.0, to: 0.4, by: 0.05).map { t in
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(
              parameterID: .hapticIntensity,
              value: Float.random(in: 0.4...0.9)),
            CHHapticEventParameter(
              parameterID: .hapticSharpness,
              value: Float.random(in: 0.3...0.95)),
          ],
          relativeTime: t)
      }
    }
    do {
      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      NSLog("%@ play pattern failed: %@", Self.logTag, "\(error)")
    }
  }
}
