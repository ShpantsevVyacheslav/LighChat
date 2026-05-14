import ActivityKit
import Flutter
import Foundation

/// Bridge для Live Activity голосового плеера (iOS 16.1+).
///
/// Channel: `lighchat/live_activity`. Методы:
///  - `isSupported()` → `Bool`
///  - `start(senderName, totalSeconds, position, isPlaying)` → `String?`
///    (activity id) — возвращает `null` если не поддерживается / отказали.
///  - `update(activityId, position, isPlaying)` → `Void`
///  - `end(activityId)` → `Void`
///
/// Чтобы реально показывать UI, нужен Widget Extension target —
/// см. `mobile/app/ios/VoiceActivity/README.md`. Без него `start()`
/// вернёт `null`, и Dart-сторона тихо продолжит работать в обычном режиме.
final class VoiceActivityBridge: NSObject {
  static let shared = VoiceActivityBridge()
  private static let logTag = "[VoiceActivity]"

  /// Сохранённые активные `Activity<…>`-инстансы по ID, чтобы потом их
  /// обновлять / завершать.
  private var activities: [String: Any] = [:]

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/live_activity", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(Self.isSupported())

    case "start":
      let args = call.arguments as? [String: Any] ?? [:]
      let senderName = (args["senderName"] as? String ?? "").trimmingCharacters(
        in: .whitespacesAndNewlines)
      let total = (args["totalSeconds"] as? Double) ?? 0
      let position = (args["positionSeconds"] as? Double) ?? 0
      let isPlaying = (args["isPlaying"] as? Bool) ?? true
      if !Self.isSupported() {
        result(nil)
        return
      }
      let id = start(
        senderName: senderName.isEmpty ? "Voice message" : senderName,
        total: total,
        position: position,
        isPlaying: isPlaying)
      result(id)

    case "update":
      let args = call.arguments as? [String: Any] ?? [:]
      let id = args["activityId"] as? String ?? ""
      let position = (args["positionSeconds"] as? Double) ?? 0
      let isPlaying = (args["isPlaying"] as? Bool) ?? true
      Task { await update(id: id, position: position, isPlaying: isPlaying) }
      result(nil)

    case "end":
      let args = call.arguments as? [String: Any] ?? [:]
      let id = args["activityId"] as? String ?? ""
      Task { await end(id: id) }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Поддерживается ли Live Activity на этой iOS-версии и устройстве,
  /// и включил ли пользователь Activities для приложения.
  static func isSupported() -> Bool {
    #if canImport(ActivityKit)
      if #available(iOS 16.2, *) {
        return ActivityAuthorizationInfo().areActivitiesEnabled
      }
    #endif
    return false
  }

  // MARK: - private (ActivityKit calls — все под @available)

  private func start(
    senderName: String, total: Double, position: Double, isPlaying: Bool
  ) -> String? {
    if #available(iOS 16.2, *) {
      let attrs = VoiceActivityAttributes(
        senderName: senderName, totalSeconds: total)
      let state = VoiceActivityContentState(
        positionSeconds: position, isPlaying: isPlaying)
      do {
        let activity = try Activity<VoiceActivityAttributes>.request(
          attributes: attrs,
          content: .init(state: state, staleDate: nil),
          pushType: nil)
        activities[activity.id] = activity
        return activity.id
      } catch {
        NSLog("%@ start failed: %@", Self.logTag, "\(error)")
        return nil
      }
    }
    return nil
  }

  private func update(id: String, position: Double, isPlaying: Bool) async {
    if #available(iOS 16.2, *) {
      guard let activity = activities[id] as? Activity<VoiceActivityAttributes>
      else { return }
      let state = VoiceActivityContentState(
        positionSeconds: position, isPlaying: isPlaying)
      await activity.update(.init(state: state, staleDate: nil))
    }
  }

  private func end(id: String) async {
    if #available(iOS 16.2, *) {
      guard let activity = activities[id] as? Activity<VoiceActivityAttributes>
      else { return }
      await activity.end(nil, dismissalPolicy: .immediate)
      activities.removeValue(forKey: id)
    }
  }
}
