import CoreSpotlight
import Flutter
import Foundation
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

/// Bridge для индексации чатов / pinned-сообщений в системный Spotlight
/// iOS. Channel: `lighchat/spotlight`. Методы:
///  - `isAvailable()` → Bool — `CSSearchableIndex.isIndexingAvailable()`
///  - `index(items)` → void — поштучно или пакетом добавить `CSSearchableItem`
///  - `remove(ids)` → void — удалить по uniqueIdentifier
///  - `removeAll()` → void — очистить весь индекс (на logout)
///  - `consumeLaunchActivity()` → Map? — на cold start возвращает
///    payload (conversationId / messageId) если приложение открыли тапом
///    по Spotlight-результату; иначе nil
///
/// Активация по тапу на результат Spotlight ловится через
/// `application:continueUserActivity:` в AppDelegate, который кладёт
/// dict в очередь, и Dart забирает через `consumeLaunchActivity()`.
final class SpotlightBridge: NSObject {
  static let shared = SpotlightBridge()
  private static let logTag = "[Spotlight]"
  static let userActivityType = "com.lighchat.spotlight.item"

  /// Очередь активаций — отдаём по одной через consumeLaunchActivity().
  /// На cold start userInfo приходит до того, как Flutter engine готов.
  private var pendingActivities: [[String: Any]] = []
  private var liveStreamChannel: FlutterEventChannel?
  private var liveSink: FlutterEventSink?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/spotlight", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    // Live stream — для активаций пока app уже жив (handoff в foreground).
    let stream = FlutterEventChannel(
      name: "lighchat/spotlight_events", binaryMessenger: messenger)
    stream.setStreamHandler(_SpotlightStreamHandler(bridge: self))
    liveStreamChannel = stream
  }

  /// Вызывается AppDelegate в `application:continueUserActivity:`.
  /// Возвращает true если активация наша (Spotlight item).
  @discardableResult
  func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
    let payload: [String: Any]
    if userActivity.activityType == CSSearchableItemActionType {
      guard
        let uid = userActivity.userInfo?[
          CSSearchableItemActivityIdentifier] as? String
      else { return false }
      payload = parsePayload(uid: uid)
    } else if userActivity.activityType == Self.userActivityType {
      guard let uid = userActivity.userInfo?["uid"] as? String else {
        return false
      }
      payload = parsePayload(uid: uid)
    } else {
      return false
    }
    if let sink = liveSink {
      sink(payload)
    } else {
      pendingActivities.append(payload)
    }
    return true
  }

  /// uid формата `chat:<conversationId>` или `pin:<conversationId>:<messageId>`.
  private func parsePayload(uid: String) -> [String: Any] {
    var dict: [String: Any] = ["uid": uid]
    let parts = uid.split(separator: ":")
    guard let kind = parts.first else { return dict }
    dict["kind"] = String(kind)
    if parts.count >= 2 {
      dict["conversationId"] = String(parts[1])
    }
    if parts.count >= 3 {
      dict["messageId"] = String(parts[2])
    }
    return dict
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(CSSearchableIndex.isIndexingAvailable())

    case "index":
      let args = call.arguments as? [String: Any] ?? [:]
      let items = (args["items"] as? [[String: Any]]) ?? []
      indexItems(items, completion: result)

    case "remove":
      let args = call.arguments as? [String: Any] ?? [:]
      let ids = (args["ids"] as? [String]) ?? []
      removeItems(ids: ids, completion: result)

    case "removeAll":
      removeAll(completion: result)

    case "consumeLaunchActivity":
      if pendingActivities.isEmpty {
        result(nil)
      } else {
        let next = pendingActivities.removeFirst()
        result(next)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func indexItems(_ items: [[String: Any]], completion: @escaping FlutterResult) {
    guard CSSearchableIndex.isIndexingAvailable() else {
      completion(nil)
      return
    }
    let searchableItems: [CSSearchableItem] = items.compactMap { dict in
      guard
        let uid = dict["uid"] as? String,
        let title = dict["title"] as? String,
        !uid.isEmpty, !title.isEmpty
      else { return nil }
      let attrs: CSSearchableItemAttributeSet
      if #available(iOS 14.0, *) {
        attrs = CSSearchableItemAttributeSet(contentType: UTType.text)
      } else {
        attrs = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
      }
      attrs.title = title
      attrs.contentDescription = dict["subtitle"] as? String
      if let kw = dict["keywords"] as? [String], !kw.isEmpty {
        attrs.keywords = kw
      }
      if let imagePath = dict["imagePath"] as? String, !imagePath.isEmpty {
        let url = URL(fileURLWithPath: imagePath)
        if FileManager.default.fileExists(atPath: imagePath) {
          attrs.thumbnailURL = url
        }
      }
      let item = CSSearchableItem(
        uniqueIdentifier: uid,
        domainIdentifier: (uid.split(separator: ":").first).map(String.init)
          ?? "lighchat",
        attributeSet: attrs
      )
      return item
    }
    if searchableItems.isEmpty {
      completion(nil)
      return
    }
    CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
      if let error = error {
        NSLog("%@ index error: %@", Self.logTag, "\(error)")
      }
      DispatchQueue.main.async { completion(nil) }
    }
  }

  private func removeItems(ids: [String], completion: @escaping FlutterResult) {
    guard !ids.isEmpty else {
      completion(nil)
      return
    }
    CSSearchableIndex.default()
      .deleteSearchableItems(withIdentifiers: ids) { error in
        if let error = error {
          NSLog("%@ remove error: %@", Self.logTag, "\(error)")
        }
        DispatchQueue.main.async { completion(nil) }
      }
  }

  private func removeAll(completion: @escaping FlutterResult) {
    CSSearchableIndex.default().deleteAllSearchableItems { error in
      if let error = error {
        NSLog("%@ removeAll error: %@", Self.logTag, "\(error)")
      }
      DispatchQueue.main.async { completion(nil) }
    }
  }

  func attachLiveSink(_ sink: @escaping FlutterEventSink) {
    liveSink = sink
    // Если на cold start уже накопились — отдаём по одному.
    while !pendingActivities.isEmpty {
      sink(pendingActivities.removeFirst())
    }
  }

  func detachLiveSink() {
    liveSink = nil
  }
}

private final class _SpotlightStreamHandler: NSObject, FlutterStreamHandler {
  init(bridge: SpotlightBridge) { self.bridge = bridge }
  weak var bridge: SpotlightBridge?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    bridge?.attachLiveSink(events)
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    bridge?.detachLiveSink()
    return nil
  }
}
