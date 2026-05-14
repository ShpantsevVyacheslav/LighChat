import ActivityKit
import Foundation

/// Live Activity для голосового сообщения, играющего из чата.
///
/// `attributes` — **неизменяемая** часть (имя отправителя, общая длина).
/// `contentState` — **динамическая** часть (позиция, isPlaying), которую
/// мы обновляем через `Activity.update(content:)`.
///
/// Этот файл должен входить в **оба** target-а: Runner (для запуска
/// из приложения) и VoiceActivity (для рендеринга Widget-ом). В Xcode
/// поставь Target Membership на обоих.
@available(iOS 16.1, *)
public struct VoiceActivityAttributes: ActivityAttributes {
  public typealias ContentState = VoiceActivityContentState

  public var senderName: String
  public var totalSeconds: Double

  public init(senderName: String, totalSeconds: Double) {
    self.senderName = senderName
    self.totalSeconds = totalSeconds
  }
}

@available(iOS 16.1, *)
public struct VoiceActivityContentState: Codable, Hashable {
  public var positionSeconds: Double
  public var isPlaying: Bool

  public init(positionSeconds: Double, isPlaying: Bool) {
    self.positionSeconds = positionSeconds
    self.isPlaying = isPlaying
  }
}
